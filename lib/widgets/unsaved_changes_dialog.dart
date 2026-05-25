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

import 'package:flutter/material.dart';

enum UnsavedAction { save, discard, cancel }

class UnsavedChangesDialog extends StatelessWidget {
  final int changeCount;

  const UnsavedChangesDialog({
    super.key,
    required this.changeCount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('Unsaved Changes'),
        ],
      ),
      content: Text(
        'You have $changeCount unsaved ${changeCount == 1 ? 'change' : 'changes'}. '
        'Do you want to save them before continuing?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(UnsavedAction.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(UnsavedAction.discard),
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(UnsavedAction.save),
          child: const Text('Save'),
        ),
      ],
    );
  }

  static Future<UnsavedAction> show(BuildContext context, {required int changeCount}) async {
    return await showDialog<UnsavedAction>(
          context: context,
          barrierDismissible: false,
          builder: (_) => UnsavedChangesDialog(changeCount: changeCount),
        ) ??
        UnsavedAction.cancel;
  }
}
