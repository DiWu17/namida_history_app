import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/detail_screen_template.dart';
import '../widgets/top_songs_list.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final Map<dynamic, dynamic> details;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.details,
    this.trackDetails,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    return DetailScreenTemplate(
      title: albumName,
      details: details,
      fallbackIcon: Icons.album_rounded,
      accentColor: Colors.deepOrange,
      extraSections: [
        if (details['top_songs'] != null && (details['top_songs'] as Map).isNotEmpty)
          TopSongsList(
            sectionTitle: AppLocalizations.of(context)!.albumTopSongsTitle,
            topSongs: details['top_songs'] as Map,
            trackDetails: trackDetails,
            allTrackCompact: allTrackCompact,
          ),
      ],
    );
  }
}
