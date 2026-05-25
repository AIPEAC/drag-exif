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
import '../services/exif_tool_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/platform_helper.dart';
import '../widgets/command_preview.dart';
import '../widgets/editable_exif_data_table.dart';
import '../widgets/error_display.dart';
import '../widgets/export_menu.dart';
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

  List<ExifTagItem> _items = [];
  List<String> _filePaths = [];
  Map<String, List<MergedTagItem>> _mergedItems = {};
  Map<String, Map<String, String>> _pendingEdits = {};
  String _error = '';
  String _errorDetails = '';
  bool _isLoading = false;
  bool _dragging = false;
  bool _isMultiFile = false;

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
    await windowManager.setMinimumSize(const Size(500, 400));
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

  Future<void> _loadFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      setState(() {
        _items = [];
        _filePaths = [];
        _mergedItems = {};
        _pendingEdits = {};
        _isMultiFile = false;
        _error = '';
      });
      await windowManager.setTitle('${Constants.appName} v1.0.0');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _errorDetails = '';
    });

    _filePaths = [filePath];
    _pendingEdits = {};
    _isMultiFile = false;
    _exifTool.exifToolPath = _settings.exifToolExecutable;

    await windowManager.setTitle('${Constants.appName} v1.0.0 - $filePath');

    final exifToolResolved = await ExifToolService.checkExifToolExists(_settings.exifToolExecutable);
    if (exifToolResolved == null) {
      setState(() {
        _items = [];
        _error = PlatformHelper.installInstructions;
        _isLoading = false;
      });
      return;
    }

    try {
      final args = _settings.exifToolArguments.isNotEmpty
          ? _settings.exifToolArguments.split(' ')
          : <String>[];
      final items = await _exifTool.readAsync(filePath, extraArgs: args);
      setState(() {
        _items = items;
        _mergedItems = MergedTagItem.mergeFiles({_filePaths.first: items});
        _isLoading = false;
      });
    } catch (e, stack) {
      setState(() {
        _items = [];
        _mergedItems = {};
        _error = e.toString();
        if (_error.contains("doesn't exist") || _error.contains('No such file')) {
          _error = PlatformHelper.installInstructions;
        }
        _errorDetails = stack.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    if (paths.length == 1) {
      await _loadFile(paths.first);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _errorDetails = '';
    });

    _filePaths = List.from(paths);
    _pendingEdits = {};
    _isMultiFile = true;
    _exifTool.exifToolPath = _settings.exifToolExecutable;

    await windowManager.setTitle('${Constants.appName} v1.0.0 - ${paths.length} files');

    final exifToolResolved = await ExifToolService.checkExifToolExists(_settings.exifToolExecutable);
    if (exifToolResolved == null) {
      setState(() {
        _items = [];
        _mergedItems = {};
        _error = PlatformHelper.installInstructions;
        _isLoading = false;
      });
      return;
    }

    try {
      final args = _settings.exifToolArguments.isNotEmpty
          ? _settings.exifToolArguments.split(' ')
          : <String>[];

      // Load tags from all files
      final allTags = <String, List<ExifTagItem>>{}; // filePath -> tags
      for (final path in paths) {
        final tags = await _exifTool.readAsync(path, extraArgs: args);
        allTags[path] = tags;
      }

      setState(() {
        _mergedItems = _mergeMultiFileTags(allTags);
        _isLoading = false;
      });
    } catch (e, stack) {
      setState(() {
        _mergedItems = {};
        _error = e.toString();
        _errorDetails = stack.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, List<MergedTagItem>> _mergeMultiFileTags(
    Map<String, List<ExifTagItem>> allTags,
  ) {
    return MergedTagItem.mergeFiles(allTags);
  }

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
    if (_pendingEdits.isEmpty) return;

    // Show unsaved changes warning for multi-file
    if (_isMultiFile) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Save Changes'),
            ],
          ),
          content: Text(
            'You are about to write changes to ${_filePaths.length} files. '
            'This will modify the original image files.\n\n'
            'Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      for (final filePath in _filePaths) {
        final args = <String>[];
        for (final edit in _pendingEdits.values) {
          final tagName = edit['tagName']!;
          final value = edit['value']!;
          args.add('-$tagName=$value');
        }
        args.add(filePath);

        await Process.run(
          _exifTool.currentExifToolPath,
          args,
        );
      }

      setState(() {
        _pendingEdits = {};
        _isLoading = false;
      });

      // Reload to show updated values
      if (_isMultiFile) {
        await _loadFiles(_filePaths);
      } else {
        await _loadFile(_filePaths.firstOrNull);
      }

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
    setState(() {
      _pendingEdits = {};
      // Reset all pending values in merged items
      for (final group in _mergedItems.values) {
        for (final item in group) {
          item.pendingValue = null;
        }
      }
    });
  }

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'tiff', 'tif', 'raw', 'cr2', 'nef', 'arw', 'dng', 'heic', 'webp', 'gif', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup, const XTypeGroup(label: 'All files')]);
    if (file != null) {
      await _loadFile(file.path);
    }
  }

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

  Future<void> _copySelected() async {
    await Clipboard.setData(ClipboardData(text: _commandText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
      );
    }
  }

  String get _commandText {
    final args = _settings.exifToolArguments.isNotEmpty ? '${_settings.exifToolArguments} ' : '';
    final target = _filePaths.isEmpty
        ? ''
        : _isMultiFile
            ? '${_filePaths.length} files'
            : _filePaths.first;
    return '${_exifTool.currentExifToolPath} ${Constants.defaultCommands} $args"$target"';
  }

  Future<void> _showSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const SettingsScreen(),
    );
    if (result == true && _filePaths.isNotEmpty) {
      if (_isMultiFile) {
        await _loadFiles(_filePaths);
      } else {
        await _loadFile(_filePaths.firstOrNull);
      }
    }
  }

  Future<void> _showAbout() async {
    await showDialog(
      context: context,
      builder: (_) => const AboutScreen(),
    );
  }

  Future<bool> _onWillPop() async {
    if (_pendingEdits.isNotEmpty) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Unsaved Changes'),
            ],
          ),
          content: const Text(
            'You have unsaved changes. Do you want to save them before closing?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                _cancelChanges();
                Navigator.of(context).pop(true);
              },
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop(false);
                await _saveChanges();
                await windowManager.close();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _pendingEdits.isNotEmpty;
    final fileCount = _filePaths.length;

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
          color: _dragging ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
          child: Column(
            children: [
              // Changes warning banner
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
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saveChanges,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),

              // File info bar
              if (fileCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMultiFile ? Icons.folder_copy : Icons.image,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isMultiFile
                              ? '$fileCount files'
                              : _filePaths.first.split(Platform.pathSeparator).last,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isMultiFile)
                        Text(
                          '${_mergedItems.values.fold<int>(0, (sum, list) => sum + list.length)} tags',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

              // Main content area
              Expanded(
                child: _error.isNotEmpty
                    ? ErrorDisplay(error: _error, details: _errorDetails)
                    : _mergedItems.isEmpty && !_isLoading
                        ? const Center(child: Text('Drop image files or click "Open file…"'))
                        : _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : EditableExifDataTable(
                                groupedItems: _mergedItems,
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
                    CommandPreview(command: _filePaths.isNotEmpty ? _commandText : ''),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Open file…'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.folder_copy, size: 18),
                          label: const Text('Open files…'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _mergedItems.isEmpty ? null : _copySelected,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 8),
                        ExportMenu(
                          items: _items,
                          defaultFileName: _filePaths.isNotEmpty
                              ? '${_filePaths.first.split(Platform.pathSeparator).last.split('.').first}_exif'
                              : null,
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          tooltip: 'Menu',
                          onSelected: (value) async {
                            switch (value) {
                              case 'settings':
                                await _showSettings();
                              case 'about':
                                await _showAbout();
                              case 'exit':
                                final canClose = await _onWillPop();
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
