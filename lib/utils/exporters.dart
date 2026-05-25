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
import 'dart:convert';

import '../models/exif_tag_item.dart';

class Exporters {
  static String toText(List<ExifTagItem> items) {
    final buffer = StringBuffer();
    String currentGroup = '';

    for (final item in items) {
      if (item.tagGroup != currentGroup) {
        if (currentGroup.isNotEmpty) buffer.writeln();
        buffer.writeln('[${item.tagGroup}]');
        currentGroup = item.tagGroup;
      }
      buffer.writeln('${item.tagId}\t${item.tagName}\t${item.tagValue}');
    }

    return buffer.toString();
  }

  static String toCsv(List<ExifTagItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('"Index","TagGroup","TagId","TagName","TagValue"');

    for (final item in items) {
      buffer.writeln(
        '"${item.index}","${_escapeCsv(item.tagGroup)}","${_escapeCsv(item.tagId)}","${_escapeCsv(item.tagName)}","${_escapeCsv(item.tagValue)}"',
      );
    }

    return buffer.toString();
  }

  static String toJson(List<ExifTagItem> items) {
    final list = items.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  static String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }
}
