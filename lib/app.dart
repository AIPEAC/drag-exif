import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/settings_service.dart';

class ExifDTEApp extends StatefulWidget {
  const ExifDTEApp({super.key});

  @override
  State<ExifDTEApp> createState() => _ExifDTEAppState();
}

class _ExifDTEAppState extends State<ExifDTEApp> {
  final _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'ExifDTE',
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
