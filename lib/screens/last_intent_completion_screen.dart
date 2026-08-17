import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';

/// Issue #14 "요청 접수 완료 화면". Reached after [LastIntentCardScreen]'s
/// single CTA successfully calls `execute()`.
///
/// This is explicitly NOT a "완료" screen for the underlying real-world
/// action (no purchase/reservation/product-transfer has actually happened)
/// — it only confirms the REQUEST was accepted and hands off to CA
/// follow-up. Copy is written to avoid implying otherwise.
///
/// [ExecutionStatus.unable]/[ExecutionStatus.followUpNeeded] aren't
/// reachable yet (that requires the PATCH updateExecutionStatus() flow,
/// a later issue's scope) — this screen already renders all three so no
/// UI rework is needed once that flow exists.
class LastIntentCompletionScreen extends StatelessWidget {
  const LastIntentCompletionScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  static String _statusLabel(ExecutionStatus status) {
    return switch (status) {
      ExecutionStatus.requested => '요청 접수 · 확인 중',
      ExecutionStatus.unable => '실행 불가',
      ExecutionStatus.followUpNeeded => '추가 확인 필요',
    };
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: customer, cartItem: cartItem);
    final ExecuteConsultationResponse? response = session.state.executionResponse;
    final ExecutionStatus? status = session.state.executionStatus;
    final String? note = session.state.executionNote;

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: response == null
          ? const Text('접수된 요청 정보가 없습니다.', style: StaffText.body12)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: <Widget>[
                const Text('요청 접수 완료', style: StaffText.title20Bold),
                if (status != null)
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: <Widget>[
                        Row(
                          spacing: 8,
                          children: <Widget>[
                            StaffButton(
                              label: _statusLabel(status),
                              variant: StaffButtonVariant.chip,
                              onPressed: null,
                            ),
                          ],
                        ),
                        if (note != null && note.isNotEmpty)
                          Text('사유: $note', style: StaffText.body12),
                      ],
                    ),
                  ),
                SectionCard(
                  child: Text(response.completionMessage, style: StaffText.header16SemiBold),
                ),
                const SectionCard(
                  child: Text(
                    '아직 실제 구매·예약·제품 이동이 완료된 것은 아닙니다. Client Advisor의 후속 확인이 진행되며, '
                    '이후 확인 결과에 따라 상태가 갱신될 수 있습니다.',
                    style: StaffText.meta11,
                  ),
                ),
                StaffButton(
                  label: '상담 홈으로',
                  variant: StaffButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.staffHome));
                  },
                ),
              ],
            ),
    );
  }
}
