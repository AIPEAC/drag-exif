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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exif_tag_item.dart';
import '../utils/exporters.dart';

class ExportMenu extends StatelessWidget {
  final List<ExifTagItem> items;
  final String? defaultFileName;

  const ExportMenu({
    super.key,
    required this.items,
    this.defaultFileName,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExportFileType>(
      tooltip: 'Export as…',
      onSelected: (type) => _export(context, type),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ExportFileType.text,
          child: Text('Text file…'),
        ),
        const PopupMenuItem(
          value: ExportFileType.csv,
          child: Text('CSV file…'),
        ),
        const PopupMenuItem(
          value: ExportFileType.json,
          child: Text('JSON file…'),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Export as…'),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, ExportFileType type) async {
    String content;
    String ext;

    switch (type) {
      case ExportFileType.text:
        content = Exporters.toText(items);
        ext = 'txt';
      case ExportFileType.csv:
        content = Exporters.toCsv(items);
        ext = 'csv';
      case ExportFileType.json:
        content = Exporters.toJson(items);
        ext = 'json';
    }

    // For now, copy to clipboard as a quick win
    // File save dialog can be added later with file_selector
    await Clipboard.setData(ClipboardData(text: content));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported as $ext and copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
