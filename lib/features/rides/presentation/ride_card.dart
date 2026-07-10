import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../domain/ride_model.dart';

/// The ride card used on Home + Live Rides — departure, route, fare split,
/// occupancy, women-only badge.
class RideCard extends StatelessWidget {
  const RideCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/ride/${ride.rideCode}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ride.departure ?? '--:--',
                      style: const TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(ride.routeLabel,
                        style: t.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (ride.women)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.female_rounded,
                          color: AppColors.womenPink, size: 22),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 15, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(ride.eta ?? '—', style: t.textTheme.bodySmall),
                  const SizedBox(width: 14),
                  Icon(Icons.directions_car_rounded,
                      size: 15, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(ride.vehicleType, style: t.textTheme.bodySmall),
                  const SizedBox(width: 14),
                  Icon(Icons.group_rounded,
                      size: 15, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${ride.occupancy} joined', style: t.textTheme.bodySmall),
                  const Spacer(),
                  StatusChip(ride.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From',
                            style: t.textTheme.labelSmall?.copyWith(
                                color: t.colorScheme.onSurfaceVariant)),
                        Text(
                          formatInr(ride.fare?.current ?? ride.baseFare),
                          style: t.textTheme.titleLarge
                              ?.copyWith(color: AppColors.brand),
                        ),
                        Text('per person',
                            style: t.textTheme.labelSmall?.copyWith(
                                color: t.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: ride.isOpen
                        ? () => context.push('/book/${ride.rideCode}')
                        : null,
                    child: Text(ride.isOpen ? 'Book seat' : 'Closed'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
