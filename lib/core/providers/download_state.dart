import 'package:bajatelo_app/core/models/download_result.dart';
import 'package:bajatelo_app/core/models/video_info.dart';

/// Represents every stage of the download lifecycle.
enum DownloadStatus {
  /// No operation in progress. Initial state.
  idle,

  /// [IDownloaderService.getVideoInfo] is running.
  fetchingInfo,

  /// [IDownloaderService.downloadMedia] is running.
  downloading,

  /// Download completed successfully.
  completed,

  /// An error occurred. See [DownloadState.errorMessage].
  error,
}

/// Immutable snapshot of the download state exposed to the UI.
class DownloadState {
  final DownloadStatus status;

  /// Video metadata returned after a successful [getVideoInfo] call.
  final VideoInfo? videoInfo;

  /// Download progress in the range [0.0, 1.0].
  final double progress;

  /// Human-readable error description when [status] == [DownloadStatus.error].
  final String? errorMessage;

  /// Populated when [status] == [DownloadStatus.completed].
  final DownloadResult? result;

  /// Which format is currently downloading: 'video' | 'audio' | null
  final String? activeFormat;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.videoInfo,
    this.progress = 0.0,
    this.errorMessage,
    this.result,
    this.activeFormat,
  });

  bool get isIdle => status == DownloadStatus.idle;
  bool get isFetchingInfo => status == DownloadStatus.fetchingInfo;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get hasError => status == DownloadStatus.error;

  DownloadState copyWith({
    DownloadStatus? status,
    VideoInfo? videoInfo,
    double? progress,
    String? errorMessage,
    DownloadResult? result,
    String? activeFormat,
    // Explicit null sentinel so callers can clear nullable fields.
    bool clearVideoInfo = false,
    bool clearError = false,
    bool clearResult = false,
    bool clearActiveFormat = false,
  }) {
    return DownloadState(
      status: status ?? this.status,
      videoInfo: clearVideoInfo ? null : (videoInfo ?? this.videoInfo),
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: clearResult ? null : (result ?? this.result),
      activeFormat:
          clearActiveFormat ? null : (activeFormat ?? this.activeFormat),
    );
  }
}
