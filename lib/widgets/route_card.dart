import 'package:flutter/material.dart';

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
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: const Color(0xFF111827), size: 28),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
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
