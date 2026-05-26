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
import 'package:flutter/services.dart';

import '../models/loaded_file.dart';
import 'image_preview.dart';

class FileListPanel extends StatefulWidget {
  final List<LoadedFile> files;
  final Set<int> selectedIndices;
  final int? lastClickedIndex;
  final void Function(int index, {bool ctrl, bool shift}) onSelect;
  final void Function(int index)? onRemove;
  final void Function(int index, String newName)? onRename;

  const FileListPanel({
    super.key,
    required this.files,
    required this.selectedIndices,
    this.lastClickedIndex,
    required this.onSelect,
    this.onRemove,
    this.onRename,
  });

  @override
  State<FileListPanel> createState() => _FileListPanelState();
}

class _FileListPanelState extends State<FileListPanel> {
  int? _renamingIndex;
  final _renameController = TextEditingController();
  final _renameFocusNode = FocusNode();

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    super.dispose();
  }

  void _startRename(int index) {
    if (widget.onRename == null) return;
    final fileName = widget.files[index].fileName;
    _renameController.text = fileName;
    setState(() => _renamingIndex = index);

    // Select the basename (without extension) after the frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lastDot = fileName.lastIndexOf('.');
      if (lastDot > 0) {
        _renameController.selection =
            TextSelection(baseOffset: 0, extentOffset: lastDot);
      } else {
        _renameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: fileName.length,
        );
      }
      _renameFocusNode.requestFocus();
    });
  }

  void _finishRename(int index) {
    final newName = _renameController.text.trim();
    if (newName.isNotEmpty && newName != widget.files[index].fileName) {
      widget.onRename!(index, newName);
    }
    setState(() => _renamingIndex = null);
  }

  void _cancelRename() {
    setState(() => _renamingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final singleSelectedPath = widget.selectedIndices.length == 1
        ? widget.files[widget.selectedIndices.first].path
        : null;

    return Column(
      children: [
        // File count header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.folder, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.files.length} file${widget.files.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${widget.selectedIndices.length} selected',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // File list
        Expanded(
          child: ListView.builder(
            itemCount: widget.files.length,
            itemBuilder: (context, index) {
              final file = widget.files[index];
              final isSelected = widget.selectedIndices.contains(index);
              final isRenaming = _renamingIndex == index;

              return GestureDetector(
                onTap: () {
                  if (isRenaming) return;
                  final ctrl = HardwareKeyboard.instance.isControlPressed ||
                      HardwareKeyboard.instance.isMetaPressed;
                  final shift = HardwareKeyboard.instance.isShiftPressed;
                  widget.onSelect(index, ctrl: ctrl, shift: shift);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : null,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (file.isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      else if (file.hasError)
                        Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error)
                      else if (file.isLoaded)
                        Icon(Icons.check_circle_outline, size: 16, color: theme.colorScheme.primary)
                      else
                        Icon(Icons.insert_drive_file, size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: isRenaming
                            ? Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey == LogicalKeyboardKey.escape) {
                                    _cancelRename();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: TextField(
                                  controller: _renameController,
                                  focusNode: _renameFocusNode,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => _finishRename(index),
                                  onEditingComplete: () => _finishRename(index),
                                  onTapOutside: (_) => _finishRename(index),
                                ),
                              )
                            : GestureDetector(
                                onDoubleTap: () => _startRename(index),
                                child: Text(
                                  file.fileName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: file.hasError
                                        ? theme.colorScheme.error
                                        : isSelected
                                            ? theme.colorScheme.onPrimaryContainer
                                            : theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ),
                      if (widget.onRemove != null)
                        InkWell(
                          onTap: () => widget.onRemove!(index),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Preview panel
        if (singleSelectedPath != null)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(Icons.preview, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ImagePreview(filePath: singleSelectedPath),
              ],
            ),
          ),
      ],
    );
  }
}
