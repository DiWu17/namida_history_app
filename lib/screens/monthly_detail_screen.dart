import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/track_detail_resolver.dart';
import '../widgets/cover_thumbnail.dart';
import '../widgets/rank_utils.dart';
import 'track_detail_screen.dart';

class MonthlyDetailScreen extends StatelessWidget {
  final String monthKey;
  final String topSong;
  final Map<String, int> rankings;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;

  const MonthlyDetailScreen({
    super.key,
    required this.monthKey,
    required this.topSong,
    required this.rankings,
    this.trackDetails,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedEntries = rankings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalPlays = sortedEntries.fold<int>(0, (sum, e) => sum + e.value);

    return Scaffold(
      appBar: AppBar(
        title: Text('$monthKey ${l10n.monthlyRanking}', style: const TextStyle(fontWeight: FontWeight.w700)),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.monthlyTopSong, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(topSong, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${sortedEntries.length} ${l10n.monthlyUniqueTracks}', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('$totalPlays ${l10n.playsSuffix}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          // Rankings list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedEntries.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 64,
                endIndent: 20,
                color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
              ),
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final rank = index + 1;
                final rankColor = getRankColor(rank, context);

                return ListTile(
                  onTap: () {
                    final details = resolveTrackDetail(entry.key, trackDetails, allTrackCompact);
                    if (details != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: entry.key, details: details)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noTrackDetails)));
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                              fontWeight: rank <= 3 ? FontWeight.w900 : FontWeight.w600,
                              color: rankColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CoverThumbnail(name: entry.key, detailsMap: trackDetails, allTrackCompact: allTrackCompact, fallbackIcon: Icons.music_note, size: 40),
                    ],
                  ),
                  title: Text(
                    entry.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(180),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value} ${l10n.playsSuffix}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
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
