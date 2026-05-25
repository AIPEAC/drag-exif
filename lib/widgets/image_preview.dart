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

import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final String? filePath;
  final double maxHeight;

  const ImagePreview({
    super.key,
    this.filePath,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (filePath == null || filePath!.isEmpty) {
      return _placeholder(context, Icons.image, 'No preview');
    }

    final file = File(filePath!);
    if (!file.existsSync()) {
      return _placeholder(context, Icons.broken_image, 'File not found');
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          file,
          key: ValueKey(filePath),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return _placeholder(context, Icons.broken_image, 'Cannot load image');
          },
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, IconData icon, String label) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
