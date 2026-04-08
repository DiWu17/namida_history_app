import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Namida History Analyzer'**
  String get appTitle;

  /// The title of the home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @optionalPath.
  ///
  /// In en, this message translates to:
  /// **'Optional Path'**
  String get optionalPath;

  /// No description provided for @metadataExtraction.
  ///
  /// In en, this message translates to:
  /// **'Match local music files for metadata extraction'**
  String get metadataExtraction;

  /// No description provided for @chooseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose Directory'**
  String get chooseDirectory;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// No description provided for @chooseBackupZip.
  ///
  /// In en, this message translates to:
  /// **'Choose a Namida Backup ZIP file to begin'**
  String get chooseBackupZip;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @chooseMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Music Folder'**
  String get chooseMusicFolder;

  /// No description provided for @clearPath.
  ///
  /// In en, this message translates to:
  /// **'Clear path'**
  String get clearPath;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @extractingMessage.
  ///
  /// In en, this message translates to:
  /// **'Extracting and analyzing...\\nThis may take a moment.'**
  String get extractingMessage;

  /// No description provided for @analysisComplete.
  ///
  /// In en, this message translates to:
  /// **'Analysis complete!'**
  String get analysisComplete;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Namida Analyzer'**
  String get welcomeMessage;

  /// No description provided for @selectBackupZip.
  ///
  /// In en, this message translates to:
  /// **'Select Backup ZIP'**
  String get selectBackupZip;

  /// No description provided for @namidaHistory.
  ///
  /// In en, this message translates to:
  /// **'Namida History'**
  String get namidaHistory;

  /// No description provided for @resetAndSelectNewFile.
  ///
  /// In en, this message translates to:
  /// **'Reset and select new file'**
  String get resetAndSelectNewFile;

  /// No description provided for @viewFullList.
  ///
  /// In en, this message translates to:
  /// **'View Full List'**
  String get viewFullList;

  /// No description provided for @monthlyTopSong.
  ///
  /// In en, this message translates to:
  /// **'Monthly Top Song'**
  String get monthlyTopSong;

  /// No description provided for @noTrackDetails.
  ///
  /// In en, this message translates to:
  /// **'No details available for this track'**
  String get noTrackDetails;

  /// No description provided for @playsSuffix.
  ///
  /// In en, this message translates to:
  /// **'plays'**
  String get playsSuffix;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History Moments'**
  String get historyTitle;

  /// No description provided for @firstPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Added / First Played'**
  String get firstPlayLabel;

  /// No description provided for @lastPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Played'**
  String get lastPlayLabel;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLabel;

  /// No description provided for @playTrend.
  ///
  /// In en, this message translates to:
  /// **'Play Trend'**
  String get playTrend;

  /// No description provided for @sectionCoreNumbers.
  ///
  /// In en, this message translates to:
  /// **'1. Core Numbers (Year Overview)'**
  String get sectionCoreNumbers;

  /// No description provided for @sectionTopLists.
  ///
  /// In en, this message translates to:
  /// **'2. Annual Rankings'**
  String get sectionTopLists;

  /// No description provided for @sectionTimeDimension.
  ///
  /// In en, this message translates to:
  /// **'3. Time & Listening Habits'**
  String get sectionTimeDimension;

  /// No description provided for @sectionHighlights.
  ///
  /// In en, this message translates to:
  /// **'4. Highlights & Notable Moments'**
  String get sectionHighlights;

  /// No description provided for @sectionPlayHistoryTrend.
  ///
  /// In en, this message translates to:
  /// **'Play History Trend'**
  String get sectionPlayHistoryTrend;

  /// No description provided for @statTotalListening.
  ///
  /// In en, this message translates to:
  /// **'Total Listening'**
  String get statTotalListening;

  /// No description provided for @statListeningCompanion.
  ///
  /// In en, this message translates to:
  /// **'Listening Companion'**
  String get statListeningCompanion;

  /// No description provided for @statAvgDaily.
  ///
  /// In en, this message translates to:
  /// **'Avg Daily'**
  String get statAvgDaily;

  /// No description provided for @statTotalPlays.
  ///
  /// In en, this message translates to:
  /// **'Total Plays'**
  String get statTotalPlays;

  /// No description provided for @statUniqueTracks.
  ///
  /// In en, this message translates to:
  /// **'Unique Tracks'**
  String get statUniqueTracks;

  /// No description provided for @statUniqueArtists.
  ///
  /// In en, this message translates to:
  /// **'Unique Artists'**
  String get statUniqueArtists;

  /// No description provided for @statUniqueAlbums.
  ///
  /// In en, this message translates to:
  /// **'Unique Albums'**
  String get statUniqueAlbums;

  /// No description provided for @statFavoriteGenre.
  ///
  /// In en, this message translates to:
  /// **'Favorite Genre'**
  String get statFavoriteGenre;

  /// No description provided for @hoursUnit.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursUnit;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// No description provided for @tracksUnit.
  ///
  /// In en, this message translates to:
  /// **'tracks'**
  String get tracksUnit;

  /// No description provided for @artistsUnit.
  ///
  /// In en, this message translates to:
  /// **'artists'**
  String get artistsUnit;

  /// No description provided for @albumsUnit.
  ///
  /// In en, this message translates to:
  /// **'albums'**
  String get albumsUnit;

  /// No description provided for @annualTopTracks.
  ///
  /// In en, this message translates to:
  /// **'Annual Favorite Tracks Top 10'**
  String get annualTopTracks;

  /// No description provided for @annualTopArtists.
  ///
  /// In en, this message translates to:
  /// **'Annual Favorite Artists Top 10'**
  String get annualTopArtists;

  /// No description provided for @annualTopAlbums.
  ///
  /// In en, this message translates to:
  /// **'Annual Favorite Albums Top 10'**
  String get annualTopAlbums;

  /// No description provided for @highlightRepeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Obsessive Moment: Most Repeats'**
  String get highlightRepeatTitle;

  /// No description provided for @highlightRepeatBody.
  ///
  /// In en, this message translates to:
  /// **'【{date}】This day was special, you looped \"{track}\" {count} times.'**
  String highlightRepeatBody(Object count, Object date, Object track);

  /// No description provided for @latestNightTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest Night'**
  String get latestNightTitle;

  /// No description provided for @latestNightBody.
  ///
  /// In en, this message translates to:
  /// **'The latest listening time was {time}, the track was \"{track}\".'**
  String latestNightBody(Object time, Object track);

  /// No description provided for @mostImmersiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Most Immersive Day'**
  String get mostImmersiveTitle;

  /// No description provided for @mostImmersiveBody.
  ///
  /// In en, this message translates to:
  /// **'【{date}】 was the day you were most immersed, with {count} plays.'**
  String mostImmersiveBody(Object count, Object date);

  /// No description provided for @periodNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get periodNight;

  /// No description provided for @periodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get periodMorning;

  /// No description provided for @periodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get periodAfternoon;

  /// No description provided for @periodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get periodEvening;

  /// No description provided for @weekMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekMon;

  /// No description provided for @weekTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekTue;

  /// No description provided for @weekWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekWed;

  /// No description provided for @weekThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekThu;

  /// No description provided for @weekFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekFri;

  /// No description provided for @weekSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekSat;

  /// No description provided for @weekSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekSun;

  /// No description provided for @periodDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Period Distribution'**
  String get periodDistributionTitle;

  /// No description provided for @weeklyPatternTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Pattern'**
  String get weeklyPatternTitle;

  /// No description provided for @artistTopSongsTitle.
  ///
  /// In en, this message translates to:
  /// **'Artist Top Songs Top 10'**
  String get artistTopSongsTitle;

  /// No description provided for @albumTopSongsTitle.
  ///
  /// In en, this message translates to:
  /// **'Album Top Songs Top 10'**
  String get albumTopSongsTitle;

  /// No description provided for @noItemDetails.
  ///
  /// In en, this message translates to:
  /// **'No details available for this item'**
  String get noItemDetails;

  /// No description provided for @fullListSuffix.
  ///
  /// In en, this message translates to:
  /// **'Full List'**
  String get fullListSuffix;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noDataAvailable;

  /// No description provided for @pythonPathHint.
  ///
  /// In en, this message translates to:
  /// **'Specify the Python interpreter path (e.g. conda env)'**
  String get pythonPathHint;

  /// No description provided for @choosePythonExe.
  ///
  /// In en, this message translates to:
  /// **'Select python.exe'**
  String get choosePythonExe;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
