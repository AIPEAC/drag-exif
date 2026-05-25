import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Load settings
  final settings = SettingsService();
  await settings.init();

  // Window options
  final windowOptions = WindowOptions(
    size: Size(
      settings.windowWidth.toDouble(),
      settings.windowHeight.toDouble(),
    ),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: settings.enableWindowTopMost,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (settings.isMaximized) {
      await windowManager.maximize();
    } else {
      await windowManager.setPosition(
        Offset(
          settings.windowPositionX.toDouble(),
          settings.windowPositionY.toDouble(),
        ),
      );
    }
  });

  runApp(const ExifDTEApp());
}
