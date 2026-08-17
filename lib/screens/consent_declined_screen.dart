import 'package:flutter/material.dart';

import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';

/// Figma node 14:1197 "비동의 안내 화면".
///
/// "비회원 일반 상담 진행" has no defined screen or API anywhere in
/// CLAUDE.md/TASK.md/API.md, so its button is intentionally inert here —
/// see the Issue #7 implementation report for follow-up.
class ConsentDeclinedScreen extends StatelessWidget {
  const ConsentDeclinedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StaffWebSessionController controller = StaffSessionScope.of(context);

    return StaffAppShell(
      currentRoute: AppRoutes.customerConsentDeclined,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: <Widget>[
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              Text('데이터 이용 동의 거부됨', style: StaffText.title20Bold),
              Text('고객이 상담 데이터 이용에 동의하지 않아 다음 기능을 사용할 수 없습니다', style: StaffText.body12),
            ],
          ),
          const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: <Widget>[
                Text('제한된 기능', style: StaffText.header16SemiBold),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: <Widget>[
                    _RestrictedFeatureLine(
                      title: '• 회원 장바구니 조회',
                      description: '고객 앱에서 저장한 제품 목록을 확인할 수 없습니다',
                    ),
                    _RestrictedFeatureLine(
                      title: '• 상담 결과 저장',
                      description: '이번 상담 결과를 고객 계정에 저장할 수 없습니다',
                    ),
                    _RestrictedFeatureLine(
                      title: '• 고객 모바일 재확인',
                      description: '상담 결과를 고객 앱에서 다시 확인하도록 안내할 수 없습니다',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: <Widget>[
                const Text('다음 단계', style: StaffText.header16SemiBold),
                const Text('고객과 함께 다음 중 하나를 선택하세요', style: StaffText.body12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    _NextStepOption(
                      title: '비회원 일반 상담 진행',
                      description:
                          '동의 없이 고객과 함께 상담을 진행합니다. 선택한 제품 정보와 고객 의도를 수동으로 '
                          '입력해 상담을 계속 진행할 수 있습니다',
                      actionLabel: '비회원 상담 시작',
                      variant: StaffButtonVariant.primary,
                      onPressed: () {},
                    ),
                    _NextStepOption(
                      title: '고객 조회 화면으로 돌아가기',
                      description: '현재 상담을 취소하고 다른 고객을 조회하거나 새로운 상담을 시작합니다',
                      actionLabel: '고객 조회로 돌아가기',
                      variant: StaffButtonVariant.secondary,
                      onPressed: () {
                        controller.reset();
                        Navigator.of(
                          context,
                        ).popUntil(ModalRoute.withName(AppRoutes.customerLookup));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictedFeatureLine extends StatelessWidget {
  const _RestrictedFeatureLine({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: <Widget>[
        Text(title, style: StaffText.body12),
        Text(description, style: StaffText.meta11),
      ],
    );
  }
}

class _NextStepOption extends StatelessWidget {
  const _NextStepOption({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.variant,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String actionLabel;
  final StaffButtonVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: <Widget>[
          Text(title, style: StaffText.header16SemiBold),
          Text(description, style: StaffText.meta11),
          StaffButton(label: actionLabel, variant: variant, onPressed: onPressed),
        ],
      ),
    );
  }
}
