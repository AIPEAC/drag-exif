/*
DragExif - EXIF metadata viewer
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
      return '#if you have scoop installed \n scoop install exiftool';
    }
    if (isLinux) {
      return 'sudo apt install libimage-exiftool-perl';
    }
    if (isMacOS) {
      return 'brew install exiftool';
    }
    return 'Unknown platform. Please install ExifTool for your platform.';
  }

  static String get downloadUrl => 'https://exiftool.org';

  static String get installInstructions {
    final buffer = StringBuffer();
    buffer.writeln('ExifTool is required but was not found on your system.');
    buffer.writeln();
    buffer.writeln('Platform: $platformName');
    buffer.writeln();
    buffer.writeln('To install ExifTool:');
    buffer.writeln(installCommand);
    buffer.writeln();
    buffer.writeln('Or download it from: $downloadUrl');
    if (isWindows) {
      buffer.writeln('After downloading, make sure to add ExifTool to your system PATH.');
    }
    return buffer.toString();
  }
}
