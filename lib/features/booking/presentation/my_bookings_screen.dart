import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';

/// My Bookings — pay-later on pending bookings, cancel with the refund-policy
/// preview (>24h ₹200 flat · 12–24h 50% · <12h none), and post-ride rating.
class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  Razorpay? _razorpay;
  Booking? _paying;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ── Pay-later ──
  Future<void> _payNow(Booking b) async {
    setState(() => _busy = true);
    try {
      final order =
          await ref.read(bookingRepositoryProvider).createOrder(b.id);
      _paying = b;
      final user = ref.read(authProvider).user;
      _razorpay!.open({
        'key': order.keyId,
        'amount': order.amount,
        'currency': order.currency,
        'order_id': order.orderId,
        'name': 'ShayreCabs',
        'description': 'Shared ride ${b.ride?.rideCode ?? ''}',
        'prefill': {
          'name': user?.name ?? '',
          'email': user?.email ?? '',
          'contact': user?.phone ?? '',
        },
        'theme': {'color': '#5B5FFF'},
      });
    } catch (e) {
      if (mounted) {
        showAppSnack(context, e.toString(), error: true);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    try {
      await ref.read(bookingRepositoryProvider).verifyPayment(
            orderId: r.orderId!,
            paymentId: r.paymentId!,
            signature: r.signature!,
            bookingId: _paying?.id,
          );
      ref.invalidate(myBookingsProvider);
      if (mounted) showAppSnack(context, 'Payment confirmed — seat booked!');
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    setState(() => _busy = false);
    showAppSnack(context, r.message ?? 'Payment was not completed.',
        error: true);
  }

  // ── Cancel with refund preview ──
  Future<void> _confirmCancel(Booking b) async {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => _CancelSheet(booking: b),
    );
    if (proceed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final refund = await ref.read(bookingRepositoryProvider).cancel(b.id);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        showAppSnack(
            context,
            refund == null
                ? 'Booking cancelled. Your seat has been released.'
                : 'Cancelled. Refund ${refund.refundCode} of '
                    '${formatInr(refund.amount)} is being processed.');
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Rate ──
  Future<void> _rate(Booking b) async {
    final result = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _RateSheet(),
    );
    if (result == null || !mounted) return;

    try {
      await ref
          .read(bookingRepositoryProvider)
          .rate(b.id, rating: result.$1, feedback: result.$2);
      ref.invalidate(myBookingsProvider);
      if (mounted) showAppSnack(context, 'Thanks for rating your ride!');
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: bookings.when(
        loading: () => const ShimmerList(count: 4, height: 180),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(myBookingsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: 'No bookings yet',
              subtitle:
                  'Book a seat on a scheduled ride and it will show up here.',
              actionLabel: 'Browse rides',
              onAction: () => context.go('/live-rides'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myBookingsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BookingCard(
                booking: list[i],
                busy: _busy,
                onPay: () => _payNow(list[i]),
                onCancel: () => _confirmCancel(list[i]),
                onRate: () => _rate(list[i]),
              ).animate(delay: (40 * i).clamp(0, 240).ms).fadeIn().moveY(begin: 10),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.busy,
    required this.onPay,
    required this.onCancel,
    required this.onRate,
  });

  final Booking booking;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onCancel;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final b = booking;
    final ride = b.ride;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ride?.routeLabel ?? 'Ride',
                      style: t.textTheme.titleMedium),
                ),
                StatusChip(b.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (ride?.rideCode != null) ride!.rideCode,
                if (b.departureAt != null) formatDateTime(b.departureAt),
                if (b.dropHotspot != null) '→ ${b.dropHotspot}',
              ].join(' · '),
              style: t.textTheme.bodySmall
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _mini(t, Icons.people_alt_rounded, '${b.passengers}-share'),
                if (b.terminal != null)
                  _mini(t, Icons.flight_land_rounded, b.terminal!),
                if (b.pickupHotspot != null)
                  _mini(t, Icons.hail_rounded, b.pickupHotspot!),
                if (b.womenOnly)
                  _mini(t, Icons.female_rounded, 'Women-only',
                      color: AppColors.womenPink),
                _mini(t, Icons.payments_rounded, formatInr(b.fareCharged),
                    color: AppColors.brand),
              ],
            ),
            if (b.rating != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                      i <= b.rating!
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.gold,
                      size: 20),
                const SizedBox(width: 6),
                Text('You rated this ride', style: t.textTheme.labelSmall),
              ]),
            ],

            // ── Actions ──
            if (b.isPendingPayment || b.canCancel || b.canRate) ...[
              const Divider(height: 24),
              Row(
                children: [
                  if (b.isPendingPayment)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: busy ? null : onPay,
                        icon: const Icon(Icons.bolt_rounded, size: 20),
                        label: const Text('Pay now'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44)),
                      ),
                    ),
                  if (b.canRate)
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: busy ? null : onRate,
                        icon: const Icon(Icons.star_rounded, size: 20),
                        label: const Text('Rate ride'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44)),
                      ),
                    ),
                  if ((b.isPendingPayment || b.canRate) && b.canCancel)
                    const SizedBox(width: 10),
                  if (b.canCancel)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: AppColors.danger,
                          side: BorderSide(
                              color: AppColors.danger.withOpacity(.5)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                ],
              ),
              if (b.isPendingPayment && b.holdExpiresAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Seat held until ${formatDateTime(b.holdExpiresAt)} — unpaid bookings auto-cancel after that.',
                  style: t.textTheme.labelSmall
                      ?.copyWith(color: AppColors.warning),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _mini(ThemeData t, IconData icon, String label, {Color? color}) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color ?? t.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: t.textTheme.bodySmall?.copyWith(
                color: color, fontWeight: color != null ? FontWeight.w600 : null)),
      ]);
}

