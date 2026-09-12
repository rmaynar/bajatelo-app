import 'package:bajatelo/core/models/video_info.dart';
import 'package:bajatelo/core/models/download_result.dart';

/// Specifies whether to download the video stream or audio-only.
enum DownloadFormat {
  /// Download as MP4 (best video + audio quality).
  video,

  /// Download as MP3 (audio only, 320kbps where possible).
  audio,
}

/// Abstract contract for all downloader engine implementations.
///
/// Concrete implementations:
///  - [MockDownloaderService]   (Phase 1 — UI development & testing)
///  - [DesktopDownloaderService] (Phase 2 — macOS / Windows / Linux via yt-dlp subprocess)
///  - [AndroidDownloaderService] (Phase 3 — Android via youtubedl-android MethodChannel)
abstract class IDownloaderService {
  /// Extracts video metadata from [url] WITHOUT downloading the media.
  ///
  /// Returns a [VideoInfo] on success.
  /// Throws a descriptive [Exception] on failure (invalid URL, unsupported
  /// platform, network error, etc.).
  Future<VideoInfo> getVideoInfo(String url);

  /// Downloads the media at [url] in the given [format].
  ///
  /// [onProgress] is called repeatedly with values from 0.0 to 1.0.
  /// Returns a [DownloadResult] containing the local file path and metadata.
  /// Throws a descriptive [Exception] on failure.
  Future<DownloadResult> downloadMedia(
    String url,
    DownloadFormat format, {
    void Function(double progress)? onProgress,
  });

  /// Cancels the currently in-progress download, if any.
  ///
  /// This is a best-effort operation; implementations may need to kill a
  /// subprocess or abort a network request.
  Future<void> cancelDownload();

  /// Updates the underlying yt-dlp engine to the latest version.
  ///
  /// On Desktop, runs `yt-dlp --update`.
  /// On Android, calls `YoutubeDL.updateYoutubeDL()`.
  /// The default implementation is a no-op so mock/stub implementations do
  /// not need to override it.
  Future<void> updateEngine() async {}
}
