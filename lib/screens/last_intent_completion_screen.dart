import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';

/// Figma node 169:3891 "요청 접수 완료 화면" (Issue #46, superseding the
/// previous #14/#15 build of this screen at node 14:2301 — that node is no
/// longer the confirmed design). Reached after a result-detail screen's CTA
/// successfully calls `execute()`.
///
/// This is explicitly NOT a "완료" screen for the underlying real-world
/// action (no purchase/reservation/product-transfer has actually happened)
/// — it only confirms the REQUEST was accepted and hands off to CA
/// follow-up. Copy is written to avoid implying otherwise.
///
/// [ExecutionStatus.unable]/[ExecutionStatus.followUpNeeded] aren't
/// reachable yet (PATCH updateExecutionStatus() is a later issue's scope)
/// — the status label already switches over all three so no UI rework is
/// needed once that flow exists.
class LastIntentCompletionScreen extends StatelessWidget {
  const LastIntentCompletionScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  static String _statusLabel(ExecutionStatus status) {
    return switch (status) {
      ExecutionStatus.requested => '확인 대기',
      ExecutionStatus.unable => '실행 불가',
      ExecutionStatus.followUpNeeded => '추가 확인 필요',
    };
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: customer, cartItem: cartItem);
    final ExecuteConsultationResponse? response = session.state.executionResponse;
    final ExecutionStatus? status = session.state.executionStatus;
    final DecisionResult? decisionResult = session.state.decisionResult;
    final ConsultationResult? savedResult = session.state.resultSaveState.data;

    if (response == null) {
      return SegueCardShell(
        step: '5/5',
        title: '요청 접수 완료',
        body: const Text('접수된 요청 정보가 없습니다.', style: SegueCardText.body18),
        bottomBar: SegueBottomActionRow(
          onBackToStart: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
        ),
      );
    }

    return SegueCardShell(
      step: '5/5',
      title: '요청 접수 완료',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _HeadlineCard(headline: response.completionMessage),
          const SizedBox(height: 22),
          SegueInfoCard(
            title: '요청 내용',
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget left = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SegueLabelValueRow(
                      label: '요청 유형',
                      value: decisionResult?.actionButtonLabel ?? '-',
                    ),
                    SegueLabelValueRow(
                      label: '제품',
                      value: '${cartItem.productName} ${cartItem.color}',
                    ),
                    SegueLabelValueRow(label: '담당 CA', value: '매장 ${session.state.storeId} 담당자'),
                    if (status != null) SegueLabelValueRow(label: '상태', value: _statusLabel(status)),
                  ],
                );
                final Widget right = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SegueLabelValueRow(label: '고객', value: customer.name),
                    SegueLabelValueRow(label: '고객 번호', value: customer.phoneNumber),
                    SegueLabelValueRow(
                      label: '접수 시각',
                      value: _formatDateTime(savedResult?.consultedAt ?? DateTime.now()),
                    ),
                  ],
                );
                if (constraints.maxWidth >= 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: left),
                      const SizedBox(width: 32),
                      Expanded(child: right),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[left, const SizedBox(height: 16), right],
                );
              },
            ),
          ),
        ],
      ),
      bottomBar: SegueBottomActionRow(
        onBackToStart: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
        cta: SegueCtaButton(
          label: '해당 제품 상담 완료',
          onPressed: () =>
              Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.cartInventory)),
        ),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.headline});

  final String headline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: SegueCardColors.border, width: 2)),
      child: Row(
        children: <Widget>[
          Container(
            width: 63,
            height: 63,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: SegueCardColors.avatarBg, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(headline, style: SegueCardText.screenTitle22),
                const SizedBox(height: 8),
                const Text(
                  '담당 Client Advisor가 실제 재고를 다시 확인한 뒤 고객 앱에 결과를 저장합니다.',
                  style: SegueCardText.subtitle16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
