import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import 'last_intent_confirm_screen.dart';
import 'last_intent_follow_up_screen.dart';

/// Figma node 98:1881 "고객 의도 입력 화면 - 2단계" — reused shell
/// ([SegueCardShell], same family as 89:1559/98:1933), so no
/// header/sidebar/CA-footer markup is built here.
///
/// Business logic unchanged from the previous (StaffAppShell-based) build —
/// see the state fields/methods below, none of which changed. Only the
/// widget tree returned by [build] was replaced.
///
/// Reached from [LastIntentIntroScreen]'s "고객 의도 입력 시작" button. Reuses
/// the SKU-scoped [LastIntentSessionController] already started by
/// [LastIntentSessionManager] — no separate consultation-target state is
/// created here, so this SKU's structured intent can never leak into another
/// SKU's session.
///
/// One screen for input/loading/error; on success it navigates straight to
/// [LastIntentFollowUpScreen] or [LastIntentConfirmScreen] depending on
/// `needsFollowUp`.
///
/// The input form is always the default view — this screen never renders a
/// persisted "analysis complete" state from `session.state.intentState`.
/// That state survives long after the CA has moved on (e.g. to the confirm
/// screen), so branching render on it meant navigating back here (e.g. via
/// "수정할게요") showed a stale "완료되었습니다" screen instead of an editable
/// field. Loading is instead driven by a local [_analyzing] flag scoped to
/// exactly one submit attempt.
class LastIntentUtteranceScreen extends StatefulWidget {
  const LastIntentUtteranceScreen({
    required this.customer,
    required this.cartItem,
    super.key,
  });

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentUtteranceScreen> createState() =>
      _LastIntentUtteranceScreenState();
}

class _LastIntentUtteranceScreenState extends State<LastIntentUtteranceScreen> {
  final TextEditingController _utteranceController = TextEditingController();
  bool _seeded = false;
  bool _analyzing = false;

  /// True right after the CA dismisses an error card via "뒤로가기" — lets
  /// build() show [_UtteranceInput] again (with the previously typed text
  /// still intact) even though `session.state.intentState` still holds the
  /// stale error, so they can revise the wording instead of being stuck
  /// staring at an error card with no way back to the text field. Reset on
  /// every new [_submit] call so a fresh failure shows its own error again.
  bool _dismissedError = false;

  // MockSegueRepository resolves near-instantly, so without an artificial
  // floor the loading state can flash by too fast for a human to register —
  // this only affects local perceived timing, not the mock response itself.
  static const Duration _minLoadingDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    // Re-evaluates canSubmit on every keystroke so the submit button's
    // enabled/disabled state stays in sync as the CA types.
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
    setState(() {
      _analyzing = true;
      _dismissedError = false;
    });
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
      LastIntentSessionScope.of(context)
          .sessionFor(customer: widget.customer, cartItem: widget.cartItem)
          .requestFollowUpQuestion();
    }
    // push (not pushReplacement) so "수정할게요"/뒤로가기 from the next screen
    // lands back here with the already-submitted utterance still visible.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => needsFollowUp
            ? LastIntentFollowUpScreen(
                customer: widget.customer,
                cartItem: widget.cartItem,
              )
            : LastIntentConfirmScreen(
                customer: widget.customer,
                cartItem: widget.cartItem,
              ),
      ),
    );
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
      // Figma (98:1881): a literal "2/5" step badge, same convention as
      // every other screen in this flow.
      stepBadge: '2/5',
      screenTitle: '고객 의도 입력',
      subtitle: '고객이 이 제품을 선택한 이유를 파악하기 위한 질문을 진행합니다. 질문을 한 뒤에 고객 답변을 입력해 주세요.',
      // Figma: subtitle bottom 227+21=248 → Details Container top 266 = 18px.
      bodyTopGap: 18,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          if (_analyzing) {
            // Real loading design isn't ready yet — kept deliberately bare
            // (just enough to confirm a loading state exists) so it's a
            // one-line swap once the design lands.
            return const AppStateView.loading(title: '로딩중...');
          }

          if (!_dismissedError && session.state.intentState.hasError) {
            return AppStateView.error(
              message: '고객 의도 분석에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _submit(session),
              secondaryActionLabel: '뒤로가기',
              onSecondaryAction: () =>
                  setState(() => _dismissedError = true),
            );
          }

          return _UtteranceInput(controller: _utteranceController);
        },
      ),
      bottomBar: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          final bool canSubmit = _utteranceController.text.trim().isNotEmpty;
          return SegueBottomActionRow(
            onBackToStart: () => Navigator.of(context).pop(),
            cta: _StructureIntentButton(
              onPressed: (!_analyzing && canSubmit)
                  ? () => _submit(session)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// Figma (98:1919): 1112×326 white box, 2px #DBDCE0 border, square corners,
/// filling with a large multi-line input — no default rounded
/// OutlineInputBorder/underline, no elevation, no floating label.
class _UtteranceInput extends StatelessWidget {
  const _UtteranceInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // Figma's 1112px is this shell's exact content width at the 1440x900
    // baseline (1440 - 265 sidebar - 31*2 padding = 1113) — double.infinity
    // reproduces that exactly at baseline while avoiding overflow at
    // narrower viewports, matching every other fixed-width Details
    // Container in this flow (98:1933/89:1559).
    return Container(
      width: double.infinity,
      height: 326,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SegueCardColors.border, width: 2),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        // Figma only specifies the empty-state placeholder style; no typed
        // text style is shown, so this reuses an existing 16px body token
        // rather than inventing an unverified new one.
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
          contentPadding: EdgeInsets.fromLTRB(18, 16, 18, 16),
          hintText: '고객 답변 입력하기',
          hintStyle: SegueCardText.inputPlaceholder14,
        ),
      ),
    );
  }
}

/// Figma (98:1922/1923/1924)'s "고객 의도 구조화하기" Continue Button — fixed
/// 201×43, bg #222, no corner radius, centered white 18px label + a
/// ~17×18 arrow icon. Not [SegueCtaButton] (auto-width, 24px symmetric
/// padding) since Figma's own padding here isn't symmetric (13px left of
/// text, 11px right of icon) and the width is a fixed, content-independent
/// UI constant (the label never varies with real data), so hardcoding the
/// exact box is safe and matches Figma precisely rather than approximating.
class _StructureIntentButton extends StatelessWidget {
  const _StructureIntentButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SegueCardColors.ctaBg,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 201,
          height: 43,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Flexible(
                child: Text(
                  '고객 의도 구조화하기',
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
