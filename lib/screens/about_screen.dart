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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_camera,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Constants.appName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const Text('EXIF metadata viewer'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Version: $_version', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Copyright © 2026 by Allen'),
              const Text('All rights reserved.'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _launchUrl('https://github.com/AIPEAC/drag-exif'),
                child: Text(
                  'https://github.com/AIPEAC/drag-exif',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Based on ${Constants.originalProjectName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Constants.originalProjectName} was originally written in C# by ${Constants.originalAuthor}. '
                      'This project is a Flutter/Dart rewrite derived from it.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _launchUrl(Constants.originalProjectUrl),
                      child: Text(
                        Constants.originalProjectUrl,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Constants.originalCopyright,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Licensed under ${Constants.originalLicense}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const ExpansionTile(
                title: Text('Credits', style: TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  ListTile(
                    title: Text('ExifTool'),
                    subtitle: Text('Distributed under the terms of the Artistic license.\nCopyright © Phil Harvey.'),
                    dense: true,
                  ),
                  ListTile(
                    title: Text('Flutter'),
                    subtitle: Text('Distributed under the terms of the BSD license.\nCopyright © Google LLC.'),
                    dense: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
