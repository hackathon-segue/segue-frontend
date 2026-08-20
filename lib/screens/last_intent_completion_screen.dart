import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/execution_status_display.dart';
import '../utils/product_option_display.dart';
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
/// The "후속 처리 상태" card lets the CA drive `updateExecutionStatus()`
/// (Issue #26) — switching to UNABLE/FOLLOW_UP_NEEDED only updates what the
/// customer app shows, it never implies the real-world action (purchase/
/// reservation/product transfer) itself happened.
class LastIntentCompletionScreen extends StatefulWidget {
  const LastIntentCompletionScreen({
    required this.customer,
    required this.cartItem,
    super.key,
  });

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentCompletionScreen> createState() =>
      _LastIntentCompletionScreenState();
}

class _LastIntentCompletionScreenState
    extends State<LastIntentCompletionScreen> {
  final TextEditingController _noteController = TextEditingController();
  ExecutionStatus _selectedStatus = ExecutionStatus.requested;
  bool _initializedFromSession = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: widget.customer, cartItem: widget.cartItem);
    final ExecuteConsultationResponse? response =
        session.state.executionResponse;
    final ExecutionStatus? status = session.state.executionStatus;
    final DecisionResult? decisionResult = session.state.decisionResult;
    final ConsultationResult? savedResult = session.state.resultSaveState.data;

    if (!_initializedFromSession) {
      _selectedStatus = status ?? ExecutionStatus.requested;
      _noteController.text = session.state.executionNote ?? '';
      _initializedFromSession = true;
    }

    if (response == null) {
      return SegueCardShell(
        pageTitle: 'CURRENT SESSION',
        activeMenuItem: TabletMenuItem.currentSession,
        sessionCount: LastIntentSessionScope.of(context).activeCount,
        guardedSession: session,
        stepBadge: '5/5',
        screenTitle: '요청 접수 완료',
        body: const Text('접수된 요청 정보가 없습니다.', style: SegueCardText.body18),
        bottomBar: SegueBottomActionRow(
          onBackToStart: () =>
              navigateToTabletRoute(context, AppRoutes.staffHome),
        ),
      );
    }

    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: LastIntentSessionScope.of(context).activeCount,
      guardedSession: session,
      stepBadge: '5/5',
      screenTitle: '요청 접수 완료',
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
                      value:
                          '${widget.cartItem.productName} ${displayProductColor(widget.cartItem.color)}',
                    ),
                    SegueLabelValueRow(
                      label: '담당 CA',
                      value: '매장 ${session.state.storeId} 담당자',
                    ),
                    if (status != null)
                      SegueLabelValueRow(
                        label: '상태',
                        value: executionStatusLabel(status),
                      ),
                  ],
                );
                final Widget right = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SegueLabelValueRow(
                      label: '고객',
                      value: widget.customer.name,
                    ),
                    SegueLabelValueRow(
                      label: '고객 번호',
                      value: widget.customer.phoneNumber,
                    ),
                    SegueLabelValueRow(
                      label: '접수 시각',
                      value: _formatDateTime(
                        savedResult?.consultedAt ?? DateTime.now(),
                      ),
                    ),
                    SegueLabelValueRow(
                      label: '처리 갱신',
                      value: _formatDateTime(
                        savedResult?.executionUpdatedAt ?? DateTime.now(),
                      ),
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
          const SizedBox(height: 22),
          _ExecutionStatusUpdateCard(
            selectedStatus: _selectedStatus,
            noteController: _noteController,
            updateState: session.state.executionStatusUpdateState,
            onStatusChanged: (ExecutionStatus status) {
              setState(() => _selectedStatus = status);
            },
            onNoteChanged: () => setState(() {}),
            onSubmit: () => session.updateExecutionStatus(
              _selectedStatus,
              note: _noteController.text,
            ),
          ),
        ],
      ),
      bottomBar: SegueBottomActionRow(
        onBackToStart: () =>
            navigateToTabletRoute(context, AppRoutes.staffHome),
        cta: SegueCtaButton(
          label: '해당 제품 상담 완료',
          onPressed: () =>
              navigateToTabletRoute(context, AppRoutes.cartInventory),
        ),
      ),
    );
  }
}

/// Figma (169:3891)-consistent card for the "후속 처리 상태" (Issue #26)
/// CA-driven status update — reuses [SegueInfoCard]/[SegueCardText] so it
/// matches this screen's own visual language, not a competing style.
class _ExecutionStatusUpdateCard extends StatelessWidget {
  const _ExecutionStatusUpdateCard({
    required this.selectedStatus,
    required this.noteController,
    required this.updateState,
    required this.onStatusChanged,
    required this.onNoteChanged,
    required this.onSubmit,
  });

  final ExecutionStatus selectedStatus;
  final TextEditingController noteController;
  final AsyncValue<ConsultationResult> updateState;
  final ValueChanged<ExecutionStatus> onStatusChanged;
  final VoidCallback onNoteChanged;
  final Future<void> Function() onSubmit;

  bool get _noteRequired => executionStatusRequiresNote(selectedStatus);

  bool get _canSubmit {
    if (updateState.isLoading) {
      return false;
    }
    if (!_noteRequired) {
      return true;
    }
    return noteController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bool showNote = _noteRequired;
    final ConsultationResult? updated = updateState.data;

    return SegueInfoCard(
      title: '후속 처리 상태',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ExecutionStatus>(
              showSelectedIcon: false,
              segments: <ButtonSegment<ExecutionStatus>>[
                for (final ExecutionStatus status in ExecutionStatus.values)
                  ButtonSegment<ExecutionStatus>(
                    value: status,
                    label: Text(executionStatusLabel(status)),
                  ),
              ],
              selected: <ExecutionStatus>{selectedStatus},
              onSelectionChanged: (Set<ExecutionStatus> selected) {
                onStatusChanged(selected.single);
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            executionStatusMessage(
              status: selectedStatus,
              note: showNote && noteController.text.trim().isNotEmpty
                  ? noteController.text.trim()
                  : null,
            ),
            style: SegueCardText.body18,
          ),
          if (showNote) ...<Widget>[
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              onChanged: (_) => onNoteChanged(),
              decoration: const InputDecoration(
                labelText: '고객 앱에 표시할 사유',
                hintText: '예: 타 매장 재고 확인이 필요합니다.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: _canSubmit ? onSubmit : null,
                child: Text(updateState.isLoading ? '갱신 중' : '상태 갱신'),
              ),
              const Text(
                '실제 예약, 결제, 제품 이동 처리 없이 고객에게 보일 상태만 갱신합니다.',
                style: SegueCardText.subtitle16,
              ),
            ],
          ),
          if (updateState.hasData && updated != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              '${executionStatusLabel(updated.executionStatus)} 상태로 갱신되었습니다.',
              style: SegueCardText.body18,
            ),
          ],
          if (updateState.hasError) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _errorMessage(
                updateState.error,
                fallback: '상태 갱신에 실패했습니다. 다시 시도해 주세요.',
              ),
              style: SegueCardText.body18.copyWith(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

String _errorMessage(Object? error, {required String fallback}) {
  if (error is AppException) {
    return error.message;
  }
  return fallback;
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.headline});

  final String headline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: SegueCardColors.border, width: 2),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 63,
            height: 63,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SegueCardColors.stepBadgeBg,
              shape: BoxShape.circle,
            ),
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
