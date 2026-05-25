import 'dart:convert';
import 'dart:io';

import '../models/exif_tag_item.dart';
import '../utils/constants.dart';

class ExifToolService {
  String exifToolPath = '';
  String originalFilePath = '';
  String cleanedFilePath = '';
  bool isFilePathDirty = false;

  String get currentExifToolPath {
    if (exifToolPath.trim().isEmpty) {
      return _defaultExifToolPath;
    }
    return exifToolPath;
  }

  String get _defaultExifToolPath {
    if (Platform.isWindows) {
      return '${Directory(Platform.resolvedExecutable).parent.path}\\exiftool.exe';
    }
    return 'exiftool';
  }

  /// Checks if ExifTool is available at the given or default path.
  /// Returns the resolved path if found, null otherwise.
  static Future<String?> checkExifToolExists([String? customPath]) async {
    final path = customPath?.trim() ?? '';

    if (path.isNotEmpty) {
      // User-specified path
      final file = File(path);
      if (await file.exists()) return path;
      // Also try with .exe on Windows
      if (Platform.isWindows) {
        final exeFile = File('$path.exe');
        if (await exeFile.exists()) return '$path.exe';
      }
      return null;
    }

    // Default: check bundled exiftool.exe on Windows
    if (Platform.isWindows) {
      final bundled = '${Directory(Platform.resolvedExecutable).parent.path}\\exiftool.exe';
      if (await File(bundled).exists()) return bundled;
    }

    // Check PATH for 'exiftool'
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        ['exiftool'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
        runInShell: Platform.isWindows,
      );
      if (result.exitCode == 0) {
        final found = result.stdout.toString().trim().split('\n').first.trim();
        if (found.isNotEmpty) return found;
      }
    } catch (_) {}

    return null;
  }

  Future<List<ExifTagItem>> readAsync(
    String filePath, {
    List<String> extraArgs = const [],
  }) async {
    await _deleteTempFiles();

    isFilePathDirty = _checkAndPurifyUnicodePath(filePath);
    originalFilePath = filePath;
    cleanedFilePath = isFilePathDirty ? _tempFilePath! : filePath;

    final args = <String>[
      ...Constants.defaultCommands.split(' '),
      ...extraArgs,
      cleanedFilePath,
    ];

    final result = await Process.run(
      currentExifToolPath,
      args,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.stderr.toString().isNotEmpty &&
        !result.stderr.toString().startsWith('-- press ENTER --')) {
      throw Exception(result.stderr.toString().trim());
    }

    return parseExifTags(result.stdout.toString());
  }

  Future<void> _deleteTempFiles() async {
    if (isFilePathDirty && originalFilePath != cleanedFilePath) {
      try {
        final file = File(cleanedFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _tempFilePath = null;
  }

  String? _tempFilePath;

  bool _checkAndPurifyUnicodePath(String filePath) {
    if (filePath.isEmpty) return false;

    const maxAnsiCode = 255;

    if (filePath.codeUnits.any((c) => c > maxAnsiCode)) {
      try {
        final ext = _getExtension(filePath);
        _tempFilePath = '${Directory.systemTemp.path}/dragexif_temp_${DateTime.now().millisecondsSinceEpoch}$ext';
        File(filePath).copySync(_tempFilePath!);
        return true;
      } catch (_) {}
    }

    return false;
  }

  String _getExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot >= 0) return filePath.substring(lastDot);
    return '';
  }

  List<ExifTagItem> parseExifTags(String output) {
    final items = <ExifTagItem>[];
    var hasError = false;
    var index = 0;
    final originalFileName = _getFileName(originalFilePath);

    var remaining = output;

    while (remaining.isNotEmpty) {
      var epos = remaining.indexOf('\r');
      if (epos < 0) epos = remaining.length;

      final line = remaining.substring(0, epos);

      final tpos1 = line.indexOf('\t');
      final tpos2 = line.indexOf('\t', tpos1 + 1);
      final tpos3 = line.indexOf('\t', tpos2 + 1);

      if (tpos1 > 0 && tpos2 > 0 && tpos3 > 0) {
        final tagGroup = line.substring(0, tpos1);
        final tagId = line.substring(tpos1 + 1, tpos2);
        final tagName = line.substring(tpos2 + 1, tpos3);
        var tagValue = line.substring(tpos3 + 1);

        // Remove binary data hint
        final binaryHint = ', use -b option to extract';
        final hintPos = tagValue.indexOf(binaryHint);
        if (hintPos >= 0) {
          tagValue = tagValue.substring(0, hintPos);
        }

        // Preserve original filename
        if (tagName == 'File Name') {
          tagValue = originalFileName;
        }

        items.add(ExifTagItem(
          index: index + 1,
          tagId: tagId,
          tagGroup: tagGroup,
          tagName: tagName,
          tagValue: tagValue,
        ));

        index++;
      } else {
        hasError = true;
      }

      if (epos < remaining.length) {
        epos += (remaining.length > epos + 1 && remaining[epos + 1] == '\n') ? 2 : 1;
      }
      remaining = remaining.substring(epos);
    }

    if (hasError && items.isEmpty) {
      throw Exception(
        'DragExif encountered an error while parsing the output of ExifTool. '
        'Please ensure that the command-line arguments for ExifTool are correct.',
      );
    }

    return items;
  }

  String _getFileName(String filePath) {
    final sep = Platform.pathSeparator;
    final lastSep = filePath.lastIndexOf(sep);
    if (lastSep >= 0) return filePath.substring(lastSep + 1);
    return filePath;
  }

  Future<void> dispose() async {
    await _deleteTempFiles();
  }
}
