import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import 'staff_button.dart';

/// Matches Figma's "SharedSidebar" component exactly: all five nav items
/// use the same underlined #6B7280 "default" Button style — Figma defines
/// no distinct active/inactive treatment for this component, so none is
/// added here. Only "상담 홈" and "고객 조회" are wired to real routes;
/// the rest (상담 이력/고객 결과/설정) have no screen yet (TASK.md P1),
/// so they render identically but do nothing on tap.
class StaffSidebar extends StatelessWidget {
  const StaffSidebar({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: StaffSizes.sidebarWidth,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: StaffColors.sidebarBg,
        border: Border(right: BorderSide(color: StaffColors.chromeBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: <Widget>[
          const Text('상담 메뉴', style: StaffText.body12),
          StaffButton(
            label: '상담 홈',
            variant: StaffButtonVariant.link,
            onPressed: () => _go(context, AppRoutes.staffHome),
          ),
          StaffButton(
            label: '고객 조회',
            variant: StaffButtonVariant.link,
            onPressed: () => _go(context, AppRoutes.customerLookup),
          ),
          const StaffButton(label: '상담 이력', variant: StaffButtonVariant.link),
          const StaffButton(label: '고객 결과', variant: StaffButtonVariant.link),
          const StaffButton(label: '설정', variant: StaffButtonVariant.link),
        ],
      ),
    );
  }

  void _go(BuildContext context, String routeName) {
    if (routeName == currentRoute) {
      return;
    }
    Navigator.of(context).pushNamed(routeName);
  }
}
