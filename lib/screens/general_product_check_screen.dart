import 'package:flutter/material.dart';

import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';

/// Figma node 14:1155 "일반 제품 확인 안내".
///
/// Reached from [CartInventoryScreen]'s "제품 확인하기" button when a cart
/// item's selected SKU is currently held at this store (AC: "현재 매장 보유
/// 상품은 일반 제품 확인 화면으로 이동할 수 있다"). The Figma copy is fully
/// generic (no product name interpolated), so this screen is intentionally
/// static — no cart-item/customer context is required to render it.
class GeneralProductCheckScreen extends StatelessWidget {
  const GeneralProductCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffAppShell(
      currentRoute: AppRoutes.generalProductCheck,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 32,
        children: <Widget>[
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: <Widget>[
              Text('현재 매장 보유 제품', style: StaffText.title20Bold, textAlign: TextAlign.center),
              Text('직접 확인 가능합니다', style: StaffText.header16SemiBold, textAlign: TextAlign.center),
            ],
          ),
          const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 20,
              children: <Widget>[
                Text(
                  '이 제품은 현재 매장에 보유 중입니다',
                  style: StaffText.header16SemiBold,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Client Advisor가 고객과 함께 매장 내 제품을 직접 확인해 주세요.',
                  style: StaffText.body12,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '별도의 타 매장 확인 요청이나 입고 신청 없이 일반 상담 절차로 진행됩니다.',
                  style: StaffText.body12,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 12,
            children: <Widget>[
              Text('확인 기준 시점', style: StaffText.meta11, textAlign: TextAlign.center),
              Text(
                '재고 정보는 조회 시점 기준이며, 실제 매장 상황과 다를 수 있습니다. '
                'Client Advisor가 직접 확인 후 상담을 진행해 주세요.',
                style: StaffText.meta11,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          StaffButton(
            label: '상담 홈으로',
            variant: StaffButtonVariant.primary,
            onPressed: () {
              Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.staffHome));
            },
          ),
        ],
      ),
    );
  }
}
