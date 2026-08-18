import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import 'last_intent_confirm_screen.dart';

/// Figma node 98:1981 "보충 질문 제시 화면 - 2단계" — reused shell
/// ([SegueCardShell], same family as 89:1559/98:1881), so no
/// header/sidebar/CA-footer markup is built here.
///
/// Business logic unchanged from the previous (StaffAppShell-based) build —
/// see [_submitAnswer], none of which changed. Only the widget tree
/// returned by [build] was replaced.
///
/// Reached when [LastIntentUtteranceScreen] gets `needsFollowUp: true` back
/// from the mock adapter AND this SKU's session hasn't already completed a
/// follow-up round (AC: "보충 질문은 최대 1회만 표시된다"). Reuses the same
/// SKU-scoped [LastIntentSessionController] (`sessionFor`) — no new
/// consultation-target state — and its existing `requestFollowUpQuestion` /
/// `submitFollowUpAnswer` methods.
class LastIntentFollowUpScreen extends StatefulWidget {
  const LastIntentFollowUpScreen({
    required this.customer,
    required this.cartItem,
    super.key,
  });

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentFollowUpScreen> createState() =>
      _LastIntentFollowUpScreenState();
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
          builder: (_) => LastIntentConfirmScreen(
            customer: widget.customer,
            cartItem: widget.cartItem,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);
    final LastIntentSessionController session = manager.sessionFor(
      customer: widget.customer,
      cartItem: widget.cartItem,
    );

    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: manager.activeCount,
      // Figma (98:1981): a literal "2/5" step badge — the follow-up
      // question is a sub-step of step 2, same convention as every other
      // screen in this flow.
      stepBadge: '2/5',
      screenTitle: '고객 의도 입력 - 보충 질문',
      subtitle:
          '고객의 핵심 구매 조건 중 일부가 명확하지 않아 정확한 다음 행동을 판단하기 어렵습니다. 아래 보충 질문을 고객에게 확인해 주세요.',
      // Figma: subtitle bottom 227+21=248 → question box top 266 = 18px.
      bodyTopGap: 18,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          final AsyncValue<FollowUpQuestion> followUpState =
              session.state.followUpState;

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

          final FollowUpQuestion? question =
              followUpState.data ?? session.state.followUpQuestion;
          if (question == null) {
            return const AppStateView.loading(title: '로딩중...');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Figma (110:2029): 1112×68 box, 2px #DBDCE0 border, square
              // corners — the real followUpQuestion.question string, never
              // Figma's example sentence.
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.fromLTRB(19, 20, 19, 20),
                decoration: BoxDecoration(
                  border: Border.all(color: SegueCardColors.border, width: 2),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  question.question,
                  style: SegueCardText.followUpQuestion20,
                ),
              ),
              // Figma: question box bottom 266+68=334 → answer box top
              // 353 = 19px.
              const SizedBox(height: 19),
              _AnswerInput(controller: _answerController),
            ],
          );
        },
      ),
      bottomBar: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          final bool canSubmit = _answerController.text.trim().isNotEmpty;
          return SegueBottomActionRow(
            onBackToStart: () =>
                Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
            // Wrap (not a fixed-width Row) so the two buttons can reflow
            // onto their own line instead of overflowing on narrow
            // viewports — SegueBottomActionRow's own Wrap doesn't shrink a
            // single wide child to fit, it only wraps between children.
            cta: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              // Figma: "이전으로 돌아가기" right edge 1014+159=1173 → "답변
              // 제출 후 의도 확인" left 1186 = 13px.
              spacing: 13,
              runSpacing: 12,
              children: <Widget>[
                _PreviousStepButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
                _SubmitAnswerButton(
                  onPressed: (!_submitting && canSubmit)
                      ? () => _submitAnswer(session)
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Figma (98:2018)'s answer input — 1112×239 white box, 2px #DBDCE0 border,
/// square corners, filling with a large multi-line input — no default
/// rounded OutlineInputBorder/underline, no elevation, no floating label.
class _AnswerInput extends StatelessWidget {
  const _AnswerInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // Figma's 1112px is this shell's exact content width at the 1440x900
    // baseline (1440 - 265 sidebar - 31*2 padding = 1113) — double.infinity
    // reproduces that exactly at baseline while avoiding overflow at
    // narrower viewports, matching every other fixed-width Details
    // Container in this flow.
    return Container(
      width: double.infinity,
      height: 239,
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
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.fromLTRB(18, 19, 18, 19),
          hintText: '고객 답변 입력하기',
          hintStyle: SegueCardText.inputPlaceholder14,
        ),
      ),
    );
  }
}

/// Figma (98:2022/2023)'s "이전으로 돌아가기" Continue Button — fixed 159×43,
/// white bg, 1px #222 border, no corner radius, centered ink 18px label.
class _PreviousStepButton extends StatelessWidget {
  const _PreviousStepButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 159,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: SegueCardColors.ink),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  '이전으로 돌아가기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SegueCardColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma (98:2019/2020/2021)'s "답변 제출 후 의도 확인" Continue Button — fixed
/// 215×43, bg #222, no corner radius, centered white 18px label + arrow.
class _SubmitAnswerButton extends StatelessWidget {
  const _SubmitAnswerButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SegueCardColors.ctaBg,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 215,
          height: 43,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Flexible(
                child: Text(
                  '답변 제출 후 의도 확인',
                  style: SegueCardText.ctaLabel18White,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              Transform.rotate(
                angle: 1.5707963267948966, // pi/2
                child: SizedBox(
                  width: 17,
                  height: 18,
                  child: SvgPicture.asset(
                    'assets/icons/nav_active_arrow.svg',
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
