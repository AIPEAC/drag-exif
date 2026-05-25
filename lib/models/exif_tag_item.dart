/*
DragExif - EXIF metadata viewer
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

class ExifTagItem {
  final int index;
  final String tagId;
  final String tagGroup;
  final String tagName;
  final String tagValue;

  const ExifTagItem({
    required this.index,
    required this.tagId,
    required this.tagGroup,
    required this.tagName,
    required this.tagValue,
  });

  Map<String, dynamic> toJson() => {
        'Index': index,
        'TagGroup': tagGroup,
        'TagId': tagId,
        'TagName': tagName,
        'TagValue': tagValue,
      };
}

enum ExportFileType { text, csv, json }

/// Represents a tag across multiple files.
/// When files have different values, [displayValue] shows "<unequal>".
class MergedTagItem {
  final String tagId;
  final String tagGroup;
  final String tagName;
  final Map<String, String> fileValues; // filePath -> original value
  final String displayValue;            // common value or "<unequal>"
  final bool isUnequal;
  String? pendingValue;                 // user-edited value not yet saved

  MergedTagItem({
    required this.tagId,
    required this.tagGroup,
    required this.tagName,
    required this.fileValues,
    required this.displayValue,
    required this.isUnequal,
    this.pendingValue,
  });

  /// The value to show in the table (pending edit takes precedence)
  String get currentValue => pendingValue ?? displayValue;

  /// Whether this tag has unsaved pending changes
  bool get hasPendingChange => pendingValue != null;

  /// Build merged view from multiple file tag lists
  static Map<String, List<MergedTagItem>> mergeFiles(
    Map<String, List<ExifTagItem>> fileTags,
  ) {
    // Group by (tagGroup, tagName) -> Map<filePath, value>
    final tagMap = <String, Map<String, String>>{};
    final tagMeta = <String, (String tagId, String tagGroup, String tagName)>{};

    fileTags.forEach((filePath, items) {
      for (final item in items) {
        final key = '${item.tagGroup}|${item.tagName}';
        tagMap.putIfAbsent(key, () => {})[filePath] = item.tagValue;
        tagMeta[key] = (item.tagId, item.tagGroup, item.tagName);
      }
    });

    // Group by tagGroup for display
    final result = <String, List<MergedTagItem>>{};

    tagMap.forEach((key, values) {
      final meta = tagMeta[key]!;
      final uniqueValues = values.values.toSet();
      final isUnequal = uniqueValues.length > 1;
      final displayValue = isUnequal ? '<unequal>' : uniqueValues.first;

      final merged = MergedTagItem(
        tagId: meta.$1,
        tagGroup: meta.$2,
        tagName: meta.$3,
        fileValues: Map.from(values),
        displayValue: displayValue,
        isUnequal: isUnequal,
      );

      result.putIfAbsent(meta.$2, () => []).add(merged);
    });

    // Sort items within each group by tagName
    result.forEach((group, items) {
      items.sort((a, b) => a.tagName.compareTo(b.tagName));
    });

    return result;
  }
}
