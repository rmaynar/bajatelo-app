import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bajatelo/core/interfaces/i_downloader_service.dart';
import 'package:bajatelo/core/providers/download_state.dart';
import 'package:bajatelo/core/utils/ytdlp_error_parser.dart';

/// Orchestrates the entire download lifecycle.
///
/// Exposed via [downloadNotifierProvider] defined in [downloader_provider.dart].
class DownloadNotifier extends StateNotifier<DownloadState> {
  final IDownloaderService _service;

  DownloadNotifier(this._service) : super(const DownloadState());

  // ── fetchInfo ──────────────────────────────────────────────────────────────

  /// Calls [IDownloaderService.getVideoInfo] and updates state with the result.
  ///
  /// On success  → status: [DownloadStatus.idle], videoInfo populated.
  /// On failure  → status: [DownloadStatus.error], errorMessage populated.
  Future<void> fetchInfo(String url) async {
    state = const DownloadState(status: DownloadStatus.fetchingInfo);
    try {
      final info = await _service.getVideoInfo(url);
      state = DownloadState(
        status: DownloadStatus.idle,
        videoInfo: info,
      );
    } on Exception catch (e) {
      final parsed = YtdlpErrorParser.parse(_rawMessage(e));
      state = DownloadState(
        status: DownloadStatus.error,
        errorMessage: parsed.friendlyMessage,
        needsEngineUpdate: parsed.needsEngineUpdate,
        rawErrorDetails: parsed.rawDetails,
      );
    }
  }

  // ── download ───────────────────────────────────────────────────────────────

  /// Calls [IDownloaderService.downloadMedia] for the given [format].
  ///
  /// Reports live progress via [onProgress] callback.
  /// On success  → status: [DownloadStatus.completed], result populated.
  /// On failure  → status: [DownloadStatus.error], errorMessage populated.
  Future<void> download(
    String url,
    DownloadFormat format,
  ) async {
    final formatKey =
        format == DownloadFormat.video ? 'video' : 'audio';

    state = state.copyWith(
      status: DownloadStatus.downloading,
      progress: 0.0,
      activeFormat: formatKey,
      clearError: true,
      clearResult: true,
    );

    try {
      final result = await _service.downloadMedia(
        url,
        format,
        onProgress: (p) {
          state = state.copyWith(progress: p);
        },
      );

      state = state.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        result: result,
        clearActiveFormat: true,
      );
    } on Exception catch (e) {
      // Don't overwrite the idle state set by cancel()
      if (state.isDownloading) {
        final parsed = YtdlpErrorParser.parse(_rawMessage(e));
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: parsed.friendlyMessage,
          needsEngineUpdate: parsed.needsEngineUpdate,
          rawErrorDetails: parsed.rawDetails,
          clearActiveFormat: true,
        );
      }
    }
  }

  // ── cancel ─────────────────────────────────────────────────────────────────

  /// Cancels the in-progress download.
  Future<void> cancel() async {
    await _service.cancelDownload();
    state = state.copyWith(
      status: DownloadStatus.idle,
      clearActiveFormat: true,
      clearError: true,
    );
  }

  // ── updateEngine ───────────────────────────────────────────────────────────

  /// Updates the yt-dlp engine to the latest version.
  Future<void> updateEngine() async {
    state = state.copyWith(isUpdatingEngine: true);
    try {
      await _service.updateEngine();
      state = state.copyWith(
        isUpdatingEngine: false,
        needsEngineUpdate: false,
        clearError: true,
        clearRawErrorDetails: true,
        status: DownloadStatus.idle,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isUpdatingEngine: false,
        errorMessage: 'Failed to update engine: ${_rawMessage(e)}',
      );
    }
  }

  // ── reset ──────────────────────────────────────────────────────────────────

  /// Resets the entire state back to [DownloadStatus.idle].
  void reset() {
    state = const DownloadState();
  }

  /// Clears just the error so the user can retry.
  void clearError() {
    state = state.copyWith(
      status: DownloadStatus.idle,
      clearError: true,
      clearRawErrorDetails: true,
      needsEngineUpdate: false,
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Extracts the raw message from an exception, stripping Dart's
  /// "Exception: " prefix.
  String _rawMessage(Exception e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring('Exception: '.length);
    }
    return msg;
  }
}
