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
