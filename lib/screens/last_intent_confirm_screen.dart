import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';

/// Figma node 14:1500 "의도 요약 확인 화면" — all 5 of the wireframe's
/// sections, matching its structure: 고객 핵심 조건 요약 / 의도 정리 근거 / 추가
/// 상담이 필요한 조건 / 구매 상황 상세 / 장바구니 원제품.
///
/// Reached once [StructuredIntent] is ready — either straight from
/// [LastIntentUtteranceScreen] (no follow-up needed) or after
/// [LastIntentFollowUpScreen]'s answer is submitted. Reads the SAME
/// SKU-scoped session (`sessionFor`), so it always reflects exactly the
/// data this SKU's own flow produced.
///
/// The current mock adapter (MockSegueRepository.structureIntent, built in
/// Issue #7/#8, unchanged here) returns the SAME canned essentialConditions/
/// purchaseUrgency regardless of what the CA typed — there's no real AI
/// behind it yet, so every non-follow-up run looks identical. That's a mock
/// limitation, not a display bug; this screen renders whatever the session
/// actually holds. Two of the five sections (의도 정리 근거, 추가 상담이 필요한
/// 조건) have no dedicated backing field in StructuredIntent — they're
/// filled from what real signals ARE available (follow-up occurred or not,
/// preferred/negotiable condition maps) rather than the wireframe's
/// fabricated example copy. "맞아요, 다음 단계로" leads into 행동
/// 판정(decide)/실행, a later issue's scope, so it's left as a stub here.
class LastIntentConfirmScreen extends StatelessWidget {
  const LastIntentConfirmScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  static String _urgencyLabel(PurchaseUrgency urgency) {
    return switch (urgency) {
      PurchaseUrgency.today => '오늘 구매 희망',
      PurchaseUrgency.thisWeek => '이번 주 내 구매 희망',
      PurchaseUrgency.flexible => '구매 시급성 낮음',
    };
  }

  static String _yesNo(bool? value) {
    if (value == null) return '확인 필요';
    return value ? '예' : '아니오';
  }

  static String _conditionsList(Map<String, String> conditions) {
    if (conditions.isEmpty) {
      return '확인된 항목이 없습니다.';
    }
    return conditions.entries.map((MapEntry<String, String> e) => '${e.key}: ${e.value}').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: customer, cartItem: cartItem);

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          final StructuredIntent? intent = session.state.structuredIntent;
          if (intent == null) {
            return const Text('구조화된 고객 의도가 아직 없습니다.', style: StaffText.body12);
          }
          final bool hadFollowUp = session.state.followUpAnswer.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              const Text('의도 확인', style: StaffText.title20Bold),
              const Text('AI가 정리한 고객 구매 의도를 고객과 함께 확인하세요.', style: StaffText.body12),

              // 1. 고객 핵심 조건 요약
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    const Text('고객 핵심 조건 요약', style: StaffText.header16SemiBold),
                    if (intent.essentialConditions.isEmpty)
                      const Text('확인된 필수 조건이 없습니다.', style: StaffText.meta11)
                    else
                      for (final MapEntry<String, String> entry in intent.essentialConditions.entries)
                        Text('${entry.key}: ${entry.value}', style: StaffText.body12),
                    Text('구매 시급성: ${_urgencyLabel(intent.purchaseUrgency)}', style: StaffText.body12),
                    if (hadFollowUp)
                      Text('보충 답변: ${session.state.followUpAnswer}', style: StaffText.body12),
                  ],
                ),
              ),

              // 2. 의도 정리 근거 — StructuredIntent에 별도 근거 필드가 없어, 실제로
              // 있었던 분기(보충 질문 진행 여부)만 반영한 안내 문구로 대체.
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    const Text('의도 정리 근거', style: StaffText.header16SemiBold),
                    Text(
                      hadFollowUp
                          ? 'CA가 입력한 고객 발화와 보충 질문 답변을 함께 반영해 조건을 구조화했습니다.'
                          : 'CA가 입력한 고객 발화를 바탕으로 조건을 구조화했습니다.',
                      style: StaffText.meta11,
                    ),
                  ],
                ),
              ),

              // 3. 추가 상담이 필요한 조건 — 실제 preferred/negotiable 필드 사용
              // (현재 mock은 항상 빈 값이라 "확인된 항목이 없습니다"로 보일 수 있음).
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    const Text('추가 상담이 필요한 조건', style: StaffText.header16SemiBold),
                    Text('선호 조건: ${_conditionsList(intent.preferredConditions)}', style: StaffText.body12),
                    Text('협의 가능 조건: ${_conditionsList(intent.negotiableConditions)}', style: StaffText.body12),
                  ],
                ),
              ),

              // 4. 구매 상황 상세
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    const Text('구매 상황 상세', style: StaffText.header16SemiBold),
                    Text('대기 가능 여부: ${_yesNo(intent.canWait)}', style: StaffText.body12),
                    Text('타 매장 방문 가능 여부: ${_yesNo(intent.canVisitOtherStore)}', style: StaffText.body12),
                    Text('보충 질문 여부: ${hadFollowUp ? '1회 완료' : '없음'}', style: StaffText.body12),
                  ],
                ),
              ),

              // 5. 장바구니 원제품
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    const Text('장바구니 원제품', style: StaffText.header16SemiBold),
                    Text(
                      '${cartItem.productName} · 컬러: ${cartItem.color} · SKU: ${cartItem.skuId}',
                      style: StaffText.body12,
                    ),
                  ],
                ),
              ),

              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  StaffButton(
                    label: '수정할게요',
                    variant: StaffButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const StaffButton(
                    label: '맞아요, 다음 단계로',
                    variant: StaffButtonVariant.primary,
                    // 행동 판정(decide)/실행 단계는 별도 이슈 범위라 아직 연결하지 않는다.
                    onPressed: null,
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
