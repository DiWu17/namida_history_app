import 'package:flutter/material.dart';
import '../services/track_detail_resolver.dart';
import '../screens/track_detail_screen.dart';
import '../l10n/app_localizations.dart';

class HighlightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? trackName;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;

  const HighlightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trackName,
    this.trackDetails,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withAlpha(isDark ? 30 : 35),
            color.withAlpha(isDark ? 8 : 10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(isDark ? 30 : 40), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: trackName != null ? () {
            final details = resolveTrackDetail(trackName!, trackDetails, allTrackCompact);
            if (details != null) {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName!, details: details)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noTrackDetails)));
            }
          } : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 35 : 40),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: color,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          height: 1.5,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(isDark ? 200 : 180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
