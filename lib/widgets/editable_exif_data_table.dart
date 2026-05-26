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

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exif_tag_item.dart' show MergedTagItem;

class EditableExifDataTable extends StatefulWidget {
  final Map<String, List<MergedTagItem>> groupedItems;
  final bool showIndex;
  final bool showTagId;
  final bool showTagName;
  final bool showTagValue;
  final void Function(MergedTagItem item)? onEdit;

  const EditableExifDataTable({
    super.key,
    required this.groupedItems,
    this.showIndex = true,
    this.showTagId = true,
    this.showTagName = true,
    this.showTagValue = true,
    this.onEdit,
  });

  @override
  State<EditableExifDataTable> createState() => _EditableExifDataTableState();
}

class _EditableExifDataTableState extends State<EditableExifDataTable> {
  int? _editingIndex;
  String? _editingGroup;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupKeys = widget.groupedItems.keys.toList();

    return ListView.builder(
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupName = groupKeys[groupIndex];
        final groupItems = widget.groupedItems[groupName]!;

        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            groupName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${groupItems.length} tags'),
          children: [
            SizedBox(
              height: groupItems.length * 52.0 + 56,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 600,
                columns: _buildColumns(),
                rows: List.generate(groupItems.length, (index) {
                  return _buildRow(groupItems[index], groupName, index);
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  List<DataColumn2> _buildColumns() {
    final columns = <DataColumn2>[];
    if (widget.showIndex) {
      columns.add(DataColumn2(size: ColumnSize.S, label: const Text('')));
    }
    if (widget.showTagId) {
      columns.add(DataColumn2(size: ColumnSize.S, label: const Text('Tag ID')));
    }
    if (widget.showTagName) {
      columns.add(DataColumn2(size: ColumnSize.M, label: const Text('Tag Name')));
    }
    if (widget.showTagValue) {
      columns.add(DataColumn2(size: ColumnSize.L, label: const Text('Value')));
    }
    return columns;
  }

  /// Groups that contain read-only file-system derived tags.
  static const _readOnlyGroups = {'File', 'ICC_Profile'};

  bool _isReadOnly(MergedTagItem item) =>
      _readOnlyGroups.contains(item.tagGroup);

  void _showReadOnlyNotice(MergedTagItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.tagGroup} › ${item.tagName} is read-only. '
          'File-system properties cannot be edited through EXIF metadata.',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        width: 400,
      ),
    );
  }

  DataRow2 _buildRow(MergedTagItem item, String groupName, int index) {
    final isEditing = _editingGroup == groupName && _editingIndex == index;
    final displayValue = item.currentValue;
    final isUnequal = item.isUnequal && item.pendingValue == null;
    final hasPending = item.hasPendingChange;
    final readOnly = _isReadOnly(item);

    final cells = <DataCell>[];

    if (widget.showIndex) {
      cells.add(DataCell(Text('${index + 1}')));
    }
    if (widget.showTagId) {
      cells.add(DataCell(Text(item.tagId)));
    }
    if (widget.showTagName) {
      cells.add(
        DataCell(
          Tooltip(
            message: item.tagName,
            waitDuration: const Duration(milliseconds: 300),
            child: Text(
              item.tagName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    if (widget.showTagValue) {
      if (isEditing && !readOnly) {
        cells.add(
          DataCell(
            TextField(
              controller: _editController,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                _finishEdit(item, value);
              },
            ),
          ),
        );
      } else if (readOnly) {
        cells.add(
          DataCell(
            InkWell(
              onTap: () => _showReadOnlyNotice(item),
              onDoubleTap: () => _showValueDialog(item),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Tooltip(
                  message: displayValue,
                  waitDuration: const Duration(milliseconds: 300),
                  child: Text(
                    displayValue,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      color: isUnequal
                          ? Theme.of(context).colorScheme.error
                          : hasPending
                              ? Colors.blue
                              : null,
                      fontStyle: isUnequal ? FontStyle.italic : null,
                      fontWeight: hasPending ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        cells.add(
          DataCell(
            InkWell(
              onTap: () => _startEdit(item, groupName, index),
              onDoubleTap: () => _showValueDialog(item),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Tooltip(
                  message: displayValue,
                  waitDuration: const Duration(milliseconds: 300),
                  child: Text(
                    displayValue,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      color: isUnequal
                          ? Theme.of(context).colorScheme.error
                          : hasPending
                              ? Colors.blue
                              : null,
                      fontStyle: isUnequal ? FontStyle.italic : null,
                      fontWeight: hasPending ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return DataRow2(
      cells: cells,
      color: hasPending
          ? WidgetStateProperty.all(
              Colors.blue.withValues(alpha: 0.12),
            )
          : null,
    );
  }

  Future<void> _showValueDialog(MergedTagItem item) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.tagGroup} › ${item.tagName}'),
        content: SingleChildScrollView(
          child: SelectableText(item.currentValue),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.currentValue));
              Navigator.of(context).pop();
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startEdit(MergedTagItem item, String groupName, int index) {
    setState(() {
      _editingGroup = groupName;
      _editingIndex = index;
      _editController.text = item.isUnequal ? '' : item.displayValue;
    });
  }

  void _finishEdit(MergedTagItem item, String value) {
    setState(() {
      _editingGroup = null;
      _editingIndex = null;
    });
    widget.onEdit?.call(item..pendingValue = value);
  }
}
