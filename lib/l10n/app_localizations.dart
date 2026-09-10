import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es')
  ];

  /// App name / logo text
  ///
  /// In en, this message translates to:
  /// **'bajatelo'**
  String get logo;

  /// Hero section badge text
  ///
  /// In en, this message translates to:
  /// **'Universal Downloader • Fast & Free'**
  String get badge;

  /// First line of hero title
  ///
  /// In en, this message translates to:
  /// **'Universal Video &'**
  String get heroTitle1;

  /// Second line of hero title (rendered with gradient)
  ///
  /// In en, this message translates to:
  /// **'Audio Downloader'**
  String get heroTitle2;

  /// Hero subtitle paragraph
  ///
  /// In en, this message translates to:
  /// **'Download videos and audio from YouTube, TikTok, Instagram, Twitter/X, Facebook, Twitch and 1,000+ platforms in highest quality MP4 or MP3.'**
  String get heroSubtitle;

  /// Label above platform chips
  ///
  /// In en, this message translates to:
  /// **'Supported platforms include:'**
  String get supportedPlatformsLabel;

  /// URL text field placeholder
  ///
  /// In en, this message translates to:
  /// **'Paste link from YouTube, TikTok, Instagram, X/Twitter, Twitch...'**
  String get inputPlaceholder;

  /// Search button label (idle state)
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchBtn;

  /// Search button label (loading state)
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get searchingBtn;

  /// Tooltip for paste icon button
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteTooltip;

  /// Tooltip for clear icon button
  ///
  /// In en, this message translates to:
  /// **'Clear input'**
  String get clearTooltip;

  /// Download video button label
  ///
  /// In en, this message translates to:
  /// **'Download Video (MP4)'**
  String get downloadVideo;

  /// Download audio button label
  ///
  /// In en, this message translates to:
  /// **'Download Audio (MP3)'**
  String get downloadAudio;

  /// Video button label while downloading
  ///
  /// In en, this message translates to:
  /// **'Processing Video...'**
  String get processingVideo;

  /// Audio button label while downloading
  ///
  /// In en, this message translates to:
  /// **'Processing Audio...'**
  String get processingAudio;

  /// Processing notice shown below download buttons
  ///
  /// In en, this message translates to:
  /// **'Converting and merging media on the server. Your download will start automatically in a few moments.'**
  String get processingNotice;

  /// Label for video duration field
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Meta tag for video format
  ///
  /// In en, this message translates to:
  /// **'MP4 / Best Quality'**
  String get videoFormatTag;

  /// Meta tag for audio format
  ///
  /// In en, this message translates to:
  /// **'MP3 / 320kbps Audio'**
  String get audioFormatTag;

  /// Title of feature card 1
  ///
  /// In en, this message translates to:
  /// **'1,000+ Supported Sites'**
  String get feature1Title;

  /// Description of feature card 1
  ///
  /// In en, this message translates to:
  /// **'Supports YouTube, TikTok, Instagram Reels/Posts, Twitter/X, Twitch, Facebook, SoundCloud, Reddit, and more.'**
  String get feature1Desc;

  /// Title of feature card 2
  ///
  /// In en, this message translates to:
  /// **'Ultra Fast Processing'**
  String get feature2Title;

  /// Description of feature card 2
  ///
  /// In en, this message translates to:
  /// **'Powered by yt-dlp & FFmpeg pipeline for lossless format conversions and fast stream merging.'**
  String get feature2Desc;

  /// Title of feature card 3
  ///
  /// In en, this message translates to:
  /// **'100% Free & Private'**
  String get feature3Title;

  /// Description of feature card 3
  ///
  /// In en, this message translates to:
  /// **'No registration, no accounts required, no telemetry. Direct downloads straight to your device.'**
  String get feature3Desc;

  /// Footer text
  ///
  /// In en, this message translates to:
  /// **'bajatelo • Fast, Private & Free Universal Media Downloader'**
  String get footer;

  /// Error shown when clipboard read fails
  ///
  /// In en, this message translates to:
  /// **'Unable to read clipboard. Please paste manually.'**
  String get clipboardError;

  /// Generic error message for failed metadata fetch
  ///
  /// In en, this message translates to:
  /// **'Error fetching video information. Please verify the URL and try again.'**
  String get defaultError;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelDownload;

  /// Success message shown after download
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// Success description message
  ///
  /// In en, this message translates to:
  /// **'File saved to Downloads folder.'**
  String get downloadCompleteDesc;

  /// Accessibility label for EN toggle button
  ///
  /// In en, this message translates to:
  /// **'Switch to English'**
  String get switchToEnglish;

  /// Accessibility label for ES toggle button
  ///
  /// In en, this message translates to:
  /// **'Switch to Spanish'**
  String get switchToSpanish;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
