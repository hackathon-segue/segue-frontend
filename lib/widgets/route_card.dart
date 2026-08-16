import 'package:flutter/material.dart';

import '../utils/app_design_tokens.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.routeName,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: AppColors.ink, size: AppSizes.iconMedium),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pushNamed(routeName),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
