/*
DragExif - EXIF metadata viewer
Based on ExifGlass by Dương Diệu Pháp
Copyright (C) 2023-2025 DUONG DIEU PHAP
Project homepage: https://github.com/d2phap/ExifGlass
Copyright (C) 2026 Allen
Project homepage: https://github.com/AIPEAC/drag-exif


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
import 'dart:convert';
import 'dart:io';

import '../models/exif_tag_item.dart';
import '../utils/constants.dart';

class ExifToolService {
  String exifToolPath = '';

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
    // If the path contains non-ASCII characters, create a temp copy
    // because ExifTool may not handle Unicode paths well.
    final tempPath = _purifyUnicodePath(filePath);
    final cleanedFilePath = tempPath ?? filePath;

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

    // Clean up temp file immediately after ExifTool finishes
    if (tempPath != null) {
      try { File(tempPath).deleteSync(); } catch (_) {}
    }

    if (result.stderr.toString().isNotEmpty &&
        !result.stderr.toString().startsWith('-- press ENTER --')) {
      throw Exception(result.stderr.toString().trim());
    }

    return parseExifTags(
      output: result.stdout.toString(),
      originalFilePath: filePath,
      usedTempCopy: tempPath != null,
    );
  }

  String? _purifyUnicodePath(String filePath) {
    if (filePath.isEmpty) return null;

    const maxAnsiCode = 255;

    if (filePath.codeUnits.any((c) => c > maxAnsiCode)) {
      try {
        final ext = _getExtension(filePath);
        final tempPath = '${Directory.systemTemp.path}/dragexif_temp_${DateTime.now().millisecondsSinceEpoch}$ext';
        File(filePath).copySync(tempPath);
        return tempPath;
      } catch (_) {}
    }

    return null;
  }

  String _getExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot >= 0) return filePath.substring(lastDot);
    return '';
  }

  List<ExifTagItem> parseExifTags({
    required String output,
    required String originalFilePath,
    required bool usedTempCopy,
  }) {
    final items = <ExifTagItem>[];
    var index = 0;
    final originalFileName = _getFileName(originalFilePath);
    final originalDir = _getDirectory(originalFilePath);

    String? pendingGroup;
    String? pendingId;
    String? pendingName;
    final pendingValue = StringBuffer();

    void flushPending() {
      if (pendingName == null) return;

      var tagValue = pendingValue.toString();

      // Remove binary data hint
      const binaryHint = ', use -b option to extract';
      final hintPos = tagValue.indexOf(binaryHint);
      if (hintPos >= 0) {
        tagValue = tagValue.substring(0, hintPos);
      }

      // Normalize all line endings to \n (Windows \r\n, old Mac \r -> \n)
      tagValue = tagValue.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // Restore original path info when a temp copy was used for Unicode paths
      if (usedTempCopy) {
        if (pendingName == 'File Name') {
          tagValue = originalFileName;
        } else if (pendingName == 'Directory') {
          tagValue = originalDir;
        }
      }

      items.add(ExifTagItem(
        index: index + 1,
        tagId: pendingId!,
        tagGroup: pendingGroup!,
        tagName: pendingName!,
        tagValue: tagValue,
      ));

      index++;
      pendingGroup = null;
      pendingId = null;
      pendingName = null;
      pendingValue.clear();
    }

    for (final line in const LineSplitter().convert(output)) {
      if (line.trim().isEmpty) continue;

      final tpos1 = line.indexOf('\t');
      final tpos2 = line.indexOf('\t', tpos1 + 1);
      final tpos3 = line.indexOf('\t', tpos2 + 1);

      if (tpos1 > 0 && tpos2 > 0 && tpos3 > 0) {
        // New tag line: Group \t TagID \t TagName \t Value
        flushPending();
        pendingGroup = line.substring(0, tpos1);
        pendingId = line.substring(tpos1 + 1, tpos2);
        pendingName = line.substring(tpos2 + 1, tpos3);
        pendingValue.write(line.substring(tpos3 + 1));
      } else if (pendingName != null) {
        // Continuation line (the tag value contained a line break)
        pendingValue.write('\n');
        pendingValue.write(line);
      }
      // Stray lines before the first tag are ignored
    }

    flushPending();

    if (items.isEmpty) {
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

  String _getDirectory(String filePath) {
    final sep = Platform.pathSeparator;
    final lastSep = filePath.lastIndexOf(sep);
    if (lastSep >= 0) return filePath.substring(0, lastSep);
    return '';
  }

  /// Writes tag changes to a file using ExifTool.
  /// Changes are written to a temp file first, then moved over the original.
  /// Returns the path to the modified file.
  Future<String> writeTagsAsync(
    String filePath,
    Map<String, String> tagChanges, {
    List<String> extraArgs = const [],
  }) async {
    if (tagChanges.isEmpty) return filePath;

    final ext = _getExtension(filePath);
    final tempFile = '${Directory.systemTemp.path}/dragexif_write_${DateTime.now().millisecondsSinceEpoch}$ext';

    // Copy original to temp
    await File(filePath).copy(tempFile);

    // Build ExifTool arguments: -TagName="value" for each change
    final args = <String>[
      ...extraArgs,
      ...tagChanges.entries.map((e) => '-${e.key}=${e.value}'),
      '-overwrite_original',
      tempFile,
    ];

    final result = await Process.run(
      currentExifToolPath,
      args,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      // Clean up temp file on failure
      try { File(tempFile).deleteSync(); } catch (_) {}
      throw Exception('ExifTool failed to write tags: ${result.stderr}');
    }

    return tempFile;
  }

  Future<void> dispose() async {
    // No-op: temp files are cleaned up immediately after each readAsync call.
  }
}
