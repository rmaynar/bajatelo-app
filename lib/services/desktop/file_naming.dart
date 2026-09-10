import 'dart:io';
import 'package:path/path.dart' as p;

String sanitizeFilename(String title) {
  final invalidChars = RegExp(r'[\\/:*?"<>|]');
  String sanitized = title.replaceAll(invalidChars, '_').trim();
  if (sanitized.length > 200) {
    sanitized = sanitized.substring(0, 200);
  }
  return sanitized;
}

String resolveUniqueFilePath(String directory, String baseName, String extension) {
  String currentName = '$baseName.$extension';
  String currentPath = p.join(directory, currentName);
  int counter = 1;
  
  while (File(currentPath).existsSync()) {
    currentName = '$baseName ($counter).$extension';
    currentPath = p.join(directory, currentName);
    counter++;
  }
  
  return currentPath;
}
