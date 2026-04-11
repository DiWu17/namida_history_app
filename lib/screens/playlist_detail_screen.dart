import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/rank_utils.dart';
import '../widgets/app_styles.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Map<dynamic, dynamic> playlistData;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistData,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = playlistData['name']?.toString() ?? '';
    final totalPlays = playlistData['total_plays'] as int? ?? 0;
    final trackCount = playlistData['track_count'] as int? ?? 0;
    final trackPlayCounts =
        (playlistData['track_play_counts'] as Map?)?.cast<String, int>() ??
            <String, int>{};

    final sortedEntries = trackPlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: namidaCardDecoration(context, borderRadius: 16),
                child: Row(
                  children: [
                    _buildStatItem(
                      context,
                      Icons.play_circle_fill_rounded,
                      Colors.green,
                      '$totalPlays',
                      l10n.playsSuffix,
                    ),
                    const SizedBox(width: 32),
                    _buildStatItem(
                      context,
                      Icons.music_note_rounded,
                      Colors.blue,
                      '$trackCount',
                      l10n.tracksUnit,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                l10n.playlistTrackRanking,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color:
                      Theme.of(context).colorScheme.onSurface.withAlpha(220),
                ),
              ),
            ),
          ),
          if (sortedEntries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l10n.noDataAvailable)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = sortedEntries[index];
                  final rank = index + 1;
                  final rankColor = getRankColor(rank, context);

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontSize: rank <= 3 ? 20 : 16,
                                    fontWeight: rank <= 3
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: rankColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withAlpha(80),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.music_note,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          entry.key,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withAlpha(180),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value} ${l10n.playsSuffix}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      if (index < sortedEntries.length - 1)
                        Divider(
                          height: 1,
                          indent: 64,
                          endIndent: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withAlpha(50),
                        ),
                    ],
                  );
                },
                childCount: sortedEntries.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, Color color,
      String value, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(150),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
