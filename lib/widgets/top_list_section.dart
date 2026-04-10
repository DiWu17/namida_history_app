import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/config_service.dart';
import '../services/track_detail_resolver.dart';
import 'cover_thumbnail.dart';
import 'rank_utils.dart';
import '../screens/full_list_screen.dart';
import '../screens/track_detail_screen.dart';
import '../screens/artist_detail_screen.dart';
import '../screens/album_detail_screen.dart';
import '../screens/monthly_top_song_screen.dart';

class TopListSection extends StatelessWidget {
  final String title;
  final Map<dynamic, dynamic> data;
  final IconData icon;
  final Color iconColor;
  final String type;
  final Map<dynamic, dynamic>? detailsMap;
  final Map<dynamic, dynamic>? trackDetailsMap;
  final Map<dynamic, dynamic>? allTrackCompact;
  final int maxItems;

  const TopListSection({
    super.key,
    required this.title,
    required this.data,
    required this.icon,
    required this.iconColor,
    this.type = 'none',
    this.detailsMap,
    this.trackDetailsMap,
    this.allTrackCompact,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => FullListScreen(title: title.replaceAll(RegExp(r' Top \d+'), ''), data: data, icon: icon, type: type, detailsMap: detailsMap, trackDetailsMap: trackDetailsMap, allTrackCompact: allTrackCompact)));
              },
              child: Text(AppLocalizations.of(context)!.viewFullList, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TopList(data: data, icon: icon, type: type, detailsMap: detailsMap, trackDetailsMap: trackDetailsMap, allTrackCompact: allTrackCompact, maxItems: maxItems),
        const SizedBox(height: 24),
      ],
    );
  }
}

class TopList extends StatelessWidget {
  final Map<dynamic, dynamic> data;
  final IconData icon;
  final String type;
  final Map<dynamic, dynamic>? detailsMap;
  final Map<dynamic, dynamic>? trackDetailsMap;
  final Map<dynamic, dynamic>? allTrackCompact;
  final int maxItems;

  const TopList({
    super.key,
    required this.data,
    this.icon = Icons.music_note,
    this.type = 'none',
    this.detailsMap,
    this.trackDetailsMap,
    this.allTrackCompact,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('No data available.');
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    final displayEntries = sortedEntries.take(maxItems).toList();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayEntries.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 64,
          endIndent: 20,
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
        ),
        itemBuilder: (context, index) {
          final entry = displayEntries[index];
          final rank = index + 1;
          final rankColor = getRankColor(rank, context);

          return ListTile(
            onTap: type != 'none' ? () {
              final name = entry.key.toString();
              final details = resolveTrackDetail(name, detailsMap, allTrackCompact);

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
                  width: 32,
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

const List<String> _kMonthAbbr = ['', 'Jan.', 'Feb.', 'Mar.', 'Apr.', 'May.', 'Jun.', 'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.', 'Dec.'];

String formatMonthStr(String monthStr) {
  final monthFormat = ConfigService().get('month_format') ?? 'numeric';
  if (monthFormat == 'english') {
    final m = int.tryParse(monthStr);
    if (m != null && m >= 1 && m <= 12) {
      return _kMonthAbbr[m];
    }
  }
  return monthStr;
}

class MonthlyTopSongPreview extends StatelessWidget {
  final Map<dynamic, dynamic> data;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;
  final int maxPreview;

  const MonthlyTopSongPreview({
    super.key,
    required this.data,
    this.trackDetails,
    this.allTrackCompact,
    this.maxPreview = 10,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();
    final bool needsTruncation = sortedKeys.length > maxPreview;
    final displayKeys = needsTruncation ? sortedKeys.sublist(sortedKeys.length - maxPreview) : sortedKeys;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.monthlyTopSong, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (needsTruncation)
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => MonthlyTopSongFullScreen(data: data, trackDetails: trackDetails, allTrackCompact: allTrackCompact)));
                },
                child: Text(AppLocalizations.of(context)!.viewFullList, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayKeys.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              endIndent: 20,
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
            ),
            itemBuilder: (context, index) {
              final key = displayKeys[index];
              final monthStr = key.toString().substring(5);
              final displayMonth = formatMonthStr(monthStr);
              final trackName = data[key].toString();
              return ListTile(
                onTap: () {
                  final details = resolveTrackDetail(trackName, trackDetails, allTrackCompact);
                  if (details != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: details)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noTrackDetails)));
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(180),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayMonth,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: displayMonth.length > 2 ? 12 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  trackName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(key.toString(), style: const TextStyle(fontSize: 13)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
