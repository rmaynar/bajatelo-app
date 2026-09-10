// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get logo => 'bajatelo';

  @override
  String get badge => 'Universal Downloader • Fast & Free';

  @override
  String get heroTitle1 => 'Universal Video &';

  @override
  String get heroTitle2 => 'Audio Downloader';

  @override
  String get heroSubtitle =>
      'Download videos and audio from YouTube, TikTok, Instagram, Twitter/X, Facebook, Twitch and 1,000+ platforms in highest quality MP4 or MP3.';

  @override
  String get supportedPlatformsLabel => 'Supported platforms include:';

  @override
  String get inputPlaceholder =>
      'Paste link from YouTube, TikTok, Instagram, X/Twitter, Twitch...';

  @override
  String get searchBtn => 'Search';

  @override
  String get searchingBtn => 'Fetching...';

  @override
  String get pasteTooltip => 'Paste from clipboard';

  @override
  String get clearTooltip => 'Clear input';

  @override
  String get downloadVideo => 'Download Video (MP4)';

  @override
  String get downloadAudio => 'Download Audio (MP3)';

  @override
  String get processingVideo => 'Processing Video...';

  @override
  String get processingAudio => 'Processing Audio...';

  @override
  String get processingNotice =>
      'Converting and merging media on the server. Your download will start automatically in a few moments.';

  @override
  String get duration => 'Duration';

  @override
  String get videoFormatTag => 'MP4 / Best Quality';

  @override
  String get audioFormatTag => 'MP3 / 320kbps Audio';

  @override
  String get feature1Title => '1,000+ Supported Sites';

  @override
  String get feature1Desc =>
      'Supports YouTube, TikTok, Instagram Reels/Posts, Twitter/X, Twitch, Facebook, SoundCloud, Reddit, and more.';

  @override
  String get feature2Title => 'Ultra Fast Processing';

  @override
  String get feature2Desc =>
      'Powered by yt-dlp & FFmpeg pipeline for lossless format conversions and fast stream merging.';

  @override
  String get feature3Title => '100% Free & Private';

  @override
  String get feature3Desc =>
      'No registration, no accounts required, no telemetry. Direct downloads straight to your device.';

  @override
  String get footer =>
      'bajatelo • Fast, Private & Free Universal Media Downloader';

  @override
  String get clipboardError =>
      'Unable to read clipboard. Please paste manually.';

  @override
  String get defaultError =>
      'Error fetching video information. Please verify the URL and try again.';

  @override
  String get cancelDownload => 'Cancel';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String get downloadCompleteDesc => 'File saved to Downloads folder.';

  @override
  String get switchToEnglish => 'Switch to English';

  @override
  String get switchToSpanish => 'Switch to Spanish';
}
