import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../utils/structured_intent_vocabulary.dart';
import '../widgets/app_state_view.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import 'last_intent_card_screen.dart';
import 'last_intent_edit_screen.dart';

/// Issue #12 "구조화된 고객 의도 확인/수정 화면" — Figma node 14:1500 "의도 요약 확인
/// 화면". Design intentionally kept plain per this issue's own instruction
/// ("디자인은 조금 투박해도 되고, 기능 구현에만 집중") — reuses existing shared
/// components rather than chasing pixel-exact Figma values.
///
/// Reached once [StructuredIntent] is ready — either straight from
/// [LastIntentUtteranceScreen] (no follow-up needed) or after
/// [LastIntentFollowUpScreen]'s answer is submitted, or after returning from
/// [LastIntentEditScreen] with saved edits. Reads the SAME SKU-scoped
/// session (`sessionFor`), so it always reflects exactly the data this
/// SKU's own flow (and any edits) produced — never another SKU's session.
class LastIntentConfirmScreen extends StatefulWidget {
  const LastIntentConfirmScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentConfirmScreen> createState() => _LastIntentConfirmScreenState();
}

class _LastIntentConfirmScreenState extends State<LastIntentConfirmScreen> {
  bool _deciding = false;

  // MockSegueRepository resolves near-instantly, so without an artificial
  // floor the AI-judgment loading state flashes by too fast to actually
  // see — same rationale as the utterance/follow-up/edit screens.
  static const Duration _minDecidingDuration = Duration(milliseconds: 600);

  Future<void> _confirmAndDecide(LastIntentSessionController session) async {
    if (_deciding) {
      return; // AC: 중복 요청 방지 — 버튼 재클릭 방지.
    }
    setState(() => _deciding = true);
    final Stopwatch stopwatch = Stopwatch()..start();
    // AC: "맞아요"를 누르면 현재(=수정했다면 수정된) StructuredIntent가 그대로
    // decide() 요청에 실린다 — session.state.structuredIntent가 유일한 source of
    // truth이고 LastIntentEditScreen의 저장도 바로 이 값을 갱신하기 때문.
    await session.decide();
    final Duration remaining = _minDecidingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    setState(() => _deciding = false);
    if (session.state.decisionResult != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              LastIntentCardScreen(customer: widget.customer, cartItem: widget.cartItem),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: widget.customer, cartItem: widget.cartItem);

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          if (_deciding || session.state.decisionState.isLoading) {
            // No dedicated Figma loading frame for this step — reuses the
            // shared loading treatment, with copy specific to what's
            // actually happening (Issue #13: "다음 행동 판단 loading 상태").
            return const AppStateView.loading(title: 'AI가 다음 행동을 판단하고 있습니다');
          }

          if (session.state.decisionState.hasError) {
            return AppStateView.error(
              message: 'Last Intent Card 생성에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _confirmAndDecide(session),
            );
          }

          final StructuredIntent? intent = session.state.structuredIntent;
          if (intent == null) {
            return const Text('구조화된 고객 의도가 아직 없습니다.', style: StaffText.body12);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              const Text('의도 요약 확인', style: StaffText.header16SemiBold),
              const Text('AI가 정리한 고객 구매 의도를 고객과 함께 확인하세요.', style: StaffText.body12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: <Widget>[
                    _InfoRow(label: '사용 목적', value: intent.purpose.isEmpty ? '확인 필요' : intent.purpose),
                    _InfoRow(label: '필수 조건', value: _conditionsList(intent.essentialConditions)),
                    _InfoRow(label: '선호 조건', value: _conditionsList(intent.preferredConditions)),
                    _InfoRow(label: '양보 가능한 조건', value: _conditionsList(intent.negotiableConditions)),
                    _InfoRow(
                      label: '구매 시급성',
                      value: StructuredIntentVocabulary.purchaseUrgencyLabel(intent.purchaseUrgency),
                    ),
                    _InfoRow(
                      label: '실물로 확인하고 싶은 요소',
                      value: intent.physicalCheckAttributes.isEmpty
                          ? '없음'
                          : intent.physicalCheckAttributes
                                .map(StructuredIntentVocabulary.attributeLabel)
                                .join(', '),
                    ),
                    _InfoRow(
                      label: '대기 가능 여부',
                      value: StructuredIntentVocabulary.yesNoUnknownLabel(intent.canWait),
                    ),
                    _InfoRow(
                      label: '타 매장 방문 가능 여부',
                      value: StructuredIntentVocabulary.yesNoUnknownLabel(intent.canVisitOtherStore),
                    ),
                  ],
                ),
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    const Text('장바구니 원제품', style: StaffText.header16SemiBold),
                    Text(
                      '${widget.cartItem.productName} · 컬러: ${widget.cartItem.color} · SKU: ${widget.cartItem.skuId}',
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LastIntentEditScreen(
                            customer: widget.customer,
                            cartItem: widget.cartItem,
                          ),
                        ),
                      );
                    },
                  ),
                  StaffButton(
                    label: '맞아요, 다음 단계로',
                    variant: StaffButtonVariant.primary,
                    onPressed: () => _confirmAndDecide(session),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _conditionsList(Map<String, String> conditions) {
    if (conditions.isEmpty) {
      return '없음';
    }
    return conditions.entries
        .map(
          (MapEntry<String, String> e) =>
              '${StructuredIntentVocabulary.attributeLabel(e.key)}: '
              '${StructuredIntentVocabulary.attributeValueLabel(e.key, e.value)}',
        )
        .join(', ');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: <Widget>[
        Text(label, style: StaffText.meta11),
        Text(value, style: StaffText.body12),
      ],
    );
  }
}
