import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';

/// Figma node 14:2301 "요청 접수 완료 화면". Reached after
/// [LastIntentCardScreen]'s single CTA successfully calls `execute()`.
///
/// This is explicitly NOT a "완료" screen for the underlying real-world
/// action (no purchase/reservation/product-transfer has actually happened)
/// — it only confirms the REQUEST was accepted and hands off to CA
/// follow-up. Copy is written to avoid implying otherwise.
///
/// [ExecutionStatus.unable]/[ExecutionStatus.followUpNeeded] aren't
/// reachable yet (that requires the PATCH updateExecutionStatus() flow, a
/// later issue's scope) — the status label already switches over all three
/// so no UI rework is needed once that flow exists.
///
/// The "앱 상담 결과 확인" button is rendered per Figma but intentionally a
/// no-op: the customer-mobile screens are owned by a separate branch/team,
/// so this screen must not build or link into that UI (see the
/// `#15` follow-up scope note) — only the tablet-side repository/local
/// store that a future mobile screen can read from is implemented.
class LastIntentCompletionScreen extends StatelessWidget {
  const LastIntentCompletionScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  static String _statusLabel(ExecutionStatus status) {
    return switch (status) {
      ExecutionStatus.requested => '접수됨',
      ExecutionStatus.unable => '실행 불가',
      ExecutionStatus.followUpNeeded => '추가 확인 필요',
    };
  }

  static String _formatDateTime(DateTime dt) {
    final bool isPm = dt.hour >= 12;
    final int hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}년 ${dt.month}월 ${dt.day}일 ${isPm ? '오후' : '오전'} $hour12:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: customer, cartItem: cartItem);
    final ExecuteConsultationResponse? response = session.state.executionResponse;
    final ExecutionStatus? status = session.state.executionStatus;
    final String? note = session.state.executionNote;
    final DecisionResult? decisionResult = session.state.decisionResult;
    final ConsultationResult? savedResult = session.state.resultSaveState.data;
    final InventoryStatus inventory = cartItem.inventory;

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: response == null
          ? const Text('접수된 요청 정보가 없습니다.', style: StaffText.body12)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 24,
              children: <Widget>[
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    const Text('요청 접수 완료', style: StaffText.header16SemiBold),
                    if (status != null) Text(_statusLabel(status), style: StaffText.body12),
                  ],
                ),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: <Widget>[
                      const Text('접수 내용', style: StaffText.header16SemiBold),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: <Widget>[
                          _InfoColumn(
                            label: '요청 유형',
                            value: decisionResult?.actionButtonLabel ?? '-',
                          ),
                          _InfoColumn(
                            label: '접수 시각',
                            value: _formatDateTime(savedResult?.consultedAt ?? DateTime.now()),
                          ),
                          _InfoColumn(
                            label: '담당 매장',
                            value: '매장 ${session.state.storeId}',
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
                      const Text('접수 상태 안내', style: StaffText.header16SemiBold),
                      const Text(
                        '요청이 정상적으로 접수되었습니다. 실제 예약·구매·제품 이동이 완료된 것은 아니며, '
                        'Client Advisor가 후속 확인을 직접 진행합니다.',
                        style: StaffText.body12,
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: <Widget>[
                          _BulletRow('타 매장 재고 확인은 매장 간 연락을 통해 순서대로 진행됩니다.'),
                          _BulletRow('확인 완료 후 고객에게 직접 안내드립니다.'),
                          _BulletRow('진행 상황은 고객 앱의 상담 결과에서 다시 확인할 수 있습니다.'),
                        ],
                      ),
                      if (note != null && note.isNotEmpty)
                        Text('사유: $note', style: StaffText.body12),
                    ],
                  ),
                ),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: <Widget>[
                      const Text('재고·입고 정보 기준 시점', style: StaffText.header16SemiBold),
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: <Widget>[
                          _InfoColumn(
                            label: '현재 매장 재고',
                            value: inventory.currentStoreInStock ? '보유 확인됨' : '미보유 확인됨',
                            valueGap: 4,
                          ),
                          const _InfoColumn(
                            label: '타 매장 재고',
                            value: '미확인 — 후속 연락으로 확인 예정',
                            valueGap: 4,
                          ),
                          const _InfoColumn(
                            label: '입고 예정',
                            value: '미확인 — 별도 안내 예정',
                            valueGap: 4,
                          ),
                        ],
                      ),
                      const Text(
                        '재고 정보는 확인 시점 이후 변동될 수 있으며, 확정 전까지 구매 가능을 보장하지 않습니다.',
                        style: StaffText.meta11,
                      ),
                    ],
                  ),
                ),
                const SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: <Widget>[
                      Text('고객 앱 상담 결과 확인', style: StaffText.header16SemiBold),
                      Text(
                        '이 상담 결과는 고객 앱에 저장되었습니다. 고객이 앱에서 접수 내용과 후속 안내를 직접 확인할 수 있습니다.',
                        style: StaffText.body12,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: StaffButton(
                          label: '앱 상담 결과 확인',
                          variant: StaffButtonVariant.primary,
                          onPressed: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value, this.valueGap = 8});

  final String label;
  final String value;
  final double valueGap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: valueGap,
        children: <Widget>[
          Text(label, style: StaffText.meta11),
          Text(value, style: StaffText.body12),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        const Text('·', style: StaffText.body12),
        Expanded(child: Text(text, style: StaffText.body12)),
      ],
    );
  }
}
