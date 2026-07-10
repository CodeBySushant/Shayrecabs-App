import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';

/// Animated success screen after payment verification — with ticket share
/// (the app twin of the web's ticketShare.js).
class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key, this.extra});
  final Map<String, dynamic>? extra;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final rideCode = extra?['rideCode'] as String? ?? '';
    final fare = extra?['fare'] as num?;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 64),
              )
                  .animate()
                  .scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(.4, .4))
                  .then()
                  .shimmer(duration: 900.ms),
              const SizedBox(height: 28),
              Text('Seat booked!', style: t.textTheme.headlineMedium)
                  .animate(delay: 200.ms)
                  .fadeIn()
                  .moveY(begin: 10),
              const SizedBox(height: 8),
              Text(
                'Your payment is verified and your seat on '
                '${rideCode.isEmpty ? 'the ride' : rideCode} is confirmed.'
                '${fare != null ? ' Paid ${formatInr(fare)}.' : ''}',
                textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded,
                          color: AppColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ride details, cancellation, and your ticket live in '
                          'My Bookings. We\'ll match you with your co-rider closer '
                          'to departure.',
                          style: t.textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 400.ms).fadeIn().moveY(begin: 8),
              const Spacer(),
              PrimaryButton(
                label: 'View my bookings',
                icon: Icons.confirmation_number_rounded,
                onPressed: () => context.go('/my-bookings'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Share.share(
                  'I just booked a shared airport cab on shayreCabs 🚕 '
                  '${rideCode.isEmpty ? '' : '(ride $rideCode) '}'
                  '— fixed-time IGI ⇄ Noida/Gurugram rides, fare split per seat. '
                  'Check it out: https://shayrecabs.com',
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                label: const Text('Share ticket'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
