import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/decision_result_validator.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';
import 'last_intent_additional_consultation_screen.dart';
import 'last_intent_result_product_screen.dart';

/// Figma node 164:3213 "Last Intent Card 화면" (Issue #46, superseding the
/// previous #13/#14 build of this screen). Now a lightweight SUMMARY with
/// exactly ONE CTA that only NAVIGATES — per the issue's explicit
/// navigation contract ("CTA 클릭 시 현재 상담 session의 resultType에 따라
/// 이동한다"), `execute()` itself has moved to each result-type detail
/// screen's own CTA (matching Figma: 159:2295/159:2173/159:3053/169:3683
/// each have their own separate "Continue Button").
///
/// [DecisionResultValidator] still runs here before anything renders — same
/// forbidden-language gate as before (#14), just relocated from the old
/// single-screen layout into this summary.
class LastIntentCardScreen extends StatelessWidget {
  const LastIntentCardScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  void _goToResultScreen(BuildContext context, DecisionResultType resultType) {
    final Widget target = switch (resultType) {
      DecisionResultType.exactProduct ||
      DecisionResultType.comparisonExperience ||
      DecisionResultType.todayPurchase => LastIntentResultProductScreen(
        customer: customer,
        cartItem: cartItem,
      ),
      DecisionResultType.additionalConsultation => LastIntentAdditionalConsultationScreen(
        customer: customer,
        cartItem: cartItem,
      ),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: customer, cartItem: cartItem);

    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? _) {
        if (session.state.decisionState.isLoading) {
          return const _CardScaffold(child: AppStateView.loading(title: '결과를 다시 불러오고 있습니다'));
        }

        final DecisionResult? result = session.state.decisionResult;
        if (result == null) {
          return const _CardScaffold(
            child: Text('생성된 Last Intent Card가 없습니다.', style: SegueCardText.body18),
          );
        }

        // AC: 금지 표현이 포함된 raw 결과를 화면에 그대로 노출하지 않는다. 재시도는
        // decide()를 다시 호출한다 — execute()는 아직 호출된 적이 없으므로
        // 재실행할 대상 자체가 없다.
        if (DecisionResultValidator.hasForbiddenLanguage(result)) {
          return _CardScaffold(
            child: AppStateView.error(
              title: '결과를 표시할 수 없습니다',
              message: '이 상담 결과에는 표시할 수 없는 표현이 포함되어 있습니다. 다시 시도해 주세요.',
              onAction: session.decide,
            ),
          );
        }

        final ProductSkuSummary? recommended = result.recommendedProduct;

        return _CardScaffold(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final List<Widget> left = <Widget>[
                _ProductSummaryCard(cartItem: cartItem, recommended: recommended),
                SegueInfoCard(
                  title: '고객 핵심 조건',
                  child: Text(result.coreConditions, style: SegueCardText.body18),
                ),
              ];
              final List<Widget> right = <Widget>[
                SegueInfoCard(
                  title: '판단 근거',
                  child: Text(result.reason, style: SegueCardText.body18),
                ),
                _NextStepPreviewCard(
                  result: result,
                  onContinue: () => _goToResultScreen(context, result.resultType),
                ),
              ];

              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          left[0],
                          const SizedBox(height: 16),
                          left[1],
                        ],
                      ),
                    ),
                    const SizedBox(width: 26),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          right[0],
                          const SizedBox(height: 16),
                          right[1],
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final Widget w in <Widget>[...left, ...right]) ...<Widget>[
                    w,
                    const SizedBox(height: 16),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CardScaffold extends StatelessWidget {
  const _CardScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: LastIntentSessionScope.of(context).activeCount,
      stepBadge: '4/5',
      screenTitle: 'SEGUE CARD',
      screenTitleStyle: SegueCardText.screenTitle24,
      body: child,
      bottomBar: SegueBottomActionRow(
        onBackToStart: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({required this.cartItem, required this.recommended});

  final CartItem cartItem;
  final ProductSkuSummary? recommended;

  @override
  Widget build(BuildContext context) {
    return SegueInfoCard(
      title: '상담 제품 요약',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SegueProductImage(width: 100, height: 108),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(cartItem.category, style: SegueCardText.bodyLabel18Bold),
                const SizedBox(height: 12),
                Text(cartItem.productName, style: SegueCardText.productMeta20),
                Text(cartItem.color, style: SegueCardText.productMeta20),
                Text(cartItem.size, style: SegueCardText.productMeta20),
                if (recommended != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SegueLabelValueRow(label: '제안 제품', value: recommended!.productName),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepPreviewCard extends StatelessWidget {
  const _NextStepPreviewCard({required this.result, required this.onContinue});

  final DecisionResult result;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ProductSkuSummary? recommended = result.recommendedProduct;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: SegueCardColors.previewPanelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.nextAction,
            style: SegueCardText.screenTitle22.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          if (recommended != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SegueProductImage(width: 100, height: 108),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(result.difference, style: SegueCardText.body18),
                ),
              ],
            )
          else
            Text(result.difference, style: SegueCardText.body18),
          const SizedBox(height: 16),
          SegueCtaButton(label: result.actionButtonLabel, onPressed: onContinue),
        ],
      ),
    );
  }
}
