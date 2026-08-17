import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_text_field.dart';
import 'last_intent_confirm_screen.dart';

/// Figma node 14:1417 "보충 질문 제시 화면".
///
/// Reached when Issue #10's [LastIntentUtteranceScreen] gets
/// `needsFollowUp: true` back from the mock adapter. Reuses the same
/// SKU-scoped [LastIntentSessionController] (`sessionFor`) — no new
/// consultation-target state — and its existing `requestFollowUpQuestion` /
/// `submitFollowUpAnswer` methods (already built in Issue #7/#8, unused
/// until now).
///
/// Structure-only per the wireframe-not-final-design instruction: no
/// pixel-level tuning, shared theme/components reused as-is.
class LastIntentFollowUpScreen extends StatefulWidget {
  const LastIntentFollowUpScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentFollowUpScreen> createState() => _LastIntentFollowUpScreenState();
}

class _LastIntentFollowUpScreenState extends State<LastIntentFollowUpScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _submitting = false;

  // Same rationale as LastIntentUtteranceScreen: MockSegueRepository
  // resolves near-instantly, so this keeps the loading state visible long
  // enough for a human to actually see it.
  static const Duration _minLoadingDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _answerController.addListener(_handleAnswerChanged);
  }

  void _handleAnswerChanged() => setState(() {});

  @override
  void dispose() {
    _answerController.removeListener(_handleAnswerChanged);
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(LastIntentSessionController session) async {
    final String answer = _answerController.text.trim();
    if (answer.isEmpty) {
      return;
    }
    setState(() => _submitting = true);
    final Stopwatch stopwatch = Stopwatch()..start();
    await session.submitFollowUpAnswer(answer);
    final Duration remaining = _minLoadingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (session.state.intentState.hasData) {
      // push (not pushReplacement) so "수정할게요" from the confirm screen
      // can land back here to revise the follow-up answer.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              LastIntentConfirmScreen(customer: widget.customer, cartItem: widget.cartItem),
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
          final AsyncValue<FollowUpQuestion> followUpState = session.state.followUpState;

          if (followUpState.isLoading || _submitting) {
            return const AppStateView.loading(title: '로딩중...');
          }

          if (followUpState.hasError) {
            return AppStateView.error(
              message: '보충 질문을 불러오지 못했습니다. 다시 시도해 주세요.',
              onAction: () => session.requestFollowUpQuestion(),
            );
          }

          // submitFollowUpAnswer() (unlike the question fetch above) sets
          // intentState, not followUpState — without this check, a failed
          // answer submission silently dumped the CA back to the form with
          // no error shown at all.
          if (session.state.intentState.hasError) {
            return AppStateView.error(
              message: '답변 제출에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _submitAnswer(session),
            );
          }

          final FollowUpQuestion? question = followUpState.data ?? session.state.followUpQuestion;
          if (question == null) {
            return const AppStateView.loading(title: '로딩중...');
          }

          final bool canSubmit = _answerController.text.trim().isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              const Text('Last Intent 상담 · 보충 질문', style: StaffText.title20Bold),
              // AC: "조건을 더 확인해야 합니다" — the mock's actual reason field,
              // not fabricated copy.
              Text(
                session.state.structuredIntent?.followUpReason ?? '조건을 더 확인해야 합니다.',
                style: StaffText.body12,
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    const Text('AI 보충 질문', style: StaffText.meta11),
                    Text(question.question, style: StaffText.header16SemiBold),
                  ],
                ),
              ),
              StaffTextField(label: '고객 답변 입력', controller: _answerController),
              Align(
                alignment: Alignment.centerRight,
                child: StaffButton(
                  label: '답변 제출 후 의도 확인',
                  variant: canSubmit ? StaffButtonVariant.primary : StaffButtonVariant.secondary,
                  onPressed: canSubmit ? () => _submitAnswer(session) : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
