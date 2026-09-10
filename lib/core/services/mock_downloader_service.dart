import 'dart:math';

import 'package:bajatelo_app/core/interfaces/i_downloader_service.dart';
import 'package:bajatelo_app/core/models/download_result.dart';
import 'package:bajatelo_app/core/models/video_info.dart';

/// A fake [IDownloaderService] implementation used during UI development
/// and unit testing.
///
/// Behaviour:
/// - [getVideoInfo] waits 2–3 seconds then returns a hardcoded [VideoInfo].
/// - [downloadMedia] simulates progress from 0 → 1 over ~3 seconds.
/// - [cancelDownload] sets an internal flag that aborts the simulated download.
class MockDownloaderService implements IDownloaderService {
  bool _cancelled = false;
  final _random = Random();

  @override
  Future<VideoInfo> getVideoInfo(String url) async {
    // Simulate a 2–3 second network delay
    final delayMs = 2000 + _random.nextInt(1000);
    await Future.delayed(Duration(milliseconds: delayMs));

    // Validate that the URL looks plausible
    if (url.trim().isEmpty) {
      throw Exception('URL cannot be empty.');
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw Exception('Invalid URL: must start with http:// or https://');
    }

    return const VideoInfo(
      id: 'dQw4w9WgXcQ',
      title: 'Test Video — Mock Result (Never Gonna Give You Up)',
      thumbnailUrl: null, // Real thumbnail requires network; kept null for mock
      durationSeconds: 183,
    );
  }

  @override
  Future<DownloadResult> downloadMedia(
    String url,
    DownloadFormat format, {
    void Function(double progress)? onProgress,
  }) async {
    _cancelled = false;

    // Simulate 20 progress ticks over ~3 seconds
    const totalTicks = 20;
    const tickDurationMs = 150;

    for (int i = 1; i <= totalTicks; i++) {
      if (_cancelled) {
        throw Exception('Download cancelled by user.');
      }
      await Future.delayed(const Duration(milliseconds: tickDurationMs));
      onProgress?.call(i / totalTicks);
    }

    if (_cancelled) {
      throw Exception('Download cancelled by user.');
    }

    final ext = format == DownloadFormat.video ? 'mp4' : 'mp3';
    const fileName = 'test_video_mock';

    return DownloadResult(
      filePath: '/Users/user/Downloads/$fileName.$ext',
      fileName: '$fileName.$ext',
      // Simulate a ~25 MB file for video, ~8 MB for audio
      fileSizeBytes:
          format == DownloadFormat.video ? 25 * 1024 * 1024 : 8 * 1024 * 1024,
      downloadedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancelDownload() async {
    _cancelled = true;
  }

  @override
  Future<void> updateEngine() async {
    // No-op for the mock — no real engine to update.
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
