import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/track_detail_resolver.dart';
import '../widgets/top_list_section.dart';
import 'track_detail_screen.dart';

class MonthlyTopSongFullScreen extends StatelessWidget {
  final Map<dynamic, dynamic> data;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;

  const MonthlyTopSongFullScreen({
    super.key,
    required this.data,
    this.trackDetails,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.monthlyTopSong, style: const TextStyle(fontWeight: FontWeight.w700)),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedKeys.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 72,
          endIndent: 20,
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
        ),
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final monthStr = key.toString().substring(5);
          final displayMonth = formatMonthStr(monthStr);
          final trackName = data[key].toString();
          return ListTile(
            onTap: () {
              final details = resolveTrackDetail(trackName, trackDetails, allTrackCompact);
              if (details != null) {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: details)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noTrackDetails)));
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
    );
  }
}
