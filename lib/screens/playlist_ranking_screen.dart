import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/rank_utils.dart';
import 'playlist_detail_screen.dart';

class PlaylistRankingScreen extends StatelessWidget {
  final List<dynamic> playlistStats;

  const PlaylistRankingScreen({
    super.key,
    required this.playlistStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (playlistStats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.playlistRankingTitle)),
        body: Center(child: Text(l10n.noDataAvailable)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.playlistRankingTitle} ${l10n.fullListSuffix}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView.separated(
        itemCount: playlistStats.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 64,
          endIndent: 20,
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
        ),
        itemBuilder: (context, index) {
          final pl = playlistStats[index] as Map<dynamic, dynamic>;
          final name = pl['name']?.toString() ?? '';
          final totalPlays = pl['total_plays'] as int? ?? 0;
          final trackCount = pl['track_count'] as int? ?? 0;
          final rank = index + 1;
          final rankColor = getRankColor(rank, context);

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PlaylistDetailScreen(playlistData: pl),
                ),
              );
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        fontWeight:
                            rank <= 3 ? FontWeight.w900 : FontWeight.w600,
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
                        .withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              '$trackCount ${l10n.tracksUnit}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(150),
              ),
            ),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withAlpha(180),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalPlays ${l10n.playsSuffix}',
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
