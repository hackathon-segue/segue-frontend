import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import 'last_intent_utterance_screen.dart';

/// Figma node 14:1256 "Last Intent 상담 시작".
///
/// Reached from [CartInventoryScreen]'s "Last Intent 시작" button for a
/// specific out-of-stock cart item. Issue #9's actual requirement is
/// per-SKU session isolation (see [LastIntentSessionManager]) — this screen
/// is the confirmation step that starts (or resumes) that SKU's session via
/// `sessionFor`, without disturbing any other SKU's in-progress session.
///
/// The Figma frame's own "상담 대상 제품" product list is dropped here — it's
/// the same list [CartInventoryScreen] (the screen the CA just came from)
/// already shows, so repeating it immediately below is pure duplication.
///
/// Per Issue #9's explicit instructions, the wireframe is not final design:
/// structure/copy only, no pixel-level tuning, styles reused from the
/// existing staff theme/components.
class LastIntentIntroScreen extends StatelessWidget {
  const LastIntentIntroScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);
    // Starts (or resumes) this SKU's own session — a different SKU's
    // session, if one exists, is untouched.
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem,
    );

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              const Text('Last Intent 상담 시작', style: StaffText.title20Bold),
              const Text(
                '고객이 앱에서 선택한 제품을 바탕으로 상담을 진행합니다. 아래 안내를 확인한 후 다음 단계로 이동하세요.',
                style: StaffText.body12,
              ),
              const Text('상담 안내', style: StaffText.header16SemiBold),
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    Text('고객 핵심 조건 확인', style: StaffText.body12),
                    Text(
                      "다음 단계에서 고객에게 '이 제품에서 절대 놓치고 싶지 않은 점은 무엇인가요?'라고 질문하고, "
                      '고객이 말한 내용을 텍스트로 입력합니다. AI가 구조화된 구매 조건으로 변환합니다.',
                      style: StaffText.meta11,
                    ),
                  ],
                ),
              ),
              const SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    Text('결과 유형 안내', style: StaffText.body12),
                    Text(
                      '입력된 고객 의도와 재고 정보를 바탕으로 정확한 제품 확인, 비교 체험 제품, 오늘 구매 가능한 제품, '
                      '추가 상담 중 하나의 결과를 제공합니다.',
                      style: StaffText.meta11,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: StaffButton(
                  label: '고객 의도 입력 시작',
                  variant: StaffButtonVariant.primary,
                  // Issue #10: hands off to LastIntentUtteranceScreen, which
                  // reuses this SAME SKU-scoped session (sessionFor already
                  // started it above) — no separate consultation-target
                  // state is created.
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            LastIntentUtteranceScreen(customer: customer, cartItem: cartItem),
                        settings: const RouteSettings(name: AppRoutes.lastIntentIntro),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
