import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String error;
  final String? details;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          '❌ Error:\n$error${details != null ? '\n\nℹ️ Details:\n$details' : ''}',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
