import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/track_detail_resolver.dart';
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
        title: Text('$title ${AppLocalizations.of(context)!.fullListSuffix}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
          Color rankColor;
          if (rank == 1) rankColor = Colors.amber;
          else if (rank == 2) rankColor = Colors.grey.shade400;
          else if (rank == 3) rankColor = Colors.brown.shade300;
          else rankColor = Theme.of(context).colorScheme.onSurfaceVariant;

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
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                _buildCoverThumbnail(context, entry.key.toString(), icon, 40),
              ],
            ),
            title: Text(
              entry.key.toString(), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
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

  Widget _buildCoverThumbnail(BuildContext context, String name, IconData fallbackIcon, double size) {
    final details = detailsMap?[name];
    final String coverPath = details?['cover']?.toString() ?? '';
    final bool hasCover = coverPath.isNotEmpty && File(coverPath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: hasCover
          ? Image.file(
              File(coverPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fallbackIcon, size: size * 0.5, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(fallbackIcon, size: size * 0.5, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
    );
  }
}
