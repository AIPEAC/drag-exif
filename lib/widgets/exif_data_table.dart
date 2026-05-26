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

import '../models/exif_tag_item.dart';

class ExifDataTable extends StatefulWidget {
  final List<ExifTagItem> items;
  final bool showIndex;
  final bool showTagId;
  final bool showTagName;
  final bool showTagValue;
  final void Function(ExifTagItem item, String column)? onCellTap;

  const ExifDataTable({
    super.key,
    required this.items,
    this.showIndex = true,
    this.showTagId = true,
    this.showTagName = true,
    this.showTagValue = true,
    this.onCellTap,
  });

  @override
  State<ExifDataTable> createState() => _ExifDataTableState();
}

class _ExifDataTableState extends State<ExifDataTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<ExifTagItem> get _sortedItems {
    final list = List<ExifTagItem>.from(widget.items);
    if (_sortColumnIndex == null) return list;

    list.sort((a, b) {
      Comparable va;
      Comparable vb;

      switch (_sortColumnIndex) {
        case 0:
          va = a.index;
          vb = b.index;
        case 1:
          va = a.tagId;
          vb = b.tagId;
        case 2:
          va = a.tagName;
          vb = b.tagName;
        case 3:
          va = a.tagValue;
          vb = b.tagValue;
        default:
          return 0;
      }

      final comparison = va.compareTo(vb);
      return _sortAscending ? comparison : -comparison;
    });

    return list;
  }

  Map<String, List<ExifTagItem>> get _groupedItems {
    final groups = <String, List<ExifTagItem>>{};
    for (final item in _sortedItems) {
      groups.putIfAbsent(item.tagGroup, () => []).add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedItems;
    final groupKeys = groups.keys.toList();

    return ListView.builder(
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupName = groupKeys[groupIndex];
        final groupItems = groups[groupName]!;

        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            groupName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text('${groupItems.length} tags'),
          children: [
            SizedBox(
              height: groupItems.length * 48.0 + 56,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 600,
                columns: _buildColumns(),
                rows: groupItems.map((item) => _buildRow(item)).toList(),
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
      columns.add(
        DataColumn2(
          size: ColumnSize.S,
          label: const Text(''),
          onSort: (columnIndex, ascending) => _onSort(0, ascending),
        ),
      );
    }
    if (widget.showTagId) {
      columns.add(
        DataColumn2(
          size: ColumnSize.S,
          label: const Text('Tag ID'),
          onSort: (columnIndex, ascending) => _onSort(1, ascending),
        ),
      );
    }
    if (widget.showTagName) {
      columns.add(
        DataColumn2(
          size: ColumnSize.M,
          label: const Text('Tag Name'),
          onSort: (columnIndex, ascending) => _onSort(2, ascending),
        ),
      );
    }
    if (widget.showTagValue) {
      columns.add(
        DataColumn2(
          size: ColumnSize.L,
          label: const Text('Value'),
          onSort: (columnIndex, ascending) => _onSort(3, ascending),
        ),
      );
    }

    return columns;
  }

  DataRow2 _buildRow(ExifTagItem item) {
    final cells = <DataCell>[];

    if (widget.showIndex) {
      cells.add(DataCell(Text('${item.index}')));
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
              style: item.tagName == 'File Name'
                  ? const TextStyle(fontWeight: FontWeight.w600)
                  : null,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    if (widget.showTagValue) {
      cells.add(
        DataCell(
          InkWell(
            onDoubleTap: () => _showValueDialog(item),
            child: Tooltip(
              message: item.tagValue,
              waitDuration: const Duration(milliseconds: 300),
              child: Text(
                item.tagValue,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ),
      );
    }

    return DataRow2(
      cells: cells,
      onTap: () => widget.onCellTap?.call(item, ''),
    );
  }

  Future<void> _showValueDialog(ExifTagItem item) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.tagGroup} › ${item.tagName}'),
        content: SingleChildScrollView(
          child: SelectableText(item.tagValue),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.tagValue));
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

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = ascending;
      }
    });
  }
}
