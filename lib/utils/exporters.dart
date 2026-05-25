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
