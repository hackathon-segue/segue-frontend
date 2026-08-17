import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/staff_design_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/staff_app_shell.dart';
import '../widgets/staff_button.dart';
import '../widgets/staff_text_field.dart';
import 'last_intent_confirm_screen.dart';
import 'last_intent_follow_up_screen.dart';

/// Issue #10 "고객 의도 입력과 구조화 mock 응답 흐름".
///
/// Reached from [LastIntentIntroScreen]'s "고객 의도 입력 시작" button. Reuses
/// the SKU-scoped [LastIntentSessionController] already started by Issue #9's
/// [LastIntentSessionManager] — no separate consultation-target state is
/// created here, so this SKU's structured intent can never leak into another
/// SKU's session.
///
/// One screen for input/loading/error; on success it navigates straight to
/// [LastIntentFollowUpScreen] or [LastIntentConfirmScreen] depending on
/// `needsFollowUp`, per Issue #10's instruction to connect to the next step
/// without pixel-perfecting it.
///
/// The input form is always the default view — this screen never renders a
/// persisted "analysis complete" state from `session.state.intentState`.
/// That state survives long after the CA has moved on (e.g. to the confirm
/// screen), so branching render on it meant navigating back here (e.g. via
/// "수정할게요") showed a stale "완료되었습니다" screen instead of an editable
/// field. Loading is instead driven by a local [_analyzing] flag scoped to
/// exactly one submit attempt.
class LastIntentUtteranceScreen extends StatefulWidget {
  const LastIntentUtteranceScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentUtteranceScreen> createState() => _LastIntentUtteranceScreenState();
}

class _LastIntentUtteranceScreenState extends State<LastIntentUtteranceScreen> {
  final TextEditingController _utteranceController = TextEditingController();
  bool _seeded = false;
  bool _analyzing = false;

  // MockSegueRepository resolves near-instantly, so without an artificial
  // floor the loading state can flash by too fast for a human to register —
  // this only affects local perceived timing, not the mock response itself.
  static const Duration _minLoadingDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    // Re-evaluates canSubmit on every keystroke so the submit button's
    // enabled/disabled styling stays in sync as the CA types.
    _utteranceController.addListener(_handleUtteranceChanged);
  }

  void _handleUtteranceChanged() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the field once from whatever this SKU's own session already has
    // saved (e.g. coming back to a session started earlier) — never from a
    // different SKU's session. Done here (not in build()) because mutating
    // the controller synchronously notifies its listener, and doing that
    // while build() is still in progress trips a
    // "setState called during build" error.
    if (!_seeded) {
      final LastIntentSessionController session = LastIntentSessionScope.of(
        context,
      ).sessionFor(customer: widget.customer, cartItem: widget.cartItem);
      if (session.state.utterance.isNotEmpty) {
        _utteranceController.text = session.state.utterance;
      }
      _seeded = true;
    }
  }

  @override
  void dispose() {
    _utteranceController.removeListener(_handleUtteranceChanged);
    _utteranceController.dispose();
    super.dispose();
  }

  Future<void> _submit(LastIntentSessionController session) async {
    final String utterance = _utteranceController.text.trim();
    if (utterance.isEmpty) {
      return;
    }
    setState(() => _analyzing = true);
    final Stopwatch stopwatch = Stopwatch()..start();
    await session.structureIntent(utterance);
    final Duration remaining = _minLoadingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    setState(() => _analyzing = false);
    final StructureIntentResponse? data = session.state.intentState.data;
    if (data != null) {
      // Issue #11 AC: "보충 질문은 최대 1회만 표시된다" — once this SKU's
      // session has already completed one follow-up round, never route
      // back into it again even if a fresh structureIntent() call reports
      // needsFollowUp: true (e.g. after revising the utterance).
      final bool alreadyFollowedUp = session.state.followUpAnswer.isNotEmpty;
      _goToNextStep(needsFollowUp: data.needsFollowUp && !alreadyFollowedUp);
    }
    // On error, intentState.hasError is now true and _analyzing is false,
    // so build() falls into the error/retry branch below.
  }

  void _goToNextStep({required bool needsFollowUp}) {
    if (needsFollowUp) {
      // Fired here (button handler), not inside LastIntentFollowUpScreen's
      // own mount — notifyListeners() while ANOTHER screen is mid-build/
      // mid-mount (this screen's ListenableBuilder is still attached, since
      // push() keeps it in the tree) trips a "setState during build" error.
      LastIntentSessionScope.of(
        context,
      ).sessionFor(customer: widget.customer, cartItem: widget.cartItem).requestFollowUpQuestion();
    }
    // push (not pushReplacement) so "수정할게요"/뒤로가기 from the next screen
    // lands back here with the already-submitted utterance still visible.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => needsFollowUp
            ? LastIntentFollowUpScreen(customer: widget.customer, cartItem: widget.cartItem)
            : LastIntentConfirmScreen(customer: widget.customer, cartItem: widget.cartItem),
      ),
    );
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
          if (_analyzing) {
            // Real loading design isn't ready yet — kept deliberately bare
            // (just enough to confirm a loading state exists) so it's a
            // one-line swap once the design lands.
            return const AppStateView.loading(title: '로딩중...');
          }

          if (session.state.intentState.hasError) {
            return AppStateView.error(
              message: '고객 의도 분석에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _submit(session),
            );
          }

          final bool canSubmit = _utteranceController.text.trim().isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              const Text('고객 의도 입력', style: StaffText.title20Bold),
              const Text('이 제품에서 절대 놓치고 싶지 않은 점은 무엇인가요?', style: StaffText.header16SemiBold),
              StaffTextField(label: '고객 발화', controller: _utteranceController),
              StaffButton(
                label: '상담 시작으로 돌아가기',
                variant: StaffButtonVariant.link,
                onPressed: () => Navigator.of(context).pop(),
              ),
              // AC: 입력값이 비어 있을 때 제출 불가 / 있을 때 활성화 — Issue #7's
              // consent-gate button already establishes secondary→primary as
              // this app's disabled→enabled styling, reused here as-is.
              Align(
                alignment: Alignment.centerRight,
                child: StaffButton(
                  label: '제출',
                  variant: canSubmit ? StaffButtonVariant.primary : StaffButtonVariant.secondary,
                  onPressed: canSubmit ? () => _submit(session) : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
