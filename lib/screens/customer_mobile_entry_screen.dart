import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/app_design_tokens.dart';
import '../widgets/app_stage_shell.dart';
import '../widgets/route_card.dart';

class CustomerMobileEntryScreen extends StatelessWidget {
  const CustomerMobileEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStageShell(
      audience: '고객 모바일',
      title: 'MCM Last Intent',
      maxWidth: AppSizes.mobileContentMaxWidth,
      child: ListView(
        children: const <Widget>[
          RouteCard(
            icon: Icons.shopping_bag_outlined,
            title: '제품 탐색',
            description: '모바일 로그인, 홈, 제품 목록, 상세 화면이 이 route group에서 확장됩니다.',
            actionLabel: '모바일 화면',
            routeName: AppRoutes.customerMobile,
          ),
          SizedBox(height: AppSpacing.sm),
          RouteCard(
            icon: Icons.desktop_windows_outlined,
            title: '직원 웹 화면',
            description: '직원 웹 route group으로 이동해 화면 분리를 확인합니다.',
            actionLabel: '직원 웹',
            routeName: AppRoutes.staffWeb,
          ),
        ],
      ),
    );
  }
}
