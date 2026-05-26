/*
DragExif - EXIF metadata viewer
Based on ExifGlass by Dương Diệu Pháp
Copyright (C) 2023-2025 DUONG DIEU PHAP
Project homepage: https://github.com/d2phap/ExifGlass
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

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../models/exif_tag_item.dart';
import '../models/loaded_file.dart';
import '../services/exif_tool_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/platform_helper.dart';
import '../widgets/editable_exif_data_table.dart';
import '../widgets/error_display.dart';
import '../widgets/export_menu.dart';
import '../widgets/file_list_panel.dart';
import '../widgets/add_tag_dialog.dart';
import '../widgets/unsaved_changes_dialog.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WindowListener {
  final _exifTool = ExifToolService();
  final _settings = SettingsService();

  // All loaded files
  final List<LoadedFile> _allFiles = [];

  // Selection state
  final Set<int> _selectedIndices = {};
  int? _lastClickedIndex;

  // Merged EXIF view for selected files
  Map<String, List<MergedTagItem>> _mergedItems = {};

  // Newly added tags that don't exist in any selected file yet
  final Map<String, List<MergedTagItem>> _newTags = {};

  // Pending edits: key = "tagGroup|tagId|tagName" -> {tagId, tagName, tagGroup, value}
  final Map<String, Map<String, String>> _pendingEdits = {};

  String _error = '';
  String _errorDetails = '';
  bool _isLoading = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
    _checkExifToolOnStartup();
  }

  Future<void> _checkExifToolOnStartup() async {
    final found = await ExifToolService.checkExifToolExists(_settings.exifToolExecutable);
    if (found == null && mounted) {
      setState(() {
        _error = PlatformHelper.installInstructions;
      });
    }
  }

  Future<void> _initWindow() async {
    await windowManager.setTitle('${Constants.appName} v1.0.0');
    await windowManager.setMinimumSize(const Size(700, 500));
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _exifTool.dispose();
    super.dispose();
  }

  @override
  void onWindowResize() => _saveWindowState();

  @override
  void onWindowMove() => _saveWindowState();

  @override
  void onWindowClose() async {
    final canClose = await _handleUnsavedChangesBeforeAction();
    if (canClose) {
      await windowManager.destroy();
    }
  }

  Future<void> _saveWindowState() async {
    final bounds = await windowManager.getBounds();
    final isMaximized = await windowManager.isMaximized();
    _settings.windowPositionX = bounds.left.toInt();
    _settings.windowPositionY = bounds.top.toInt();
    _settings.windowWidth = bounds.width.toInt();
    _settings.windowHeight = bounds.height.toInt();
    _settings.isMaximized = isMaximized;
    await _settings.save();
  }

  // ──────────────────────────────────────────────────────────
  // Selection
  // ──────────────────────────────────────────────────────────

  Future<void> _onSelectFile(int index, {bool ctrl = false, bool shift = false}) async {
    if (_pendingEdits.isNotEmpty) {
      final action = await UnsavedChangesDialog.show(
        context,
        changeCount: _pendingEdits.length,
      );
      switch (action) {
        case UnsavedAction.cancel:
          return;
        case UnsavedAction.discard:
          _discardEditsInternal();
          break;
        case UnsavedAction.save:
          await _saveChangesInternal();
          if (_pendingEdits.isNotEmpty) return; // save failed
          break;
      }
    }

    setState(() {
      if (shift && _lastClickedIndex != null) {
        final start = _lastClickedIndex!;
        final end = index;
        final range = <int>{};
        final min = start < end ? start : end;
        final max = start < end ? end : start;
        for (var i = min; i <= max; i++) {
          range.add(i);
        }
        _selectedIndices.addAll(range);
      } else if (ctrl) {
        if (_selectedIndices.contains(index)) {
          _selectedIndices.remove(index);
        } else {
          _selectedIndices.add(index);
        }
      } else {
        _selectedIndices.clear();
        _selectedIndices.add(index);
      }
      _lastClickedIndex = index;
    });

    _rebuildMergedView();
  }

  void _rebuildMergedView() {
    if (_selectedIndices.isEmpty) {
      setState(() => _mergedItems = {});
      return;
    }

    final selectedTags = <String, List<ExifTagItem>>{};
    for (final idx in _selectedIndices) {
      final file = _allFiles[idx];
      if (file.isLoaded && !file.hasError) {
        selectedTags[file.path] = file.tags;
      }
    }

    setState(() {
      _mergedItems = selectedTags.isEmpty ? {} : MergedTagItem.mergeFiles(selectedTags);
    });
  }

  // ──────────────────────────────────────────────────────────
  // File loading
  // ──────────────────────────────────────────────────────────

  Future<void> _loadFiles(List<String> paths) async {
    if (paths.isEmpty) return;

    // Check unsaved changes
    if (_pendingEdits.isNotEmpty) {
      final action = await UnsavedChangesDialog.show(
        context,
        changeCount: _pendingEdits.length,
      );
      switch (action) {
        case UnsavedAction.cancel:
          return;
        case UnsavedAction.discard:
          _discardEditsInternal();
          break;
        case UnsavedAction.save:
          await _saveChangesInternal();
          if (_pendingEdits.isNotEmpty) return;
          break;
      }
    }

    setState(() {
      _allFiles.clear();
      _selectedIndices.clear();
      _lastClickedIndex = null;
      _mergedItems = {};
      _pendingEdits.clear();
      _error = '';
      _errorDetails = '';
    });

    // Add files to list
    for (final path in paths) {
      _allFiles.add(LoadedFile(path: path));
    }

    // Select first file by default
    if (_allFiles.isNotEmpty) {
      _selectedIndices.add(0);
      _lastClickedIndex = 0;
    }

    await windowManager.setTitle('${Constants.appName} v1.0.0 - ${_allFiles.length} files');

    // Verify ExifTool
    final exifToolResolved = await ExifToolService.checkExifToolExists(_settings.exifToolExecutable);
    if (exifToolResolved == null) {
      setState(() {
        _error = PlatformHelper.installInstructions;
        for (final f in _allFiles) {
          f.hasError = true;
          f.errorMessage = 'ExifTool not found';
        }
      });
      return;
    }

    _exifTool.exifToolPath = _settings.exifToolExecutable;

    // Load EXIF for all files in parallel
    final args = _settings.exifToolArguments.isNotEmpty
        ? _settings.exifToolArguments.split(' ')
        : <String>[];

    await Future.wait(
      List.generate(_allFiles.length, (i) => _loadExifForIndex(i, args)),
    );

    _rebuildMergedView();
  }

  Future<void> _loadExifForIndex(int index, List<String> args) async {
    final file = _allFiles[index];
    setState(() => file.isLoading = true);

    try {
      final tags = await _exifTool.readAsync(file.path, extraArgs: args);
      setState(() {
        file.tags = tags;
        file.isLoaded = true;
        file.isLoading = false;
        file.hasError = false;
        file.errorMessage = null;
      });
    } catch (e) {
      setState(() {
        file.hasError = true;
        file.errorMessage = e.toString();
        file.isLoading = false;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _allFiles.removeAt(index);

      // Rebuild selected indices
      final newSelected = <int>{};
      for (final idx in _selectedIndices) {
        if (idx < index) {
          newSelected.add(idx);
        } else if (idx > index) {
          newSelected.add(idx - 1);
        }
        // idx == index is removed
      }
      _selectedIndices
        ..clear()
        ..addAll(newSelected);

      if (_lastClickedIndex == index) {
        _lastClickedIndex = null;
      } else if (_lastClickedIndex != null && _lastClickedIndex! > index) {
        _lastClickedIndex = _lastClickedIndex! - 1;
      }

      if (_allFiles.isNotEmpty && _selectedIndices.isEmpty) {
        _selectedIndices.add(0);
        _lastClickedIndex = 0;
      }
    });
    _rebuildMergedView();
  }

  Future<void> _renameFile(int index, String newName) async {
    final file = _allFiles[index];
    final oldPath = file.path;
    final lastSep = oldPath.lastIndexOf(Platform.pathSeparator);
    final dir = lastSep >= 0 ? oldPath.substring(0, lastSep) : '';
    final newPath = dir.isNotEmpty
        ? '$dir${Platform.pathSeparator}$newName'
        : newName;

    if (newPath == oldPath) return;

    try {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        try {
          await oldFile.rename(newPath);
        } catch (_) {
          // Cross-device rename fallback
          await oldFile.copy(newPath);
          await oldFile.delete();
        }
      }

      setState(() {
        file.path = newPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File renamed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error renaming file: $e')),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // Editing
  // ──────────────────────────────────────────────────────────

  void _onEdit(MergedTagItem item) {
    setState(() {
      final key = '${item.tagGroup}|${item.tagId}|${item.tagName}';
      _pendingEdits[key] = {
        'tagId': item.tagId,
        'tagName': item.tagName,
        'tagGroup': item.tagGroup,
        'value': item.pendingValue!,
      };
    });
  }

  Future<void> _saveChanges() async {
    await _saveChangesInternal();
  }

  Future<void> _saveChangesInternal() async {
    if (_pendingEdits.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final tagChanges = <String, String>{};
      for (final edit in _pendingEdits.values) {
        tagChanges[edit['tagName']!] = edit['value']!;
      }

      // Determine which files to save to
      final targetFiles = <String>[];
      for (final idx in _selectedIndices) {
        final file = _allFiles[idx];
        if (file.isLoaded && !file.hasError) {
          targetFiles.add(file.path);
        }
      }

      for (final filePath in targetFiles) {
        final tempPath = await _exifTool.writeTagsAsync(
          filePath,
          tagChanges,
        );
        // Move temp file over original
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          try {
            await tempFile.rename(filePath);
          } catch (_) {
            // Cross-device rename fallback
            await tempFile.copy(filePath);
            await tempFile.delete();
          }
        }
      }

      setState(() {
        _pendingEdits.clear();
        _newTags.clear();
        _isLoading = false;
      });

      // Reload EXIF for affected files
      final args = _settings.exifToolArguments.isNotEmpty
          ? _settings.exifToolArguments.split(' ')
          : <String>[];
      await Future.wait(
        _selectedIndices.map((idx) => _loadExifForIndex(idx, args)),
      );
      _rebuildMergedView();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  void _cancelChanges() {
    _discardEditsInternal();
  }

  void _discardEditsInternal() {
    setState(() {
      _pendingEdits.clear();
      _newTags.clear();
      for (final group in _mergedItems.values) {
        for (final item in group) {
          item.pendingValue = null;
        }
      }
    });
  }

  // ──────────────────────────────────────────────────────────
  // Unsaved changes guard
  // ──────────────────────────────────────────────────────────

  Future<bool> _handleUnsavedChangesBeforeAction() async {
    if (_pendingEdits.isEmpty) return true;

    final action = await UnsavedChangesDialog.show(
      context,
      changeCount: _pendingEdits.length,
    );
    switch (action) {
      case UnsavedAction.cancel:
        return false;
      case UnsavedAction.discard:
        _discardEditsInternal();
        return true;
      case UnsavedAction.save:
        await _saveChangesInternal();
        return _pendingEdits.isEmpty;
    }
  }

  // ──────────────────────────────────────────────────────────
  // File pickers
  // ──────────────────────────────────────────────────────────

  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'tiff', 'tif', 'raw', 'cr2', 'nef', 'arw', 'dng', 'heic', 'webp', 'gif', 'bmp'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup, const XTypeGroup(label: 'All files')]);
    if (files.isNotEmpty) {
      await _loadFiles(files.map((f) => f.path).toList());
    }
  }

  // ──────────────────────────────────────────────────────────
  // Clipboard / Export
  // ──────────────────────────────────────────────────────────

  Map<String, List<MergedTagItem>> get _displayItems {
    final result = <String, List<MergedTagItem>>{};
    for (final entry in _mergedItems.entries) {
      result[entry.key] = List.from(entry.value);
    }
    for (final entry in _newTags.entries) {
      result.putIfAbsent(entry.key, () => []).addAll(entry.value);
    }
    return result;
  }

  Future<void> _showAddTagDialog() async {
    if (_selectedIndices.isEmpty) return;

    final result = await AddTagDialog.show(context);
    if (result == null) return;

    final key = '${result.group}||${result.tagName}';
    setState(() {
      _pendingEdits[key] = {
        'tagId': '',
        'tagName': result.tagName,
        'tagGroup': result.group,
        'value': result.value,
      };

      final newItem = MergedTagItem(
        tagId: '',
        tagGroup: result.group,
        tagName: result.tagName,
        fileValues: {},
        displayValue: '<new>',
        isUnequal: false,
        pendingValue: result.value,
      );
      _newTags.putIfAbsent(result.group, () => []).add(newItem);
    });
  }

  Future<void> _copySelected() async {
    final buffer = StringBuffer();
    final display = _displayItems;
    for (final groupEntry in display.entries) {
      buffer.writeln('[${groupEntry.key}]');
      for (final item in groupEntry.value) {
        buffer.writeln('  ${item.tagName}: ${item.currentValue}');
      }
      buffer.writeln();
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
      );
    }
  }

  List<ExifTagItem> get _exportItems {
    // Flatten display items into ExifTagItem list for export
    final result = <ExifTagItem>[];
    var index = 0;
    for (final group in _displayItems.values) {
      for (final item in group) {
        result.add(ExifTagItem(
          index: ++index,
          tagId: item.tagId,
          tagGroup: item.tagGroup,
          tagName: item.tagName,
          tagValue: item.currentValue,
        ));
      }
    }
    return result;
  }

  // ──────────────────────────────────────────────────────────
  // Settings / About
  // ──────────────────────────────────────────────────────────

  Future<void> _showSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const SettingsScreen(),
    );
    if (result == true && _allFiles.isNotEmpty) {
      final args = _settings.exifToolArguments.isNotEmpty
          ? _settings.exifToolArguments.split(' ')
          : <String>[];
      await Future.wait(
        List.generate(_allFiles.length, (i) => _loadExifForIndex(i, args)),
      );
      _rebuildMergedView();
    }
  }

  Future<void> _showAbout() async {
    await showDialog(
      context: context,
      builder: (_) => const AboutScreen(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasChanges = _pendingEdits.isNotEmpty;
    final selectedCount = _selectedIndices.length;

    return Scaffold(
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (detail) async {
          setState(() => _dragging = false);
          final files = <String>[];
          for (final file in detail.files) {
            final path = file.path;
            if (path.isNotEmpty) {
              final stat = FileStat.statSync(path);
              if (stat.type != FileSystemEntityType.directory) {
                files.add(path);
              }
            }
          }
          if (files.isNotEmpty) {
            await _loadFiles(files);
          }
        },
        child: Container(
          color: _dragging
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          child: Row(
            children: [
              // ── Left: File list panel ──
              SizedBox(
                width: 260,
                child: FileListPanel(
                  files: _allFiles,
                  selectedIndices: _selectedIndices,
                  lastClickedIndex: _lastClickedIndex,
                  onSelect: _onSelectFile,
                  onRemove: _removeFile,
                  onRename: _renameFile,
                ),
              ),

              const VerticalDivider(width: 1),

              // ── Right: Main content ──
              Expanded(
                child: Column(
                  children: [
                    // Unsaved changes banner
                    if (hasChanges)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Unsaved changes (${_pendingEdits.length} ${_pendingEdits.length == 1 ? 'field' : 'fields'})',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _cancelChanges,
                              child: const Text('Discard'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _saveChanges,
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ),

                    // Main content area
                    Expanded(
                      child: _error.isNotEmpty && _allFiles.isEmpty
                          ? ErrorDisplay(error: _error, details: _errorDetails)
                          : _allFiles.isEmpty && !_isLoading
                              ? const Center(child: Text('Drop image files or click "Open files…"'))
                              : _isLoading && _mergedItems.isEmpty
                                  ? const Center(child: CircularProgressIndicator())
                                  : selectedCount == 0
                                      ? const Center(child: Text('Select a file to view EXIF data'))
                                      : _displayItems.isEmpty
                                          ? const Center(child: Text('No EXIF data for selected files'))
                                          : EditableExifDataTable(
                                              groupedItems: _displayItems,
                                              showIndex: _settings.showColumnIndex,
                                              showTagId: _settings.showColumnTagId,
                                              showTagName: _settings.showColumnTagName,
                                              showTagValue: _settings.showColumnTagValue,
                                              onEdit: _onEdit,
                                            ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          top: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: _pickFiles,
                                  icon: const Icon(Icons.folder_open, size: 18),
                                  label: const Text('Open files…'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _displayItems.isEmpty ? null : _copySelected,
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _selectedIndices.isEmpty ? null : _showAddTagDialog,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add tag'),
                                ),
                                const SizedBox(width: 8),
                                ExportMenu(
                                  items: _exportItems,
                                  defaultFileName: selectedCount > 0
                                      ? '${_allFiles[_selectedIndices.first].fileName.split('.').first}_exif'
                                      : null,
                                ),
                                const SizedBox(width: 24),
                                PopupMenuButton<String>(
                                  tooltip: 'Menu',
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'settings':
                                        await _showSettings();
                                      case 'about':
                                        await _showAbout();
                                      case 'exit':
                                        final canClose = await _handleUnsavedChangesBeforeAction();
                                        if (canClose) await windowManager.close();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'settings', child: Text('Settings…')),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(value: 'about', child: Text('About…')),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(value: 'exit', child: Text('Exit')),
                                  ],
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Menu'),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_drop_down, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
