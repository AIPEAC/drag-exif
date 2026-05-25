import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  late final _executableController = TextEditingController();
  late final _argumentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _executableController.text = _settings.exifToolExecutable;
    _argumentsController.text = _settings.exifToolArguments;
    _executableController.addListener(_updatePreview);
    _argumentsController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _executableController.dispose();
    _argumentsController.dispose();
    super.dispose();
  }

  String get _previewCommand {
    final path = _executableController.text.trim().isEmpty
        ? 'exiftool'
        : _executableController.text.trim();
    final args = _argumentsController.text.trim();
    return '$path ${Constants.defaultCommands} ${args.isNotEmpty ? '$args ' : ''}"C:\\path\\to\\photo.jpg"';
  }

  void _updatePreview() => setState(() {});

  Future<void> _pickExecutable() async {
    const typeGroup = XTypeGroup(
      label: 'ExifTool binary',
      extensions: ['exe'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        _executableController.text = file.path;
      });
    }
  }

  void _save() {
    _settings.themeMode = _selectedThemeIndex;
    _settings.enableWindowTopMost = _topMost;
    _settings.exifToolExecutable = _executableController.text.trim();
    _settings.exifToolArguments = _argumentsController.text.trim();
    _settings.save();
    Navigator.of(context).pop(true);
  }

  int get _selectedThemeIndex => _settings.themeMode;
  set _selectedThemeIndex(int value) => setState(() => _settings.themeMode = value);

  bool get _topMost => _settings.enableWindowTopMost;
  set _topMost(bool value) => setState(() => _settings.enableWindowTopMost = value);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Theme',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedThemeIndex,
                // ignore: deprecated_member_use
                items: const [
                  DropdownMenuItem(value: 0, child: Text('System setting')),
                  DropdownMenuItem(value: 1, child: Text('Dark')),
                  DropdownMenuItem(value: 2, child: Text('Light')),
                ],
                onChanged: (v) => _selectedThemeIndex = v ?? 0,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Keep window always on top'),
                value: _topMost,
                onChanged: (v) => _topMost = v ?? false,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              const Text(
                'ExifTool Configurations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text('Executable Path'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _executableController,
                      decoration: const InputDecoration(
                        hintText: '(default)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickExecutable,
                    child: const Text('Select…'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Arguments'),
              const SizedBox(height: 4),
              TextField(
                controller: _argumentsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Preview'),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 80),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _previewCommand,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
