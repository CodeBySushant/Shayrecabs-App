import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../rides/data/rides_repository.dart';
import '../../rides/presentation/ride_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final auth = ref.watch(authProvider);
    final rides = ref.watch(ridesListProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ridesListProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Row(
                children: [
                  Image.asset('assets/images/shayrelogo.png', height: 30),
                  const SizedBox(width: 10),
                  const Text('shayreCabs'),
                ],
              ),
              actions: [
                if (!auth.isLoggedIn)
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Log in'),
                  ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Hero ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brand, AppColors.sky],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.isLoggedIn
                            ? 'Hi ${auth.user!.name.split(' ').first} 👋'
                            : 'Shared airport rides,\nsplit fares.',
                        style: t.textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fixed-time cabs between IGI Airport, Noida & Gurugram. '
                        'Pay per seat — save up to 60% vs a solo cab.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.9), height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickRoute(
                              label: 'IGI → Noida',
                              onTap: () => _goRides(context, ref, 'noida'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickRoute(
                              label: 'IGI → Gurugram',
                              onTap: () => _goRides(context, ref, 'gurugram'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _QuickRoute(
                        label: 'Noida ⇄ Gurugram intercity',
                        onTap: () => _goRides(context, ref, 'noida-gurugram'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).moveY(begin: 14),
              ),
            ),

            // ── Women-only banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    ref.read(rideFiltersProvider.notifier).state =
                        const RideFilters(womenOnly: true);
                    context.go('/live-rides');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.womenPink.withOpacity(.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.womenPink.withOpacity(.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.female_rounded,
                            color: AppColors.womenPink, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Women-only rides',
                                  style: t.textTheme.titleMedium),
                              Text(
                                'Verified female co-riders & women drivers where available',
                                style: t.textTheme.bodySmall?.copyWith(
                                    color: t.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ).animate(delay: 120.ms).fadeIn().moveY(begin: 10),
              ),
            ),

            // ── Upcoming rides ──
            SliverToBoxAdapter(
              child: SectionHeader(
                'Upcoming rides',
                trailing: TextButton(
                  onPressed: () => context.go('/live-rides'),
                  child: const Text('See all'),
                ),
              ),
            ),
            rides.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    ShimmerCard(),
                    SizedBox(height: 12),
                    ShimmerCard(),
                  ]),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(ridesListProvider),
                ),
              ),
              data: (list) {
                final featured = list.take(3).toList();
                if (featured.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.directions_car_outlined,
                      title: 'No rides scheduled right now',
                      subtitle: 'New rides are added daily — check back soon.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: featured.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => RideCard(ride: featured[i])
                        .animate(delay: (60 * i).ms)
                        .fadeIn()
                        .moveY(begin: 12),
                  ),
                );
              },
            ),

            // ── How it works ──
            const SliverToBoxAdapter(child: SectionHeader('How it works')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: const [
                    _Step(
                        n: 1,
                        icon: Icons.search_rounded,
                        title: 'Pick a scheduled ride',
                        text:
                            'Fixed departure times on the IGI ⇄ Noida / Gurugram corridors.'),
                    _Step(
                        n: 2,
                        icon: Icons.event_seat_rounded,
                        title: 'Book your seat',
                        text:
                            'Choose 2-share or 3-share. Fare is per person — never per cab.'),
                    _Step(
                        n: 3,
                        icon: Icons.payments_rounded,
                        title: 'Pay securely',
                        text:
                            'Razorpay checkout. Cancel up to 24h before for a near-full refund.'),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _goRides(BuildContext context, WidgetRef ref, String route) {
    ref.read(rideFiltersProvider.notifier).state = RideFilters(route: route);
    context.go('/live-rides');
  }
}

class _QuickRoute extends StatelessWidget {
  const _QuickRoute({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5)),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      );
}

class _Step extends StatelessWidget {
  const _Step(
      {required this.n,
      required this.icon,
      required this.title,
      required this.text});
  final int n;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.brand),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$n. $title', style: t.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(text,
                      style: t.textTheme.bodySmall?.copyWith(
                          color: t.colorScheme.onSurfaceVariant, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
