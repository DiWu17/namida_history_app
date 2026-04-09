import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/track_detail_resolver.dart';
import '../screens/track_detail_screen.dart';
import 'rank_utils.dart';

class TopSongsList extends StatelessWidget {
  final String sectionTitle;
  final Map<dynamic, dynamic> topSongs;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;

  const TopSongsList({
    super.key,
    required this.sectionTitle,
    required this.topSongs,
    this.trackDetails,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = topSongs.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                  final trackName = entry.key.toString();
                  final td = resolveTrackDetail(trackName, trackDetails, allTrackCompact);
                  if (td != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: td)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noTrackDetails)));
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  entry.key.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                trailing: Text(
                  '${entry.value} ${AppLocalizations.of(context)!.playsSuffix}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
