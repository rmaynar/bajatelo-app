import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bajatelo_app/core/providers/download_notifier.dart';
import 'package:bajatelo_app/core/providers/download_state.dart';
import 'package:bajatelo_app/core/interfaces/i_downloader_service.dart';
import 'package:bajatelo_app/core/services/mock_downloader_service.dart';

void main() {
  group('DownloadNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [],
      );
    });

    tearDown(() => container.dispose());

    test('initial state is idle', () {
      final notifier = DownloadNotifier(MockDownloaderService());
      expect(notifier.state.status, DownloadStatus.idle);
      expect(notifier.state.videoInfo, isNull);
      expect(notifier.state.progress, 0.0);
    });

    test('fetchInfo transitions to fetchingInfo then idle', () async {
      final notifier = DownloadNotifier(MockDownloaderService());
      final statuses = <DownloadStatus>[];

      // Listen before calling
      notifier.addListener((s) => statuses.add(s.status));

      // Start the fetch — doesn't block
      final future =
          notifier.fetchInfo('https://www.youtube.com/watch?v=test');
      expect(notifier.state.status, DownloadStatus.fetchingInfo);

      await future;

      expect(notifier.state.status, DownloadStatus.idle);
      expect(notifier.state.videoInfo, isNotNull);
      expect(notifier.state.videoInfo!.id, 'dQw4w9WgXcQ');
    });

    test('fetchInfo with empty URL sets error state', () async {
      final notifier = DownloadNotifier(MockDownloaderService());
      await notifier.fetchInfo('');

      expect(notifier.state.status, DownloadStatus.error);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('fetchInfo with non-http URL sets error state', () async {
      final notifier = DownloadNotifier(MockDownloaderService());
      await notifier.fetchInfo('not-a-url');

      expect(notifier.state.status, DownloadStatus.error);
    });

    test('download transitions through downloading to completed', () async {
      final notifier = DownloadNotifier(MockDownloaderService());

      // First fetch to get videoInfo
      await notifier.fetchInfo('https://youtube.com/watch?v=abc');
      expect(notifier.state.videoInfo, isNotNull);

      // Now download
      final progressValues = <double>[];
      // Spy on progress via state changes
      notifier.addListener((s) {
        if (s.isDownloading) progressValues.add(s.progress);
      });

      await notifier.download(
          'https://youtube.com/watch?v=abc',
          DownloadFormat.video);

      expect(notifier.state.status, DownloadStatus.completed);
      expect(notifier.state.result, isNotNull);
      expect(notifier.state.result!.fileName, contains('mp4'));
      // Progress should have reached 1.0
      expect(notifier.state.progress, 1.0);
    });

    test('reset returns to idle', () async {
      final notifier = DownloadNotifier(MockDownloaderService());
      await notifier.fetchInfo('https://youtube.com/watch?v=abc');
      notifier.reset();

      expect(notifier.state.status, DownloadStatus.idle);
      expect(notifier.state.videoInfo, isNull);
    });

    test('cancel during download transitions back to idle', () async {
      final notifier = DownloadNotifier(MockDownloaderService());
      await notifier.fetchInfo('https://youtube.com/watch?v=abc');

      // Start download but cancel quickly
      final downloadFuture = notifier.download(
          'https://youtube.com/watch?v=abc', DownloadFormat.audio);

      // Cancel after a tick
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.cancel();

      await downloadFuture; // should complete (with error internally)

      expect(notifier.state.status, DownloadStatus.idle);
    });
  });

  group('MockDownloaderService', () {
    test('getVideoInfo returns expected mock data', () async {
      final service = MockDownloaderService();
      final info = await service.getVideoInfo('https://youtube.com/watch?v=test');

      expect(info.id, 'dQw4w9WgXcQ');
      expect(info.title, isNotEmpty);
      expect(info.durationSeconds, 183);
    });

    test('downloadMedia returns result with correct extension for video', () async {
      final service = MockDownloaderService();
      final result = await service.downloadMedia(
          'https://youtube.com/watch?v=test', DownloadFormat.video);

      expect(result.fileName, endsWith('.mp4'));
      expect(result.fileSizeBytes, greaterThan(0));
    });

    test('downloadMedia returns result with correct extension for audio', () async {
      final service = MockDownloaderService();
      final result = await service.downloadMedia(
          'https://youtube.com/watch?v=test', DownloadFormat.audio);

      expect(result.fileName, endsWith('.mp3'));
    });

    test('cancelDownload sets cancelled flag', () async {
      final service = MockDownloaderService();
      await service.cancelDownload();
      // Verify that a subsequent download throws
      expect(
        () => service.downloadMedia(
            'https://youtube.com/watch?v=test', DownloadFormat.video),
        throwsException,
      );
    });
  });
}
