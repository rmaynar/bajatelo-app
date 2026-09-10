import 'dart:convert';

/// Metadata extracted from a video URL before downloading.
class VideoInfo {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final int? durationSeconds;

  const VideoInfo({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnailUrl: json['thumbnail'] as String?,
      durationSeconds: (json['duration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnailUrl,
        'duration': durationSeconds,
      };

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() => 'VideoInfo(id: $id, title: $title, duration: $durationSeconds)';
}
