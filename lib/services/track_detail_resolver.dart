/// Resolves track details, lazily building from compact data when not pre-computed.
///
/// Lookup order:
/// 1. [trackDetails] (pre-computed top 300)
/// 2. [allTrackCompact] (compact data for all remaining tracks)
///    → on hit, result is cached into [trackDetails] for future calls
///
/// Returns null if the track is unknown.
Map<dynamic, dynamic>? resolveTrackDetail(
  String trackName,
  Map<dynamic, dynamic>? trackDetails,
  Map<dynamic, dynamic>? allTrackCompact,
) {
  if (trackDetails?.containsKey(trackName) == true) {
    return trackDetails![trackName] as Map<dynamic, dynamic>;
  }
  final compact = allTrackCompact?[trackName];
  if (compact == null) return null;
  // Cache so subsequent clicks are instant.
  trackDetails?[trackName] = compact;
  return compact as Map<dynamic, dynamic>;
}
