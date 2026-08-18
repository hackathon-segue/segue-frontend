import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_image_placeholder.dart';
import 'last_intent_confirm_screen.dart';

/// Figma node 14:1417 "보충 질문 제시 화면" (final design — matched pixel-exact,
/// not structural-only like Issue #9/#10's screens).
///
/// Reached when Issue #10's [LastIntentUtteranceScreen] gets
/// `needsFollowUp: true` back from the mock adapter AND this SKU's session
/// hasn't already completed a follow-up round (see that screen's
/// `_goToNextStep` — Issue #11 AC: "보충 질문은 최대 1회만 표시된다"). Reuses the
/// same SKU-scoped [LastIntentSessionController] (`sessionFor`) — no new
/// consultation-target state — and its existing `requestFollowUpQuestion` /
/// `submitFollowUpAnswer` methods (already built in Issue #7/#8).
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
    final int cartItemCount =
        StaffSessionScope.of(context).state.cartState.data?.length ?? 0;

    return StaffAppShell(
      currentRoute: AppRoutes.lastIntentIntro,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          final AsyncValue<FollowUpQuestion> followUpState = session.state.followUpState;

          if (followUpState.isLoading || _submitting) {
            // No dedicated loading frame exists for this step in Figma —
            // reuses this app's one shared bare loading treatment.
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
            spacing: 24,
            children: <Widget>[
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  Text('Last Intent 상담', style: StaffText.header16SemiBold),
                  Text('보충 질문', style: StaffText.body12),
                ],
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 20,
                  children: <Widget>[
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: <Widget>[
                        Text('상담 단계', style: StaffText.meta11),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            _StageChip(label: '고객 조회'),
                            _StageChip(label: '의도 입력'),
                            _StageChip(label: '보충 질문', active: true),
                            _StageChip(label: '의도 확인'),
                            _StageChip(label: '결과 확인'),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: <Widget>[
                        const Text('현재 상담 고객', style: StaffText.meta11),
                        Row(
                          spacing: 12,
                          children: <Widget>[
                            const StaffImagePlaceholder.avatar(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: <Widget>[
                                Text(widget.customer.name, style: StaffText.body12),
                                Text('장바구니 $cartItemCount개 항목', style: StaffText.meta11),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 20,
                  children: <Widget>[
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: <Widget>[
                        Text('AI 분석 결과', style: StaffText.meta11),
                        Text('조건을 더 확인해야 합니다', style: StaffText.header16SemiBold),
                        Text(
                          '고객의 핵심 구매 조건 중 일부가 명확하지 않아 정확한 다음 행동을 판단하기 어렵습니다. '
                          '아래 보충 질문을 고객에게 확인해 주세요.',
                          style: StaffText.body12,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: <Widget>[
                        const Text('보충 질문', style: StaffText.meta11),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: <Widget>[
                              const Text('AI 보충 질문', style: StaffText.meta11),
                              // AC: 질문 문구는 adapter 응답의 question 값을 그대로
                              // 표시 — 프론트에서 하드코딩하지 않는다.
                              Text(question.question, style: StaffText.header16SemiBold),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: <Widget>[
                        const Text('고객 답변 입력', style: StaffText.meta11),
                        _AnswerTextArea(
                          controller: _answerController,
                          hintText: '고객이 답변한 내용을 그대로 입력해 주세요',
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: StaffButton(
                            label: '답변 제출 후 의도 확인',
                            variant: canSubmit
                                ? StaffButtonVariant.primary
                                : StaffButtonVariant.secondary,
                            onPressed: canSubmit ? () => _submitAnswer(session) : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Figma's "상담 단계" stepper chip: non-active stages render as the shared
/// pill/chip look; the current stage renders as plain bold text with no
/// background (node 14:1452's "default-active" Button variant).
class _StageChip extends StatelessWidget {
  const _StageChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Text(
        label,
        style: StaffText.buttonSecondary14.copyWith(fontWeight: FontWeight.bold),
      );
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: StaffColors.chipBg,
        border: Border.all(color: StaffColors.cardBorder),
        borderRadius: BorderRadius.circular(StaffRadii.chip),
      ),
      child: Text(label, style: StaffText.buttonSecondary14),
    );
  }
}

/// Figma's Input "area" variant (node 14:1485's `inputType="area"`): same
/// box styling as [StaffTextField] but taller/multiline, with the sample
/// copy shown as a real placeholder rather than a permanent label.
class _AnswerTextArea extends StatelessWidget {
  const _AnswerTextArea({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: null,
      minLines: 3,
      style: StaffText.body14,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        constraints: const BoxConstraints(minHeight: 80),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        hintText: hintText,
        hintStyle: StaffText.placeholder14,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StaffRadii.input),
          borderSide: const BorderSide(color: StaffColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StaffRadii.input),
          borderSide: const BorderSide(color: StaffColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(StaffRadii.input),
          borderSide: const BorderSide(color: StaffColors.ink, width: 1.5),
        ),
      ),
    );
  }
}
