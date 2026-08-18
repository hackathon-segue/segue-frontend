import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/segue_card_tokens.dart';
import '../utils/structured_intent_vocabulary.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';
import 'last_intent_completion_screen.dart';

/// Figma node 169:3683/169:3821 "추가 상담 진행" (ADDITIONAL_CONSULTATION).
///
/// Figma's own frame shows a 진행/미진행 toggle + free-text input + two
/// different completion labels ("요청 접수 완료" / "해당 제품 상담 중단") — none of
/// that has a backing field anywhere in API.md/SCHEMA.md (no endpoint takes
/// free-text "고객 답변"/"실행 불가 사유" at this step), and it conflicts with
/// this issue's own explicit written rule: "CTA는 하나: 조건 다시 확인하기"
/// and "사용자에게 4개 결과 중 하나를 선택하게 함" 로직을 만들지 마.
/// Same precedent as this issue's "결과4 디자인이 비슷한 제품" instruction
/// (override stale/conflicting Figma example content with the written
/// project rule) — so this screen keeps Figma's layout/cards but replaces
/// the toggle panel with the single real `actionButtonLabel` CTA, which
/// calls the SAME `execute()`/completion flow every other resultType uses
/// (RECONSULT is just another `actionType` per API.md's `/execute` table —
/// no special-cased second flow, satisfying "기존 route/state 재사용").
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

  static const Duration _minExecutingDuration = Duration(milliseconds: 600);

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
    if (session.state.executionResponse != null && session.state.resultSaveState.hasData) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              LastIntentCompletionScreen(customer: widget.customer, cartItem: widget.cartItem),
        ),
      );
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
          return const _Scaffold(
            child: Text('생성된 결과가 없습니다.', style: SegueCardText.body18),
          );
        }

        if (_executing || session.state.executionState.isLoading) {
          return _Scaffold(
            child: AppStateView.loading(
              title: session.state.executionState.isLoading ? '요청을 접수하고 있습니다' : '상담 결과를 저장하고 있습니다',
            ),
          );
        }

        if (session.state.executionState.hasError) {
          return _Scaffold(
            child: AppStateView.error(
              message: '요청 접수에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleExecute(session),
            ),
          );
        }

        if (session.state.resultSaveState.hasError) {
          return _Scaffold(
            child: AppStateView.error(
              message: '상담 결과 저장에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleRetrySave(session),
            ),
          );
        }

        return _Scaffold(
          ctaLabel: result.actionButtonLabel,
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
                          value: '${widget.cartItem.productName} ${widget.cartItem.color}',
                        ),
                        SegueLabelValueRow(label: '고객 핵심 조건', value: result.coreConditions),
                        SegueLabelValueRow(
                          label: '상담 일시',
                          value: _formatDateTime(DateTime.now()),
                        ),
                        const SegueLabelValueRow(label: '현재 상태', value: '추가 상담 필요'),
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
                child: Text(
                  '고객과 함께 핵심 조건을 다시 확인한 뒤 상담을 재개합니다.',
                  style: SegueCardText.body18.copyWith(color: SegueCardColors.subtitleMuted),
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
  const _Scaffold({required this.child, this.ctaLabel, this.onCta});

  final Widget child;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return SegueCardShell(
      step: '3/5',
      title: '추가 상담 진행',
      subtitle: '보다 정확한 제안을 위해 추가 상담이 필요합니다. Client Advisor가 고객님과 더 깊이 있는 상담을 진행하겠습니다.',
      body: child,
      bottomBar: SegueBottomActionRow(
        onBackToStart: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
        cta: ctaLabel != null ? SegueCtaButton(label: ctaLabel!, onPressed: onCta) : null,
      ),
    );
  }
}
