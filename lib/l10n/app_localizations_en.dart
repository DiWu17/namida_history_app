// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Namida History Analyzer';

  @override
  String get homeTitle => 'Home';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get optionalPath => 'Optional Path';

  @override
  String get metadataExtraction =>
      'Match local music files for metadata extraction';

  @override
  String get chooseDirectory => 'Choose Directory';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get chinese => '简体中文';

  @override
  String get chooseBackupZip => 'Choose a Namida Backup ZIP file to begin';

  @override
  String get allTime => 'All Time';

  @override
  String get chooseMusicFolder => 'Select Music Folder';

  @override
  String get clearPath => 'Clear path';

  @override
  String get done => 'Done';

  @override
  String get extractingMessage =>
      'Extracting and analyzing...\\nThis may take a moment.';

  @override
  String get analysisComplete => 'Analysis complete!';

  @override
  String get errorTitle => 'Error';

  @override
  String get ok => 'OK';

  @override
  String get welcomeMessage => 'Welcome to Namida Analyzer';

  @override
  String get selectBackupZip => 'Select Backup ZIP';

  @override
  String get namidaHistory => 'Namida History';

  @override
  String get resetAndSelectNewFile => 'Reset and select new file';

  @override
  String get viewFullList => 'View Full List';

  @override
  String get monthlyTopSong => 'Monthly Top Song';

  @override
  String get noTrackDetails => 'No details available for this track';

  @override
  String get playsSuffix => 'plays';

  @override
  String get historyTitle => 'History Moments';

  @override
  String get firstPlayLabel => 'Added / First Played';

  @override
  String get lastPlayLabel => 'Last Played';

  @override
  String get unknownLabel => 'Unknown';

  @override
  String get playTrend => 'Play Trend';

  @override
  String get sectionCoreNumbers => '1. Core Numbers (Year Overview)';

  @override
  String get sectionTopLists => '2. Annual Rankings';

  @override
  String get sectionTimeDimension => '3. Time & Listening Habits';

  @override
  String get sectionHighlights => '4. Highlights & Notable Moments';

  @override
  String get sectionPlayHistoryTrend => 'Play History Trend';

  @override
  String get statTotalListening => 'Total Listening';

  @override
  String get statListeningCompanion => 'Listening Companion';

  @override
  String get statAvgDaily => 'Avg Daily';

  @override
  String get statTotalPlays => 'Total Plays';

  @override
  String get statUniqueTracks => 'Unique Tracks';

  @override
  String get statUniqueArtists => 'Unique Artists';

  @override
  String get statUniqueAlbums => 'Unique Albums';

  @override
  String get statFavoriteGenre => 'Favorite Genre';

  @override
  String get hoursUnit => 'hours';

  @override
  String get daysUnit => 'days';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get tracksUnit => 'tracks';

  @override
  String get artistsUnit => 'artists';

  @override
  String get albumsUnit => 'albums';

  @override
  String get annualTopTracks => 'Annual Favorite Tracks Top 10';

  @override
  String get annualTopArtists => 'Annual Favorite Artists Top 10';

  @override
  String get annualTopAlbums => 'Annual Favorite Albums Top 10';

  @override
  String get highlightRepeatTitle => 'Obsessive Moment: Most Repeats';

  @override
  String highlightRepeatBody(Object count, Object date, Object track) {
    return '【$date】This day was special, you looped \"$track\" $count times.';
  }

  @override
  String get latestNightTitle => 'Latest Night';

  @override
  String latestNightBody(Object time, Object track) {
    return 'The latest listening time was $time, the track was \"$track\".';
  }

  @override
  String get mostImmersiveTitle => 'Most Immersive Day';

  @override
  String mostImmersiveBody(Object count, Object date) {
    return '【$date】 was the day you were most immersed, with $count plays.';
  }

  @override
  String get periodNight => 'Night';

  @override
  String get periodMorning => 'Morning';

  @override
  String get periodAfternoon => 'Afternoon';

  @override
  String get periodEvening => 'Evening';

  @override
  String get weekMon => 'Mon';

  @override
  String get weekTue => 'Tue';

  @override
  String get weekWed => 'Wed';

  @override
  String get weekThu => 'Thu';

  @override
  String get weekFri => 'Fri';

  @override
  String get weekSat => 'Sat';

  @override
  String get weekSun => 'Sun';

  @override
  String get periodDistributionTitle => 'Period Distribution';

  @override
  String get weeklyPatternTitle => 'Weekly Pattern';

  @override
  String get artistTopSongsTitle => 'Artist Top Songs Top 10';

  @override
  String get albumTopSongsTitle => 'Album Top Songs Top 10';

  @override
  String get noItemDetails => 'No details available for this item';

  @override
  String get fullListSuffix => 'Full List';

  @override
  String get noDataAvailable => 'No data available.';

  @override
  String get pythonPathHint =>
      'Specify the Python interpreter path (e.g. conda env)';

  @override
  String get choosePythonExe => 'Select python.exe';

  @override
  String get namidaPathLabel => 'Namida Player Path';

  @override
  String get namidaPathHint => 'Set to play songs directly in Namida';

  @override
  String get chooseNamidaExe => 'Select namida.exe';

  @override
  String get playInNamida => 'Play in Namida';

  @override
  String get openWithDefault => 'Open with default player';

  @override
  String get fileNotFound => 'Local music file not found';

  @override
  String get needMusicDir =>
      'Please configure music folder path in settings first';

  @override
  String get launchFailed => 'Launch failed';
}
