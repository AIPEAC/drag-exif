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
