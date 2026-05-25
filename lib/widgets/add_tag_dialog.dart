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

import '../models/exif_tag_definition.dart';
import '../services/exif_tag_catalog.dart';

class AddTagDialog extends StatefulWidget {
  const AddTagDialog({super.key});

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();

  static Future<({String tagName, String group, String value})?> show(BuildContext context) async {
    return await showDialog<({String tagName, String group, String value})>(
      context: context,
      builder: (_) => const AddTagDialog(),
    );
  }
}

class _AddTagDialogState extends State<AddTagDialog> {
  final _searchController = TextEditingController();
  final _valueController = TextEditingController();
  final _customController = TextEditingController();
  final _focusNode = FocusNode();

  List<ExifTagDefinition> _filtered = [];
  ExifTagDefinition? _selected;
  bool _useCustom = false;

  @override
  void initState() {
    super.initState();
    _filtered = ExifTagCatalog.allTags;
    _searchController.addListener(_onSearchChanged);
    // Focus search field after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _valueController.dispose();
    _customController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filtered = ExifTagCatalog.search(_searchController.text);
      _useCustom = _searchController.text.trim().isNotEmpty && _filtered.isEmpty;
    });
  }

  void _onSelect(ExifTagDefinition tag) {
    setState(() {
      _selected = tag;
      _useCustom = false;
    });
  }

  void _onAdd() {
    final tagName = _useCustom
        ? _customController.text.trim()
        : _selected?.tagName ?? '';
    final group = _selected?.group ?? 'EXIF';
    final value = _valueController.text;

    if (tagName.isEmpty) return;

    Navigator.of(context).pop((tagName: tagName, group: group, value: value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add EXIF Tag',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type to search tags (e.g. Date, GPS, Lens...)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _focusNode.requestFocus();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filtered.length} tags available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Tag list
              Expanded(
                child: _filtered.isEmpty && !_useCustom
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'No matching tags',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final tag = _filtered[index];
                          final isSelected = _selected?.tagName == tag.tagName;
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            title: Text(
                              tag.tagName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            subtitle: tag.description != null
                                ? Text('${tag.group} — ${tag.description}')
                                : Text(tag.group),
                            onTap: () => _onSelect(tag),
                          );
                        },
                      ),
              ),

              // Custom tag option when search has no results
              if (_useCustom) ...[
                const Divider(),
                Text(
                  'Custom tag',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customController,
                  decoration: const InputDecoration(
                    hintText: 'Enter custom tag name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              // Value input (shown when tag selected or custom mode)
              if (_selected != null || _useCustom) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (_selected != null)
                  Text(
                    'Tag: ${_selected!.tagName} (${_selected!.group})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(
                    hintText: 'Enter tag value',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  autofocus: true,
                  onSubmitted: (_) => _onAdd(),
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_selected != null || (_useCustom && _customController.text.trim().isNotEmpty))
                        ? _onAdd
                        : null,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
