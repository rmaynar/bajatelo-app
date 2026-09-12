import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bajatelo/core/interfaces/i_downloader_service.dart';
import 'package:bajatelo/core/models/video_info.dart';
import 'package:bajatelo/core/models/download_result.dart';

class AndroidDownloaderService implements IDownloaderService {
  static const _channel = MethodChannel('maynar.bajatelo/downloader');
  static const _progressChannel = EventChannel('maynar.bajatelo/progress');

  @override
  Future<VideoInfo> getVideoInfo(String url) async {
    try {
      final String result = await _channel.invokeMethod('getVideoInfo', {'url': url});
      return VideoInfo.fromJson(jsonDecode(result));
    } on PlatformException catch (e) {
      throw Exception('Failed to get video info: ${e.message}');
    }
  }

  @override
  Future<DownloadResult> downloadMedia(
    String url,
    DownloadFormat format, {
    void Function(double progress)? onProgress,
  }) async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    // Get temp directory for yt-dlp to download into before moving
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/bajatelo_temp';

    if (onProgress != null) {
      _progressChannel.receiveBroadcastStream().listen((event) {
        if (event is double) {
          onProgress(event);
        }
      });
    }

    try {
      final String result = await _channel.invokeMethod('downloadMedia', {
        'url': url,
        'format': format == DownloadFormat.video ? 'video' : 'audio',
        'outputPath': outputPath,
      });

      return DownloadResult.fromJson(jsonDecode(result));
    } on PlatformException catch (e) {
      throw Exception('Failed to download media: ${e.message}');
    }
  }

  @override
  Future<void> cancelDownload() async {
    try {
      await _channel.invokeMethod('cancelDownload');
    } on PlatformException catch (e) {
      throw Exception('Failed to cancel download: ${e.message}');
    }
  }

  @override
  Future<void> updateEngine() async {
    try {
      await _channel.invokeMethod('updateEngine');
    } on PlatformException catch (e) {
      throw Exception('Failed to update engine: ${e.message}');
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 33) {
        final videoStatus = await Permission.videos.request();
        final audioStatus = await Permission.audio.request();
        return videoStatus.isGranted || audioStatus.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }
}
