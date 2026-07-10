import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/data/fares.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../rides/data/rides_repository.dart';
import '../../rides/domain/ride_model.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';

/// Booking flow — mirrors the web Book page:
///  • airport rides: terminal + flight no. + airline + drop hotspot
///  • intercity rides: pickup hotspot + drop hotspot
///  • sharing type (2 / 3) — airport rides are 2-share only
///  • women-only toggle (gated server-side to verified female profiles)
///  • fare preview from the same table the server charges from
///  • Razorpay checkout → server signature verification → confirmed
class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key, required this.rideCode});
  final String rideCode;

  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  final _form = GlobalKey<FormState>();
  final _flightNumber = TextEditingController();
  final _airline = TextEditingController();

  String _terminal = 'T3';
  String? _pickupHotspot;
  String? _dropHotspot;
  int _shareType = 2;
  bool _womenOnly = false;
  bool _busy = false;

  Razorpay? _razorpay;
  Booking? _pendingBooking;

  static const _terminals = ['T1', 'T2', 'T3'];

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
    _flightNumber.dispose();
    _airline.dispose();
    super.dispose();
  }

  // ── Fare preview: same lookup the backend performs ──
  num? _farePreview(Ride ride) {
    final origin = ride.isAirport ? 'IGI' : _pickupHotspot;
    if (origin != null && _dropHotspot != null) {
      final f = lookupFare(origin, _dropHotspot!, _shareType);
      if (f != null) return f;
    }
    // Fallback mirrors backend fareForOccupancy(baseFare, shareType)
    return ride.baseFare > 0 ? (ride.baseFare / _shareType).round() : null;
  }

  Future<void> _submit(Ride ride) async {
    if (!_form.currentState!.validate()) return;
    if (_dropHotspot == null && ride.covers.isNotEmpty) {
      showAppSnack(context, 'Please choose a drop point', error: true);
      return;
    }
    if (!ride.isAirport && _pickupHotspot == null && ride.pickups.isNotEmpty) {
      showAppSnack(context, 'Please choose a pickup point', error: true);
      return;
    }

    setState(() => _busy = true);
    final repo = ref.read(bookingRepositoryProvider);
    try {
      // 1. Create the pending booking — fare is computed server-side.
      final booking = await repo.create(
        rideId: ride.rideCode,
        terminal: ride.isAirport ? _terminal : null,
        flightNumber: ride.isAirport ? _flightNumber.text.trim() : null,
        airline: ride.isAirport ? _airline.text.trim() : null,
        pickupHotspot: ride.isAirport ? null : _pickupHotspot,
        passengers: _shareType,
        dropHotspot: _dropHotspot,
        womenOnly: _womenOnly || ride.women,
      );
      _pendingBooking = booking;

      // 2. Create the Razorpay order (server-trusted amount).
      final order = await repo.createOrder(booking.id);

      // 3. Open native Razorpay checkout.
      final user = ref.read(authProvider).user;
      _razorpay!.open({
        'key': order.keyId,
        'amount': order.amount,
        'currency': order.currency,
        'order_id': order.orderId,
        'name': 'ShayreCabs',
        'description': 'Shared ride ${ride.rideCode}',
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
            bookingId: _pendingBooking?.id,
          );
      ref.invalidate(myBookingsProvider);
      ref.invalidate(ridesListProvider);
      if (mounted) {
        context.pushReplacement('/booking-confirmed', extra: {
          'bookingId': _pendingBooking?.id,
          'rideCode': widget.rideCode,
          'fare': _pendingBooking?.fareCharged,
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(
            context,
            'Payment received but verification failed — check My Bookings '
            'or contact support. (${e.toString()})',
            error: true);
        context.go('/my-bookings');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    setState(() => _busy = false);
    showAppSnack(
        context,
        r.message?.isNotEmpty == true
            ? r.message!
            : 'Payment was not completed. Your seat is held for 1 hour — '
                'you can retry from My Bookings.',
        error: true);
  }

  @override
  Widget build(BuildContext context) {
    final rideAsync = ref.watch(rideDetailsProvider(widget.rideCode));

    return Scaffold(
      appBar: AppBar(title: Text('Book · ${widget.rideCode}')),
      body: rideAsync.when(
        loading: () => const ShimmerList(count: 3, height: 150),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(rideDetailsProvider(widget.rideCode)),
        ),
        data: (ride) => _buildForm(ride),
      ),
    );
  }

  Widget _buildForm(Ride ride) {
    final t = Theme.of(context);
    final fare = _farePreview(ride);
    final airportOnly2Share = ride.isAirport;
    if (airportOnly2Share && _shareType != 2) _shareType = 2;

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ride summary
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_car_rounded,
                  color: AppColors.brand),
              title: Text(ride.routeLabel),
              subtitle: Text(
                  'Departs ${ride.departure ?? '—'} · ${ride.eta ?? ''}'),
              trailing: ride.women
                  ? const Icon(Icons.female_rounded,
                      color: AppColors.womenPink)
                  : null,
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 18),

          // ── Airport fields ──
          if (ride.isAirport) ...[
            Text('Arrival details', style: t.textTheme.titleMedium),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: [
                for (final term in _terminals)
                  ButtonSegment(value: term, label: Text(term)),
              ],
              selected: {_terminal},
              onSelectionChanged: (s) => setState(() => _terminal = s.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _flightNumber,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Flight number (optional)',
                  hintText: 'AI 863',
                  prefixIcon: Icon(Icons.flight_land_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _airline,
              decoration: const InputDecoration(
                  labelText: 'Airline (optional)',
                  prefixIcon: Icon(Icons.airlines_rounded)),
            ),
            const SizedBox(height: 18),
          ],

          // ── Intercity pickup ──
          if (!ride.isAirport && ride.pickups.isNotEmpty) ...[
            Text('Pickup point', style: t.textTheme.titleMedium),
            const SizedBox(height: 10),
            _HotspotPicker(
              options: ride.pickups,
              value: _pickupHotspot,
              onChanged: (v) => setState(() => _pickupHotspot = v),
            ),
            const SizedBox(height: 18),
          ],

          // ── Drop point ──
          if (ride.covers.isNotEmpty) ...[
            Text('Drop point', style: t.textTheme.titleMedium),
            const SizedBox(height: 10),
            _HotspotPicker(
              options: ride.covers,
              value: _dropHotspot,
              onChanged: (v) => setState(() => _dropHotspot = v),
            ),
            const SizedBox(height: 18),
          ],

          // ── Sharing type ──
          Text('Sharing type', style: t.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            airportOnly2Share
                ? 'Airport rides are 2-share only — one co-rider, maximum comfort.'
                : 'Pick how many riders share the cab. Fare shown is per person.',
            style: t.textTheme.bodySmall
                ?.copyWith(color: t.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: [
              const ButtonSegment(
                  value: 2,
                  label: Text('2-share'),
                  icon: Icon(Icons.people_alt_rounded)),
              if (!airportOnly2Share)
                const ButtonSegment(
                    value: 3,
                    label: Text('3-share'),
                    icon: Icon(Icons.groups_rounded)),
            ],
            selected: {_shareType},
            onSelectionChanged: (s) => setState(() => _shareType = s.first),
          ),

          const SizedBox(height: 18),

          // ── Women-only ──
          if (!ride.women)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary:
                  const Icon(Icons.female_rounded, color: AppColors.womenPink),
              title: const Text('Women-only preference'),
              subtitle: const Text(
                  'Requires a KYC-verified female profile',
                  style: TextStyle(fontSize: 12.5)),
              value: _womenOnly,
              onChanged: (v) => setState(() => _womenOnly = v),
            ),

          const SizedBox(height: 10),

          // ── Fare summary ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _fareRow(t, 'Fare per person ($_shareType-share)',
                      formatInr(fare)),
                  const SizedBox(height: 6),
                  _fareRow(t, 'Seats reserved', '1'),
                  const Divider(height: 22),
                  _fareRow(t, 'You pay now', formatInr(fare), bold: true),
                  const SizedBox(height: 6),
                  Text(
                    'Exact fare is confirmed by the server at booking. '
                    'Free seat hold for 1 hour if payment fails.',
                    style: t.textTheme.labelSmall
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),
          PrimaryButton(
            label: fare == null
                ? 'Select points to see fare'
                : 'Pay ${formatInr(fare)} · Book seat',
            loading: _busy,
            onPressed: fare == null ? null : () => _submit(ride),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _fareRow(ThemeData t, String label, String value,
          {bool bold = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold ? t.textTheme.titleMedium : t.textTheme.bodyMedium),
          Text(value,
              style: bold
                  ? t.textTheme.titleMedium?.copyWith(color: AppColors.brand)
                  : t.textTheme.bodyMedium),
        ],
      );
}

class _HotspotPicker extends StatelessWidget {
  const _HotspotPicker(
      {required this.options, required this.value, required this.onChanged});
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            ChoiceChip(
              label: Text(o),
              selected: value == o,
              onSelected: (_) => onChanged(o),
            ),
        ],
      );
}
