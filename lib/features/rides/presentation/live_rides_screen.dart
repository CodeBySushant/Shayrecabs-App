import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../data/rides_repository.dart';
import 'ride_card.dart';

/// Live rides board — direction / women-only / open filters, like the web.
class LiveRidesScreen extends ConsumerWidget {
  const LiveRidesScreen({super.key});

  static const _routes = [
    ('all', 'All routes'),
    ('noida', 'IGI → Noida'),
    ('gurugram', 'IGI → Gurugram'),
    ('noida-gurugram', 'Noida → Gurugram'),
    ('gurugram-noida', 'Gurugram → Noida'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(rideFiltersProvider);
    final rides = ref.watch(ridesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live rides')),
      body: Column(
        children: [
          // ── Filter chips ──
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (value, label) in _routes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: filters.route == value,
                      onSelected: (_) => ref
                          .read(rideFiltersProvider.notifier)
                          .state = filters.copyWith(route: value),
                    ),
                  ),
                FilterChip(
                  avatar: const Icon(Icons.female_rounded,
                      size: 18, color: AppColors.womenPink),
                  label: const Text('Women only'),
                  selected: filters.womenOnly,
                  onSelected: (v) => ref
                      .read(rideFiltersProvider.notifier)
                      .state = filters.copyWith(womenOnly: v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Open for booking'),
                  selected: filters.openOnly,
                  onSelected: (v) => ref
                      .read(rideFiltersProvider.notifier)
                      .state = filters.copyWith(openOnly: v),
                ),
              ],
            ),
          ),
          Expanded(
            child: rides.when(
              loading: () => const ShimmerList(count: 5, height: 170),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(ridesListProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.no_transfer_rounded,
                    title: 'No rides match these filters',
                    subtitle:
                        'Try a different route, or clear the filters to see everything.',
                    actionLabel: 'Clear filters',
                    onAction: () => ref
                        .read(rideFiltersProvider.notifier)
                        .state = const RideFilters(openOnly: false),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(ridesListProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => RideCard(ride: list[i])
                        .animate(delay: (40 * i).clamp(0, 240).ms)
                        .fadeIn(duration: 250.ms)
                        .moveY(begin: 10),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
