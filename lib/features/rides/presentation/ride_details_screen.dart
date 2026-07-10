import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../data/rides_repository.dart';
import '../domain/ride_model.dart';

class RideDetailsScreen extends ConsumerWidget {
  const RideDetailsScreen({super.key, required this.idOrCode});
  final String idOrCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(rideDetailsProvider(idOrCode));

    return Scaffold(
      appBar: AppBar(title: Text(idOrCode)),
      body: ride.when(
        loading: () => const ShimmerList(count: 3, height: 160),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(rideDetailsProvider(idOrCode)),
        ),
        data: (r) => _RideDetails(ride: r),
      ),
      bottomNavigationBar: ride.maybeWhen(
        data: (r) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: PrimaryButton(
              label: r.isOpen
                  ? 'Book seat · ${formatInr(r.fare?.current ?? r.baseFare)}'
                  : 'Booking closed',
              onPressed:
                  r.isOpen ? () => context.push('/book/${r.rideCode}') : null,
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _RideDetails extends StatelessWidget {
  const _RideDetails({required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header card ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(ride.routeLabel,
                          style: t.textTheme.headlineSmall),
                    ),
                    StatusChip(ride.status),
                  ],
                ),
                const SizedBox(height: 6),
                if (ride.women)
                  const Row(children: [
                    Icon(Icons.female_rounded,
                        color: AppColors.womenPink, size: 18),
                    SizedBox(width: 4),
                    Text('Women-only ride',
                        style: TextStyle(
                            color: AppColors.womenPink,
                            fontWeight: FontWeight.w600)),
                  ]),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Metric(
                        icon: Icons.schedule_rounded,
                        label: 'Departs',
                        value: ride.departure ?? '—'),
                    _Metric(
                        icon: Icons.flag_rounded,
                        label: 'Arrives',
                        value: ride.arrival ?? '—'),
                    _Metric(
                        icon: Icons.timelapse_rounded,
                        label: 'ETA',
                        value: ride.eta ?? '—'),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fare per person',
                              style: t.textTheme.labelMedium?.copyWith(
                                  color: t.colorScheme.onSurfaceVariant)),
                          Text(formatInr(ride.fare?.current ?? ride.baseFare),
                              style: t.textTheme.headlineSmall
                                  ?.copyWith(color: AppColors.brand)),
                        ],
                      ),
                    ),
                    if ((ride.fare?.savings ?? 0) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Drops to ${formatInr(ride.fare!.projected)}\nwhen 1 more joins',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn().moveY(begin: 10),

        const SizedBox(height: 14),

        // ── Driver ──
        if (ride.driver != null)
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.brand.withOpacity(.12),
                child: Icon(
                    ride.driver!.female
                        ? Icons.face_3_rounded
                        : Icons.face_6_rounded,
                    color: AppColors.brand,
                    size: 30),
              ),
              title: Text(ride.driver!.name, style: t.textTheme.titleMedium),
              subtitle: Text(
                  '${ride.driver!.vehicle ?? ride.vehicleType} · ${ride.driver!.plate ?? ''}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 18),
                    Text(' ${ride.driver!.rating}',
                        style: t.textTheme.titleSmall),
                  ]),
                  Text('${ride.driver!.trips} trips',
                      style: t.textTheme.labelSmall),
                ],
              ),
            ),
          ).animate(delay: 80.ms).fadeIn().moveY(begin: 10),

        const SizedBox(height: 14),

        // ── Drop points / pickups ──
        if (ride.covers.isNotEmpty) ...[
          Text(ride.isAirport ? 'Drop points covered' : 'Drop points',
              style: t.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ride.covers)
                Chip(
                    avatar: const Icon(Icons.place_rounded, size: 16),
                    label: Text(c)),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (ride.pickups.isNotEmpty) ...[
          Text('Pickup points', style: t.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ride.pickups)
                Chip(
                    avatar: const Icon(Icons.hail_rounded, size: 16),
                    label: Text(p)),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // ── Co-riders ──
        if (ride.riders.isNotEmpty) ...[
          Text('Co-riders on this ride', style: t.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final r in ride.riders)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.sky.withOpacity(.12),
                  child: Text(
                      (r.firstName ?? '?').characters.first.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.sky, fontWeight: FontWeight.w700)),
                ),
                title: Row(children: [
                  Text(r.firstName ?? 'Rider'),
                  if (r.verified)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.verified_rounded,
                          color: AppColors.sky, size: 17),
                    ),
                ]),
                subtitle: Text([
                  if (r.gender != null) r.gender,
                  if (r.ageRange != null) r.ageRange,
                  if (r.langs.isNotEmpty) r.langs.join(', '),
                ].whereType<String>().join(' · ')),
                trailing: r.rating == null
                    ? null
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 16),
                        Text(' ${r.rating}'),
                      ]),
              ),
            ),
        ],
        const SizedBox(height: 90),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: t.colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(value, style: t.textTheme.titleSmall),
          Text(label,
              style: t.textTheme.labelSmall
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
