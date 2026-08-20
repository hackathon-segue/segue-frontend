import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/product_option_display.dart';
import '../utils/segue_card_tokens.dart';
import '../utils/structured_intent_vocabulary.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';
import 'last_intent_intro_screen.dart';

/// Figma node 169:3683 ("진행" checked) / 169:3821 ("미진행" checked) —
/// "추가 상담 진행" (ADDITIONAL_CONSULTATION). Both nodes are the SAME screen
/// state-toggled, not separate pages — [_inProgress] is a local UI-only
/// toggle (no backing field anywhere in API.md/SCHEMA.md). The CTA always
/// calls the same real `execute()` (RECONSULT, per API.md's `/execute`
/// table) as before — Issue #64 only changed what happens AFTER it
/// succeeds: both branches now return straight to the cart (never the
/// "요청 접수 완료" hand-off screen), and:
/// - "진행" (169:3683): [_noteController]'s CA-written note is attached via
///   the existing `updateExecutionStatus(REQUESTED, note: ...)` PATCH
///   (status unchanged, only the note) — reuses real backend capability
///   instead of inventing a new one. Cart row shows the normal "상담 완료"
///   badge.
/// - "미진행" (169:3821): [LastIntentSessionController.declineAdditionalConsultation]
///   sets a local-only display flag (never a new `ExecutionStatus` value —
///   backend only defines REQUESTED/UNABLE/FOLLOW_UP_NEEDED). Cart row
///   shows Figma 98:1740's darker "상담 중단" badge instead.
class LastIntentAdditionalConsultationScreen extends StatefulWidget {
  const LastIntentAdditionalConsultationScreen({
    required this.customer,
    required this.cartItem,
    super.key,
  });

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentAdditionalConsultationScreen> createState() =>
      _LastIntentAdditionalConsultationScreenState();
}

