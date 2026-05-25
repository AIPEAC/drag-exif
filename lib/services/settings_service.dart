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
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;
  late Directory _configDir;

  // Window state
  int windowPositionX = 200;
  int windowPositionY = 200;
  int windowWidth = 900;
  int windowHeight = 700;
  bool isMaximized = false;

  // App settings
  int themeMode = 0; // 0 = system, 1 = dark, 2 = light
  bool enableWindowTopMost = false;

  // ExifTool settings
  String exifToolExecutable = '';
  String exifToolArguments = '';

  // Column visibility
  bool showColumnIndex = true;
  bool showColumnTagId = true;
  bool showColumnTagName = true;
  bool showColumnTagValue = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _configDir = await _getConfigDir();
    await _loadFromJson();
    await _loadFromPrefs();
  }

  Future<void> save() async {
    await _saveToJson();
    await _saveToPrefs();
  }

  Future<Directory> _getConfigDir() async {
    final appDir = await getApplicationSupportDirectory();
    final configDir = Directory('${appDir.path}/dragexif');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return configDir;
  }

  Future<void> _loadFromJson() async {
    final configFile = File('${_configDir.path}/config.json');
    if (!await configFile.exists()) return;

    try {
      final json = jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;

      windowPositionX = json['windowPositionX'] ?? windowPositionX;
      windowPositionY = json['windowPositionY'] ?? windowPositionY;
      windowWidth = json['windowWidth'] ?? windowWidth;
      windowHeight = json['windowHeight'] ?? windowHeight;
      isMaximized = json['isMaximized'] ?? isMaximized;

      exifToolExecutable = json['exifToolExecutable'] ?? exifToolExecutable;
      exifToolArguments = json['exifToolArguments'] ?? exifToolArguments;
    } catch (_) {}
  }

  Future<void> _saveToJson() async {
    final configFile = File('${_configDir.path}/config.json');
    final json = {
      'windowPositionX': windowPositionX,
      'windowPositionY': windowPositionY,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'isMaximized': isMaximized,
      'exifToolExecutable': exifToolExecutable,
      'exifToolArguments': exifToolArguments,
    };
    await configFile.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  Future<void> _loadFromPrefs() async {
    themeMode = _prefs.getInt('themeMode') ?? themeMode;
    enableWindowTopMost = _prefs.getBool('enableWindowTopMost') ?? enableWindowTopMost;
    showColumnIndex = _prefs.getBool('showColumnIndex') ?? showColumnIndex;
    showColumnTagId = _prefs.getBool('showColumnTagId') ?? showColumnTagId;
    showColumnTagName = _prefs.getBool('showColumnTagName') ?? showColumnTagName;
    showColumnTagValue = _prefs.getBool('showColumnTagValue') ?? showColumnTagValue;
  }

  Future<void> _saveToPrefs() async {
    await _prefs.setInt('themeMode', themeMode);
    await _prefs.setBool('enableWindowTopMost', enableWindowTopMost);
    await _prefs.setBool('showColumnIndex', showColumnIndex);
    await _prefs.setBool('showColumnTagId', showColumnTagId);
    await _prefs.setBool('showColumnTagName', showColumnTagName);
    await _prefs.setBool('showColumnTagValue', showColumnTagValue);
  }
}
