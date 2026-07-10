import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../data/community_repository.dart';
import '../domain/community_model.dart';

/// Community — WhatsApp groups by destination/area/special + the anonymized
/// live activity feed, same data as the web Community page.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _category = 'all';

  static const _categories = [
    ('all', 'All'),
    ('destination', 'Destinations'),
    ('area', 'Areas'),
    ('special', 'Special'),
  ];

  Future<void> _openWhatsapp(Community c) async {
    final link = c.whatsappLink;
    if (link == null || link.isEmpty) {
      showAppSnack(context, 'This group\'s invite link isn\'t live yet.',
          error: true);
      return;
    }
    final uri = Uri.parse(link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        showAppSnack(context, 'Could not open WhatsApp.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final communities = ref.watch(communitiesProvider);
    final activity = ref.watch(communityActivityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communitiesProvider);
          ref.invalidate(communityActivityProvider);
          await ref.read(communitiesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Live activity ──
            activity.maybeWhen(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle),
                              )
                                  .animate(
                                      onPlay: (c) => c.repeat(reverse: true))
                                  .fade(begin: .4, duration: 800.ms),
                              const SizedBox(width: 8),
                              Text('Live on shayreCabs',
                                  style: t.textTheme.titleMedium),
                            ]),
                            const SizedBox(height: 12),
                            for (final a in items.take(5))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.bolt_rounded,
                                        size: 16, color: AppColors.gold),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(children: [
                                          TextSpan(
                                              text: a.user,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          TextSpan(text: ' ${a.text}'),
                                        ]),
                                        style: t.textTheme.bodySmall,
                                      ),
                                    ),
                                    if (a.time != null)
                                      Text(timeAgo(a.time!),
                                          style: t.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: t.colorScheme
                                                      .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().moveY(begin: 8),
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // ── Category filter ──
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (value, label) in _categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _category == value,
                        onSelected: (_) =>
                            setState(() => _category = value),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Groups ──
            communities.when(
              loading: () => const Column(children: [
                ShimmerCard(height: 100),
                SizedBox(height: 12),
                ShimmerCard(height: 100),
                SizedBox(height: 12),
                ShimmerCard(height: 100),
              ]),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(communitiesProvider),
              ),
              data: (all) {
                final list = _category == 'all'
                    ? all
                    : all.where((c) => c.category == _category).toList();
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No groups in this category yet',
                    subtitle: 'New WhatsApp communities are added regularly.',
                  );
                }
                return Column(
                  children: [
                    for (final (i, c) in list.indexed)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: (c.women
                                    ? AppColors.womenPink
                                    : AppColors.success)
                                .withOpacity(.12),
                            child: Icon(
                              c.women
                                  ? Icons.female_rounded
                                  : Icons.groups_rounded,
                              color: c.women
                                  ? AppColors.womenPink
                                  : AppColors.success,
                            ),
                          ),
                          title: Row(children: [
                            Flexible(
                                child: Text(c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            if (c.featured)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.star_rounded,
                                    color: AppColors.gold, size: 16),
                              ),
                          ]),
                          subtitle: Text(
                            [
                              if (c.city != null) c.city,
                              '${c.members} members',
                              if (c.description != null) c.description,
                            ].whereType<String>().join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.success.withOpacity(.12),
                              foregroundColor: AppColors.success,
                            ),
                            onPressed: () => _openWhatsapp(c),
                            child: const Text('Join'),
                          ),
                        ),
                      )
                          .animate(delay: (40 * i).clamp(0, 200).ms)
                          .fadeIn()
                          .moveY(begin: 8),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
