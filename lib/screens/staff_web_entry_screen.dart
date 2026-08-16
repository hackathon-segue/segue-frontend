import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/app_design_tokens.dart';
import '../widgets/app_stage_shell.dart';
import '../widgets/route_card.dart';

class StaffWebEntryScreen extends StatelessWidget {
  const StaffWebEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStageShell(
      audience: '직원 웹',
      title: 'Last Intent 상담',
      child: GridView.count(
        crossAxisCount:
            MediaQuery.sizeOf(context).width >= AppSizes.staffGridBreakpoint
            ? 2
            : 1,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.35,
        children: const <Widget>[
          RouteCard(
            icon: Icons.person_search_outlined,
            title: '고객 조회',
            description: '직원 로그인, 홈, 고객 조회 화면이 이 route group에서 확장됩니다.',
            actionLabel: '직원 웹',
            routeName: AppRoutes.staffWeb,
          ),
          RouteCard(
            icon: Icons.phone_iphone_outlined,
            title: '고객 모바일',
            description: '고객 모바일 route group으로 이동해 화면 분리를 확인합니다.',
            actionLabel: '모바일 화면',
            routeName: AppRoutes.customerMobile,
          ),
        ],
      ),
    );
  }
}