class _LastIntentAdditionalConsultationScreenState
    extends State<LastIntentAdditionalConsultationScreen> {
  bool _executing = false;

  // Figma 169:3683 ("진행" checked) vs 169:3821 ("미진행" checked) — a single
  // local UI toggle, not a backend field (confirmed: no such field exists on
  // StructuredIntent/DecisionResult per API.md/SCHEMA.md). Defaults to the
  // "진행" state, matching 169:3683's checked default.
  bool _inProgress = true;
  final TextEditingController _noteController = TextEditingController();

  static const Duration _minExecutingDuration = Duration(milliseconds: 600);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleExecute(LastIntentSessionController session) {
    return _runAndMaybeNavigate(session, session.execute);
  }

  Future<void> _handleRetrySave(LastIntentSessionController session) {
    return _runAndMaybeNavigate(session, session.retrySaveConsultationResult);
  }

  Future<void> _runAndMaybeNavigate(
    LastIntentSessionController session,
    Future<void> Function() action,
  ) async {
    if (_executing) {
      return;
    }
    setState(() => _executing = true);
    final Stopwatch stopwatch = Stopwatch()..start();
    await action();
    final Duration remaining = _minExecutingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    setState(() => _executing = false);
    if (session.state.executionResponse != null &&
        session.state.resultSaveState.hasData) {
      if (_inProgress) {
        // Attaches the CA's note via the real PATCH endpoint (status stays
        // REQUESTED — no new ExecutionStatus value) rather than inventing
        // storage for it; only when there's actually something to attach.
        final String note = _noteController.text.trim();
        if (note.isNotEmpty) {
          await session.updateExecutionStatus(
            ExecutionStatus.requested,
            note: note,
          );
          if (!mounted) {
            return;
          }
        }
      } else {
        session.declineAdditionalConsultation();
      }
      navigateToTabletRoute(context, AppRoutes.cartInventory);
    }
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

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionController session = LastIntentSessionScope.of(
      context,
    ).sessionFor(customer: widget.customer, cartItem: widget.cartItem);

    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? _) {
        final DecisionResult? result = session.state.decisionResult;
        final StructuredIntent? intent = session.state.structuredIntent;
        if (result == null || intent == null) {
          return _Scaffold(
            customer: widget.customer,
            cartItem: widget.cartItem,
            child: const Text('생성된 결과가 없습니다.', style: SegueCardText.body18),
          );
        }

        if (_executing || session.state.executionState.isLoading) {
          return _Scaffold(
            customer: widget.customer,
            cartItem: widget.cartItem,
            child: AppStateView.loading(
              title: session.state.executionState.isLoading
                  ? '요청을 접수하고 있습니다'
                  : '상담 결과를 저장하고 있습니다',
            ),
          );
        }

        if (session.state.executionState.hasError) {
          return _Scaffold(
            customer: widget.customer,
            cartItem: widget.cartItem,
            child: AppStateView.error(
              message: '요청 접수에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleExecute(session),
            ),
          );
        }

        if (session.state.resultSaveState.hasError) {
          return _Scaffold(
            customer: widget.customer,
            cartItem: widget.cartItem,
            child: AppStateView.error(
              message: '상담 결과 저장에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleRetrySave(session),
            ),
          );
        }

        return _Scaffold(
          customer: widget.customer,
          cartItem: widget.cartItem,
          // Figma-literal display override (169:3724/169:3972), same
          // established pattern as the result-detail screens' CTA label —
          // execute() below still sends the real actionType/actionButtonLabel
          // from decisionResult, only the on-screen text/arrow toggle here.
          ctaLabel: _inProgress ? '상담 완료' : '해당 제품 상담 중단',
          // Neither 169:3683 nor 169:3821's Continue Button has an arrow
          // icon (unlike this flow's other Continue Buttons).
          ctaShowArrow: false,
          onCta: () => _handleExecute(session),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget left = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SegueInfoCard(
                    title: '이전 상담 요약',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SegueLabelValueRow(
                          label: '관심 제품',
                          value:
                              '${widget.cartItem.productName} ${displayProductColor(widget.cartItem.color)}',
                        ),
                        SegueLabelValueRow(
                          label: '고객 핵심 조건',
                          value: result.coreConditions,
                        ),
                        SegueLabelValueRow(
                          label: '상담 일시',
                          value: _formatDateTime(DateTime.now()),
                        ),
                        const SegueLabelValueRow(
                          label: '현재 상태',
                          value: '추가 상담 필요',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegueInfoCard(
                    title: '고객 핵심 조건',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SegueLabelValueRow(
                          label: '필수 조건',
                          value: _conditionsList(intent.essentialConditions),
                        ),
                        SegueLabelValueRow(
                          label: '추가 조건',
                          value: _conditionsList(intent.preferredConditions),
                        ),
                        SegueLabelValueRow(
                          label: '미확정 항목',
                          value: intent.followUpReason.isNotEmpty
                              ? intent.followUpReason
                              : _conditionsList(intent.negotiableConditions),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final Widget right = SegueInfoCard(
                title: '후속 행동 처리',
                backgroundColor: SegueCardColors.panelBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '고객과 함께 핵심 조건을 다시 확인한 뒤 상담을 재개합니다.',
                      style: SegueCardText.body18.copyWith(
                        color: SegueCardColors.subtitleMuted,
                      ),
                    ),
                    // Figma: subtitle bottom 322+24=346 → first checkbox row
                    // top 372 = 26px.
                    const SizedBox(height: 26),
                    _ToggleCheckboxRow(
                      label: '추가 상담 미진행',
                      checked: !_inProgress,
                      onTap: () => setState(() => _inProgress = false),
                    ),
                    _ToggleCheckboxRow(
                      label: '추가 상담 진행',
                      checked: _inProgress,
                      onTap: () => setState(() => _inProgress = true),
                    ),
                    // Figma: 2nd checkbox row bottom 402+30=432 → input box
                    // top 443 = 11px.
                    const SizedBox(height: 11),
                    _NoteInput(
                      controller: _noteController,
                      hintText: _inProgress
                          ? '상담 내용 기록하기'
                          : '실행 불가 사유 입력하기 (예: 고객 동의 거절, 시간 부족 등)',
                    ),
                  ],
                ),
              );

              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: left),
                    const SizedBox(width: 26),
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
        );
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.customer,
    required this.cartItem,
    required this.child,
    this.ctaLabel,
    this.onCta,
    this.ctaShowArrow = true,
  });

  final Customer customer;
  final CartItem cartItem;
  final Widget child;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool ctaShowArrow;

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);
    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: manager.activeCount,
      guardedSession: manager.sessionFor(
        customer: customer,
        cartItem: cartItem,
      ),
      stepBadge: '3/5',
      screenTitle: '추가 상담 진행',
      subtitle:
          '보다 정확한 제안을 위해 추가 상담이 필요합니다. Client Advisor가 고객님과 더 깊이 있는 상담을 진행하겠습니다.',
      body: child,
      bottomBar: SegueBottomActionRow(
        onBackToStart: () => navigateToLastIntentIntro(
          context,
          customer: customer,
          cartItem: cartItem,
        ),
        cta: ctaLabel != null
            ? SegueCtaButton(
                label: ctaLabel!,
                onPressed: onCta,
                showArrow: ctaShowArrow,
              )
            : null,
      ),
    );
  }
}

/// Figma (169:3805/169:3816 / 169:3874/169:3875)'s "추가 상담 진행/미진행"
/// toggle checkbox — 15×15 box, 2px ink border, filled+check icon when
/// checked (same checked-state visual language as [SegueCheckboxRow], no
/// bespoke SVG asset in either). 11px label gap and
/// [SegueCardText.toggleCheckLabel18] are this screen's own measured
/// values — [SegueCheckboxRow]'s 28px gap/19px-Bold label are the consent
/// screen's own spec, not reused here since they don't match this Figma.
class _ToggleCheckboxRow extends StatelessWidget {
  const _ToggleCheckboxRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? SegueCardColors.ink : Colors.white,
                border: Border.all(color: SegueCardColors.ink, width: 2),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 11),
            Text(label, style: SegueCardText.toggleCheckLabel18),
          ],
        ),
      ),
    );
  }
}

/// Figma (169:3802/169:3872)'s free-text box — 501×215 (this screen's own
/// measured size, distinct from [_AnswerInput]'s 239-tall box on the
/// follow-up-question screen), white bg, 2px border, hint text only (no
/// backing API field at this step — same rationale as this file's class
/// doc comment — so its content isn't sent anywhere, purely matching
/// Figma's input affordance).
class _NoteInput extends StatelessWidget {
  const _NoteInput({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 215,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SegueCardColors.border, width: 2),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: SegueCardText.detailValue16,
        cursorColor: SegueCardColors.ink,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
          hintText: hintText,
          hintStyle: SegueCardText.inputPlaceholder14,
        ),
      ),
    );
  }
}
