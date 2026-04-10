import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/track_detail_resolver.dart';
import '../widgets/cover_thumbnail.dart';
import '../widgets/rank_utils.dart';
import 'track_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'album_detail_screen.dart';

class FullListScreen extends StatelessWidget {
  final String title;
  final Map<dynamic, dynamic> data;
  final IconData icon;
  final String type;
  final Map<dynamic, dynamic>? detailsMap;
  final Map<dynamic, dynamic>? trackDetailsMap;
  final Map<dynamic, dynamic>? allTrackCompact;

  const FullListScreen({
    super.key,
    required this.title,
    required this.data,
    required this.icon,
    this.type = 'none',
    this.detailsMap,
    this.trackDetailsMap,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(AppLocalizations.of(context)!.noDataAvailable)),
      );
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return Scaffold(
      appBar: AppBar(
        title: Text('$title ${AppLocalizations.of(context)!.fullListSuffix}', style: const TextStyle(fontWeight: FontWeight.w700)),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView.separated(
        itemCount: sortedEntries.length,
        separatorBuilder: (_, __) => Divider(
          height: 1, 
          indent: 64, 
          endIndent: 20, 
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)
        ),
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final rank = index + 1;
          final rankColor = getRankColor(rank, context);

          return ListTile(
            onTap: type != 'none' ? () {
              final name = entry.key.toString();
              final compact = type == 'track' ? allTrackCompact : null;
              final details = resolveTrackDetail(name, detailsMap, compact);
              if (details != null) {
                if (type == 'track') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: name, details: details)));
                } else if (type == 'artist') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => ArtistDetailScreen(artistName: name, details: details, trackDetails: trackDetailsMap, allTrackCompact: allTrackCompact)));
                } else if (type == 'album') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => AlbumDetailScreen(albumName: name, details: details, trackDetails: trackDetailsMap, allTrackCompact: allTrackCompact)));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noItemDetails)));
              }
            } : null,
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
                CoverThumbnail(name: entry.key.toString(), detailsMap: detailsMap, allTrackCompact: type == 'track' ? allTrackCompact : null, fallbackIcon: icon, size: 40),
              ],
            ),
            title: Text(
              entry.key.toString(), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(180),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entry.value} ${AppLocalizations.of(context)!.playsSuffix}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onPrimaryContainer, 
                  fontSize: 13
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
