import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/app_design_tokens.dart';

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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(audience, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: child),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${AppConfig.appEnvironment} | ${AppConfig.apiBaseUrl}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
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
