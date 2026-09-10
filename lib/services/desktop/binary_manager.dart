import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

class BinaryPaths {
  final String ytdlpPath;
  final String ffmpegPath;

  BinaryPaths({required this.ytdlpPath, required this.ffmpegPath});
}

class BinaryManager {
  Future<BinaryPaths> ensureBinaries({void Function(String status)? onStatus}) async {
    final supportDir = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(supportDir.path, 'bin'));
    if (!binDir.existsSync()) {
      binDir.createSync(recursive: true);
    }
    
    onStatus?.call("Checking yt-dlp...");
    final ytdlpPath = await _ensureYtdlp(binDir);
    
    onStatus?.call("Checking ffmpeg...");
    final ffmpegPath = await _ensureFfmpeg(binDir);
    
    return BinaryPaths(ytdlpPath: ytdlpPath, ffmpegPath: ffmpegPath);
  }

  Future<String> _ensureYtdlp(Directory binDir) async {
    final fileName = Platform.isWindows ? 'yt-dlp.exe' : (Platform.isMacOS ? 'yt-dlp_macos' : 'yt-dlp_linux');
    final filePath = p.join(binDir.path, fileName);
    final versionFile = File(p.join(binDir.path, '.yt-dlp-version'));
    
    if (File(filePath).existsSync() && versionFile.existsSync()) {
      return filePath;
    }
    
    String url;
    if (Platform.isWindows) {
      url = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
    } else if (Platform.isMacOS) {
      url = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos';
    } else {
      url = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux';
    }
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', filePath]);
      }
      await versionFile.writeAsString('latest');
      return filePath;
    } else {
      throw Exception('Failed to download yt-dlp: ${response.statusCode}');
    }
  }

  Future<String> _ensureFfmpeg(Directory binDir) async {
    // Check system ffmpeg first
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', ['ffmpeg']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final lines = result.stdout.toString().split('\n');
        return lines.first.trim();
      }
    } catch (_) {}

    final fileName = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    final filePath = p.join(binDir.path, fileName);
    final versionFile = File(p.join(binDir.path, '.ffmpeg-version'));
    
    if (File(filePath).existsSync() && versionFile.existsSync()) {
      return filePath;
    }

    String url;
    if (Platform.isMacOS) {
      url = 'https://evermeet.cx/ffmpeg/getrelease/zip';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final zipFile = File(p.join(binDir.path, 'ffmpeg.zip'));
        await zipFile.writeAsBytes(response.bodyBytes);
        await Process.run('unzip', ['-o', zipFile.path, '-d', binDir.path]);
        await zipFile.delete();
      } else {
        throw Exception('Failed to download ffmpeg');
      }
    } else if (Platform.isLinux) {
      url = 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tarFile = File(p.join(binDir.path, 'ffmpeg.tar.xz'));
        await tarFile.writeAsBytes(response.bodyBytes);
        await Process.run('tar', ['xf', tarFile.path, '-C', binDir.path, '--strip-components=1']);
        await tarFile.delete();
      } else {
        throw Exception('Failed to download ffmpeg');
      }
    } else if (Platform.isWindows) {
      url = 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final zipFile = File(p.join(binDir.path, 'ffmpeg.zip'));
        await zipFile.writeAsBytes(response.bodyBytes);
        
        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          if (file.isFile && file.name.endsWith('ffmpeg.exe')) {
            final outFile = File(filePath);
            await outFile.writeAsBytes(file.content as List<int>);
            break;
          }
        }
        await zipFile.delete();
      } else {
        throw Exception('Failed to download ffmpeg');
      }
    }

    if (!Platform.isWindows && File(filePath).existsSync()) {
      await Process.run('chmod', ['+x', filePath]);
    }
    
    if (File(filePath).existsSync()) {
      await versionFile.writeAsString('latest');
      return filePath;
    }
    throw Exception('Failed to setup ffmpeg');
  }
}
