import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../widgets/app_stage_shell.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.routeName, super.key});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return AppStageShell(
      audience: 'Route',
      title: '화면을 찾을 수 없습니다',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(routeName ?? 'unknown route'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.root);
              },
              child: const Text('처음으로'),
            ),
          ],
        ),
      ),
    );
  }
}
