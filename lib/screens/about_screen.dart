import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
        width: 400,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DragExif',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Text('EXIF metadata viewer'),
                  ],
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
            const ExpansionTile(
              title: Text('Credits', style: TextStyle(fontWeight: FontWeight.w600)),
              children: [
                ListTile(
                  title: Text('ExifGlass'),
                  subtitle: Text('Original software was written in C#. This project is written based on ExifGlass.\n Distributed under the terms of the GPLv3 license.\nCopyright © 2023-2025, Dương Diệu Pháp.'),
                  dense: true,
                ),
              ],
            ),
          ],
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
