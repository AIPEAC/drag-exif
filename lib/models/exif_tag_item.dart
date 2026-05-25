/*
DragExif - EXIF metadata viewer
Copyright (C) 2026 Allen
Project homepage: https://github.com/AIPEAC/drag-exif

Based on ExifGlass by Dương Diệu Pháp
Copyright (C) 2023-2025 DUONG DIEU PHAP
Project homepage: https://github.com/d2phap/ExifGlass

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
