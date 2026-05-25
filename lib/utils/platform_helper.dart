import 'dart:io';

class PlatformHelper {
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isMacOS => Platform.isMacOS;

  static String get platformName {
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isMacOS) return 'macOS';
    return 'Unknown';
  }

  static String get installCommand {
    if (isWindows) {
      return 'Download ExifTool from https://exiftool.org and place exiftool.exe in the app folder, or add it to your PATH.';
    }
    if (isLinux) {
      return 'sudo apt install libimage-exiftool-perl';
    }
    if (isMacOS) {
      return 'brew install exiftool';
    }
    return 'Please install ExifTool for your platform.';
  }

  static String get downloadUrl => 'https://exiftool.org';

  static String get installInstructions {
    final buffer = StringBuffer();
    buffer.writeln('ExifTool is required but was not found on your system.');
    buffer.writeln();
    buffer.writeln('Platform: $platformName');
    buffer.writeln();
    buffer.writeln('To install ExifTool, run:');
    buffer.writeln(installCommand);
    buffer.writeln();
    buffer.writeln('Or download it from: $downloadUrl');
    return buffer.toString();
  }
}
