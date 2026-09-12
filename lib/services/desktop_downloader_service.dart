import 'dart:io';
import 'package:bajatelo/core/interfaces/i_downloader_service.dart';
import 'package:bajatelo/core/models/video_info.dart';
import 'package:bajatelo/core/models/download_result.dart';
import 'package:bajatelo/services/desktop/binary_manager.dart';
import 'package:bajatelo/services/desktop/ytdlp_process_runner.dart';
import 'package:bajatelo/services/desktop/file_naming.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DesktopDownloaderService implements IDownloaderService {
  final BinaryManager _binaryManager = BinaryManager();
  final YtdlpProcessRunner _runner = YtdlpProcessRunner();
  
  BinaryPaths? _binaryPaths;
  
  Future<void> _ensureReady() async {
    _binaryPaths ??= await _binaryManager.ensureBinaries();
  }

  @override
  Future<VideoInfo> getVideoInfo(String url) async {
    await _ensureReady();
    final data = await _runner.extractInfo(url, _binaryPaths!.ytdlpPath, _binaryPaths!.ffmpegPath);
    
    return VideoInfo.fromJson({
      'id': data['id'],
      'title': data['title'],
      'thumbnailUrl': data['thumbnail'] ?? '',
      'durationSeconds': data['duration'] ?? 0,
    });
  }

  @override
  Future<DownloadResult> downloadMedia(
    String url,
    DownloadFormat format, {
    void Function(double progress)? onProgress,
  }) async {
    await _ensureReady();
    
    final tempDir = Directory.systemTemp.createTempSync('ytdl_');
    try {
      final formatStr = format == DownloadFormat.audio ? 'audio' : 'video';
      
      final downloadedPath = await _runner.download(
        url,
        formatStr,
        tempDir.path,
        _binaryPaths!.ytdlpPath,
        _binaryPaths!.ffmpegPath,
        onProgress: onProgress,
      );
      
      final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final downloadedFile = File(downloadedPath);
      final extension = p.extension(downloadedPath).replaceFirst('.', '');
      final originalBaseName = p.basenameWithoutExtension(downloadedPath);
      final sanitizedBase = sanitizeFilename(originalBaseName);
      
      final finalPath = resolveUniqueFilePath(downloadsDir.path, sanitizedBase, extension);
      final finalFile = await downloadedFile.copy(finalPath);
      
      return DownloadResult(
        filePath: finalFile.path,
        fileName: p.basename(finalFile.path),
        fileSizeBytes: await finalFile.length(),
        downloadedAt: DateTime.now(),
      );
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  @override
  Future<void> cancelDownload() async {
    _runner.cancel();
  }

  @override
  Future<void> updateEngine() async {
    await _ensureReady();
    await _runner.updateYtdlp(_binaryPaths!.ytdlpPath);
  }
}
