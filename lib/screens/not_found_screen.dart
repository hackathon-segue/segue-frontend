import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/app_design_tokens.dart';
import '../widgets/app_stage_shell.dart';
import '../widgets/app_state_view.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.routeName, super.key});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return AppStageShell(
      audience: 'Route',
      title: '화면을 찾을 수 없습니다',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.mobileContentMaxWidth,
          ),
          child: AppStateView.error(
            title: '화면을 찾을 수 없습니다',
            message: routeName ?? 'unknown route',
            actionLabel: '처음으로',
            onAction: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.root);
            },
          ),
        ),
      ),
    );
  }
}
