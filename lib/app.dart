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
import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/settings_service.dart';

class DragExifApp extends StatefulWidget {
  const DragExifApp({super.key});

  @override
  State<DragExifApp> createState() => _DragExifAppState();
}

class _DragExifAppState extends State<DragExifApp> {
  final _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'DragExif',
          debugShowCheckedModeBanner: false,
          themeMode: _themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const MainScreen(),
        );
      },
    );
  }

  ThemeMode get _themeMode {
    switch (_settings.themeMode) {
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
}

// Simple notifier to trigger rebuilds when settings change
final _settingsNotifier = _SettingsNotifier();

class _SettingsNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
