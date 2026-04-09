import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/detail_screen_template.dart';
import '../widgets/top_songs_list.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  final Map<dynamic, dynamic> details;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    required this.details,
    this.trackDetails,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    return DetailScreenTemplate(
      title: artistName,
      details: details,
      fallbackIcon: Icons.mic_rounded,
      accentColor: Colors.purple,
      extraSections: [
        if (details['top_songs'] != null && (details['top_songs'] as Map).isNotEmpty)
          TopSongsList(
            sectionTitle: AppLocalizations.of(context)!.artistTopSongsTitle,
            topSongs: details['top_songs'] as Map,
            trackDetails: trackDetails,
            allTrackCompact: allTrackCompact,
          ),
      ],
    );
  }
}
