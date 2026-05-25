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

class ErrorDisplay extends StatelessWidget {
  final String error;
  final String? details;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          '❌ Error:\n$error${details != null ? '\n\nℹ️ Details:\n$details' : ''}',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
