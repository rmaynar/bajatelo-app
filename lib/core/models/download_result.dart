import 'dart:convert';

/// Result of a completed download operation.
class DownloadResult {
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final DateTime downloadedAt;

  const DownloadResult({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  factory DownloadResult.fromJson(Map<String, dynamic> json) {
    return DownloadResult(
      filePath: json['filePath'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory DownloadResult.fromJsonString(String jsonString) {
    return DownloadResult.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Human-readable file size (e.g. "12.3 MB").
  String get fileSizeFormatted {
    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (fileSizeBytes >= gb) {
      return '${(fileSizeBytes / gb).toStringAsFixed(1)} GB';
    } else if (fileSizeBytes >= mb) {
      return '${(fileSizeBytes / mb).toStringAsFixed(1)} MB';
    } else if (fileSizeBytes >= kb) {
      return '${(fileSizeBytes / kb).toStringAsFixed(0)} KB';
    }
    return '$fileSizeBytes B';
  }

  @override
  String toString() =>
      'DownloadResult(fileName: $fileName, size: $fileSizeFormatted)';
}
