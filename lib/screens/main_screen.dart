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
import '../widgets/error_display.dart';
import '../widgets/exif_data_table.dart';
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
  String _filePath = '';
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
        _filePath = '';
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

    _filePath = filePath;
    _exifTool.exifToolPath = _settings.exifToolExecutable;

    await windowManager.setTitle('${Constants.appName} v1.0.0 - $filePath');

    // Verify ExifTool exists before running
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
        _isLoading = false;
      });
    } catch (e, stack) {
      setState(() {
        _items = [];
        _error = e.toString();
        if (_error.contains("doesn't exist") || _error.contains('No such file')) {
          _error = PlatformHelper.installInstructions;
        }
        _errorDetails = stack.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _copySelected() async {
    // For now, copy the command preview as a placeholder
    // In a full implementation, we'd track which cell is selected
    await Clipboard.setData(ClipboardData(text: _commandText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
      );
    }
  }

  String get _commandText {
    final args = _settings.exifToolArguments.isNotEmpty ? '${_settings.exifToolArguments} ' : '';
    return '${_exifTool.currentExifToolPath} ${Constants.defaultCommands} $args"$_filePath"';
  }

  Future<void> _showSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const SettingsScreen(),
    );
    if (result == true && _filePath.isNotEmpty) {
      await _loadFile(_filePath);
    }
  }

  Future<void> _showAbout() async {
    await showDialog(
      context: context,
      builder: (_) => const AboutScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (detail) async {
          setState(() => _dragging = false);
          for (final file in detail.files) {
            final path = file.path;
            if (path.isNotEmpty) {
              final stat = FileStat.statSync(path);
              if (stat.type != FileSystemEntityType.directory) {
                await _loadFile(path);
                break;
              }
            }
          }
        },
        child: Container(
          color: _dragging ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
          child: Column(
            children: [
              // Main content area
              Expanded(
                child: _error.isNotEmpty
                    ? ErrorDisplay(error: _error, details: _errorDetails)
                    : _items.isEmpty && !_isLoading
                        ? const Center(child: Text('Drop an image file or click "Open file…"'))
                        : _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ExifDataTable(
                                items: _items,
                                showIndex: _settings.showColumnIndex,
                                showTagId: _settings.showColumnTagId,
                                showTagName: _settings.showColumnTagName,
                                showTagValue: _settings.showColumnTagValue,
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
                    CommandPreview(command: _filePath.isNotEmpty ? _commandText : ''),
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
                          onPressed: _items.isEmpty ? null : _copySelected,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: 8),
                        ExportMenu(
                          items: _items,
                          defaultFileName: _filePath.isNotEmpty
                              ? '${_filePath.split(Platform.pathSeparator).last.split('.').first}_exif'
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
                                await windowManager.close();
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
