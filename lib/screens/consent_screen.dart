import 'package:flutter/material.dart';

import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_check_row.dart';

/// Figma node 14:964 "동의 안내 화면".
///
/// SCHEMA.md's `customer_consent` stores a single `status`/`scope` per
/// customer (no per-item flags), so the three "동의 범위" rows are
/// read-only and always shown checked.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StaffWebSessionController controller = StaffSessionScope.of(context);

    return StaffAppShell(
      currentRoute: AppRoutes.customerConsent,
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final bool isSubmitting = controller.state.consentState.isLoading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              const Text('상담 데이터 이용 동의', style: StaffText.title20Bold),
              const Text('고객 정보를 활용한 상담 서비스 제공을 위해 아래 내용을 고객에게 안내하고 동의 여부를 확인해 주세요.',
                  style: StaffText.body12),
              const SectionCard(
                child: _BulletSection(
                  title: '수집 및 이용 목적',
                  items: <String>[
                    '고객 앱 장바구니 제품·컬러 정보 조회 및 매장 재고 확인',
                    'AI 기반 구매 조건 분석 및 다음 행동 추천',
                    '상담 결과(추천 제품·경로, 핵심 조건, 결과 유형) 고객 계정 저장',
                    '저장된 상담 결과 고객 모바일 앱 재확인 제공',
                  ],
                ),
              ),
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: <Widget>[
                    Text('동의 범위', style: StaffText.header16SemiBold),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: <Widget>[
                        StaffCheckRow(
                          label: '회원 장바구니 조회 — 고객 앱에 담긴 제품·컬러 목록을 이번 상담에서 불러옵니다.',
                        ),
                        StaffCheckRow(label: '상담 결과 저장 — 상담 종료 후 결과를 고객 계정에 저장합니다.'),
                        StaffCheckRow(
                          label: '고객 모바일 재확인 — 저장된 결과를 고객 앱에서 다시 확인할 수 있도록 제공합니다.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionCard(
                child: _BulletSection(
                  title: '유의 사항',
                  items: <String>[
                    '동의하지 않으면 회원 정보 기반 조회 및 상담 결과 저장이 제공되지 않습니다.',
                    '동의 없이도 비회원 일반 상담은 진행할 수 있습니다.',
                    '수집된 정보는 이번 상담 목적에만 사용되며 제3자에게 제공되지 않습니다.',
                  ],
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  StaffButton(
                    label: '동의하지 않음',
                    variant: StaffButtonVariant.secondary,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            await controller.submitConsent(false);
                            if (context.mounted) {
                              Navigator.of(context).pushNamed(AppRoutes.customerConsentDeclined);
                            }
                          },
                  ),
                  StaffButton(
                    label: '동의하고 장바구니 확인',
                    variant: StaffButtonVariant.primary,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            await controller.submitConsent(true);
                            if (context.mounted) {
                              Navigator.of(context).pushNamed(AppRoutes.cartInventory);
                            }
                          },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: <Widget>[
        Text(title, style: StaffText.header16SemiBold),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            for (final String item in items)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: <Widget>[
                  const Text('·', style: StaffText.body12),
                  Expanded(child: Text(item, style: StaffText.body12)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
