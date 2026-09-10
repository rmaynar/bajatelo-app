import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class YtdlpProcessRunner {
  Process? _activeProcess;

  Future<Map<String, dynamic>> extractInfo(String url, String ytdlpPath, String ffmpegPath) async {
    final result = await Process.run(ytdlpPath, [
      '--dump-json',
      '--no-download',
      '--ffmpeg-location',
      ffmpegPath,
      url,
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to extract info: ${result.stderr}');
    }

    return jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
  }

  Future<String> download(
    String url,
    String format,
    String outputDir,
    String ytdlpPath,
    String ffmpegPath, {
    void Function(double)? onProgress,
  }) async {
    final args = [
      '--newline',
      '--ffmpeg-location',
      ffmpegPath,
      '-o',
      p.join(outputDir, '%(title)s.%(ext)s'),
    ];

    if (format == 'audio') {
      args.addAll([
        '-f',
        'bestaudio/best',
        '--extract-audio',
        '--audio-format',
        'mp3',
      ]);
    } else {
      args.addAll([
        '-f',
        'bestvideo+bestaudio/best',
        '--merge-output-format',
        'mp4',
      ]);
    }

    args.add(url);

    _activeProcess = await Process.start(ytdlpPath, args);

    final regex = RegExp(r'\[download\]\s+([\d.]+)%');

    _activeProcess!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      final match = regex.firstMatch(line);
      if (match != null && onProgress != null) {
        final progress = double.tryParse(match.group(1) ?? '0');
        if (progress != null) {
          onProgress(progress / 100.0);
        }
      }
    });

    final stderrString = StringBuffer();
    _activeProcess!.stderr.transform(utf8.decoder).listen((line) {
      stderrString.write(line);
    });

    final exitCode = await _activeProcess!.exitCode;
    _activeProcess = null;

    if (exitCode != 0) {
      throw Exception('Download failed with exit code $exitCode: $stderrString');
    }

    final dir = Directory(outputDir);
    final files = dir.listSync().whereType<File>().toList();
    if (files.isEmpty) {
      throw Exception('No file found in output directory');
    }
    
    return files.first.path;
  }

  void cancel() {
    _activeProcess?.kill(ProcessSignal.sigterm);
    _activeProcess = null;
  }

  Future<void> updateYtdlp(String ytdlpPath) async {
    final result = await Process.run(ytdlpPath, ['--update']);
    if (result.exitCode != 0) {
      throw Exception('Failed to update yt-dlp: ${result.stderr}');
    }
  }
}