/// Cancellation sheet showing the exact refund band that will apply —
/// mirrors the backend policy so there are no surprises.
class _CancelSheet extends StatelessWidget {
  const _CancelSheet({required this.booking});
  final Booking booking;

  (String, String) _policyPreview() {
    final b = booking;
    if (!(b.status == 'confirmed' && b.paid)) {
      return ('No charge', 'This booking is unpaid — cancelling simply releases your seat.');
    }
    final fare = b.fareCharged ?? 0;
    final dep = b.departureAt;
    if (dep == null) return ('—', 'Refund will be computed per policy.');
    final hours = dep.difference(DateTime.now()).inMinutes / 60.0;
    if (hours >= 24) {
      final refund = fare - (fare < 200 ? fare : 200);
      return ('Refund ${inrFmt(refund)}',
          'More than 24h before departure — flat ₹200 deduction.');
    }
    if (hours >= 12) {
      return ('Refund ${inrFmt((fare * 0.5).roundToDouble())}',
          '12–24h before departure — 50% deduction applies.');
    }
    return ('No refund', 'Less than 12h before departure — 100% deduction per policy.');
  }

  static String inrFmt(num v) => formatInr(v);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (headline, detail) = _policyPreview();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cancel this booking?', style: t.textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline,
                      style: t.textTheme.titleMedium
                          ?.copyWith(color: AppColors.warning)),
                  const SizedBox(height: 4),
                  Text(detail, style: t.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, cancel booking'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep my seat'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Star rating + feedback sheet (1–5, optional text).
class _RateSheet extends StatefulWidget {
  const _RateSheet();

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  int _stars = 0;
  final _feedback = TextEditingController();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How was your ride?', style: t.textTheme.titleLarge),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      iconSize: 40,
                      onPressed: () => setState(() => _stars = i),
                      icon: Icon(
                        i <= _stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.gold,
                      ),
                    ).animate(target: i <= _stars ? 1 : 0).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        duration: 120.ms),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _feedback,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    hintText: 'Anything you want to share? (optional)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _stars == 0
                    ? null
                    : () =>
                        Navigator.pop(context, (_stars, _feedback.text.trim())),
                child: const Text('Submit rating'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
