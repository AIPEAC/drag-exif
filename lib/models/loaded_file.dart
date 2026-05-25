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

import 'exif_tag_item.dart';

class LoadedFile {
  final String path;
  late final String fileName;
  List<ExifTagItem> tags;
  bool isLoaded;
  bool isLoading;
  bool hasError;
  String? errorMessage;

  LoadedFile({
    required this.path,
    this.tags = const [],
    this.isLoaded = false,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  }) {
    fileName = path.split(Platform.pathSeparator).last;
  }


}
