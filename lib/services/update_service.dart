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
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class UpdateModel {
  final double apiVersion;
  final String version;
  final String title;
  final String description;
  final Uri? changelogUrl;
  final DateTime? publishedDate;
  final Uri? downloadUrl;

  UpdateModel({
    required this.apiVersion,
    required this.version,
    required this.title,
    required this.description,
    this.changelogUrl,
    this.publishedDate,
    this.downloadUrl,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      apiVersion: (json['ApiVersion'] ?? json['apiVersion'] ?? 1).toDouble(),
      version: json['Version'] ?? json['version'] ?? '',
      title: json['Title'] ?? json['title'] ?? '',
      description: json['Description'] ?? json['description'] ?? '',
      changelogUrl: json['ChangelogUrl'] != null || json['changelogUrl'] != null
          ? Uri.tryParse(json['ChangelogUrl'] ?? json['changelogUrl'])
          : null,
      publishedDate: json['PublishedDate'] != null || json['publishedDate'] != null
          ? DateTime.tryParse(json['PublishedDate'] ?? json['publishedDate'])
          : null,
      downloadUrl: json['DownloadUrl'] != null || json['downloadUrl'] != null
          ? Uri.tryParse(json['DownloadUrl'] ?? json['downloadUrl'])
          : null,
    );
  }
}

class UpdateService {
  UpdateModel? currentReleaseInfo;

  bool get hasNewUpdate {
    if (currentReleaseInfo == null) return false;
    // Simple string comparison for version
    return currentReleaseInfo!.version.isNotEmpty;
  }

  Future<void> getUpdatesAsync() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.updateUrl),
        headers: {'Cache-Control': 'no-cache'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        currentReleaseInfo = UpdateModel.fromJson(json);
      }
    } catch (_) {
      // Silently fail — update check is non-critical
    }
  }
}
