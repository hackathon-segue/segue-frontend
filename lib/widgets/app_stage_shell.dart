import 'package:flutter/material.dart';

import '../utils/app_config.dart';

class AppStageShell extends StatelessWidget {
  const AppStageShell({
    required this.audience,
    required this.title,
    required this.child,
    this.maxWidth = 960,
    super.key,
  });

  final String audience;
  final String title;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    audience,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: child),
                  const SizedBox(height: 16),
                  Text(
                    '${AppConfig.appEnvironment} | ${AppConfig.apiBaseUrl}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
