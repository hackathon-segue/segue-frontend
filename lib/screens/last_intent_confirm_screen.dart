import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/product_option_display.dart';
import '../utils/segue_card_tokens.dart';
import '../utils/structured_intent_vocabulary.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';
import 'last_intent_card_screen.dart';
import 'last_intent_edit_screen.dart';

/// Figma node 110:2038 "의도 요약 확인 화면 - 3단계" — reused shell
/// ([SegueCardShell], same family as 89:1559/98:1881), so no
/// header/sidebar/CA-footer markup is built here.
///
/// Business logic unchanged from the previous (StaffAppShell-based) build —
/// see [_confirmAndDecide], none of which changed. Only the widget tree
/// returned by [build] was replaced.
///
/// Reached once [StructuredIntent] is ready — either straight from
/// [LastIntentUtteranceScreen] (no follow-up needed) or after
/// [LastIntentFollowUpScreen]'s answer is submitted, or after returning from
/// [LastIntentEditScreen] with saved edits. Reads the SAME SKU-scoped
/// session (`sessionFor`), so it always reflects exactly the data this
/// SKU's own flow (and any edits) produced — never another SKU's session.
class LastIntentConfirmScreen extends StatefulWidget {
  const LastIntentConfirmScreen({
    required this.customer,
    required this.cartItem,
    super.key,
  });

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentConfirmScreen> createState() =>
      _LastIntentConfirmScreenState();
}

class _LastIntentConfirmScreenState extends State<LastIntentConfirmScreen> {
  bool _deciding = false;

  // MockSegueRepository resolves near-instantly, so without an artificial
  // floor the AI-judgment loading state flashes by too fast to actually
  // see — same rationale as the utterance/follow-up/edit screens.
  static const Duration _minDecidingDuration = Duration(milliseconds: 600);

  Future<void> _confirmAndDecide(LastIntentSessionController session) async {
    if (_deciding) {
      return; // AC: 중복 요청 방지 — 버튼 재클릭 방지.
    }
    setState(() => _deciding = true);
    final Stopwatch stopwatch = Stopwatch()..start();
    // AC: "맞아요"를 누르면 현재(=수정했다면 수정된) StructuredIntent가 그대로
    // decide() 요청에 실린다 — session.state.structuredIntent가 유일한 source of
    // truth이고 LastIntentEditScreen의 저장도 바로 이 값을 갱신하기 때문.
    await session.decide();
    final Duration remaining = _minDecidingDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) {
      return;
    }
    setState(() => _deciding = false);
    if (session.state.decisionResult != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LastIntentCardScreen(
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
      // Figma (110:2038): a literal "3/5" step badge, same convention as
      // every other screen in this flow.
      stepBadge: '3/5',
      screenTitle: '고객 의도 요약 확인',
      subtitle: 'AI가 고객님의 구매 의도 파악을 완료했어요! 내용을 고객님과 함께 확인해 주세요.',
      // Figma: subtitle bottom 227+21=248 → first card top 272 = 24px.
      bodyTopGap: 24,
      body: ListenableBuilder(
        listenable: session,
        builder: (BuildContext context, Widget? _) {
          if (_deciding || session.state.decisionState.isLoading) {
            // No dedicated Figma loading frame for this step — reuses the
            // shared loading treatment, with copy specific to what's
            // actually happening.
            return const AppStateView.loading(title: 'AI가 다음 행동을 판단하고 있습니다');
          }

          if (session.state.decisionState.hasError) {
            return AppStateView.error(
              message: 'Last Intent Card 생성에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _confirmAndDecide(session),
            );
          }

          final StructuredIntent? intent = session.state.structuredIntent;
          if (intent == null) {
            return const AppStateView.empty(title: '구조화된 고객 의도가 아직 없습니다');
          }

          return _SummaryCards(
            intent: intent,
            followUpAnswer: session.state.followUpAnswer,
            cartItem: widget.cartItem,
          );
        },
      ),
      bottomBar: SegueBottomActionRow(
        onBackToStart: () =>
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
        topPadding: 28,
        // Wrap (not a fixed-width Row) so the two buttons can reflow onto
        // their own line instead of overflowing — SegueBottomActionRow's
        // own Wrap doesn't shrink a single wide child to fit, it only
        // wraps between children.
        cta: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          // Figma: "수정할게요" right edge 1071+118=1189 → "맞아요" left
          // 1203 = 14px.
          spacing: 14,
          runSpacing: 12,
          children: <Widget>[
            _EditButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LastIntentEditScreen(
                      customer: widget.customer,
                      cartItem: widget.cartItem,
                    ),
                  ),
                );
              },
            ),
            _ConfirmButton(onPressed: () => _confirmAndDecide(session)),
          ],
        ),
      ),
    );
  }
}

String _conditionsList(Map<String, String> conditions) {
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

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.intent,
    required this.followUpAnswer,
    required this.cartItem,
  });

  final StructuredIntent intent;
  final String followUpAnswer;
  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final String purposeLabel = intent.purpose.isEmpty
        ? '확인 필요'
        : intent.purpose;
    final String urgencyLabel = StructuredIntentVocabulary.purchaseUrgencyLabel(
      intent.purchaseUrgency,
    );
    final bool followedUp = followUpAnswer.isNotEmpty;

    final Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegueInfoCard(
          title: '고객 핵심 조건 요약',
          titleStyle: SegueCardText.sectionHeading20,
          height: 177,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SegueLabelValueRow(
                label: '필수 조건',
                value: _conditionsList(intent.essentialConditions),
                bottomSpacing: 0,
              ),
              // Figma shows a single combined "구매 상황" row — no such field
              // exists on StructuredIntent by itself, so this composes it
              // from the two real fields the right-hand card also uses
              // (purpose + purchaseUrgency), rather than inventing new data.
              SegueLabelValueRow(
                label: '구매 상황',
                value: '$purposeLabel · $urgencyLabel',
                bottomSpacing: 0,
              ),
              // No priority/ranking field exists anywhere in the model —
              // shown as "확인 필요" (this app's existing empty-data
              // convention) rather than hardcoding Figma's example ranking.
              const SegueLabelValueRow(
                label: '중요도 순위',
                value: '확인 필요',
                bottomSpacing: 0,
              ),
              SegueLabelValueRow(
                label: '보충 답변',
                value: followedUp ? followUpAnswer : '없음',
                bottomSpacing: 0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const SegueInfoCard(
          title: '의도 정리 근거',
          titleStyle: SegueCardText.sectionHeading20,
          height: 155,
          // StructuredIntent has no reasoning/explanation field of its own
          // (only DecisionResult.reason does, and that doesn't exist until
          // AFTER this screen's "맞아요" triggers decide()) — shown as an
          // honest placeholder instead of hardcoding Figma's example
          // sentences as if they were real AI output.
          child: Text(
            'AI 판단 근거 요약은 다음 단계(Last Intent 결과) 이후에 제공됩니다.',
            style: SegueCardText.body18,
          ),
        ),
        const SizedBox(height: 10),
        SegueInfoCard(
          title: '추가 상담 필요 조건',
          titleStyle: SegueCardText.sectionHeading20,
          height: 127,
          child: Text(
            intent.needsFollowUp && intent.followUpReason.isNotEmpty
                ? intent.followUpReason
                : '추가로 확인이 필요한 조건이 없습니다.',
            style: SegueCardText.body18,
          ),
        ),
      ],
    );

    final Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegueInfoCard(
          title: '상세 구매 상황',
          titleStyle: SegueCardText.sectionHeading20,
          height: 126,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SegueLabelValueRow(
                      label: '사용 목적',
                      value: purposeLabel,
                      bottomSpacing: 0,
                    ),
                    SegueLabelValueRow(
                      label: '구매 시급성',
                      value: urgencyLabel,
                      bottomSpacing: 0,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // No budget field exists anywhere in the model — always
                    // "확인 필요", matching this app's existing empty-data
                    // convention rather than a fabricated range.
                    const SegueLabelValueRow(
                      label: '예산 범위',
                      value: '확인 필요',
                      bottomSpacing: 0,
                    ),
                    SegueLabelValueRow(
                      label: '보충 질문 여부',
                      value: followedUp ? '1회 완료' : '없음',
                      bottomSpacing: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SegueInfoCard(
          title: '쇼핑백 품목',
          titleStyle: SegueCardText.sectionHeading20,
          height: 249,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ProductImage(imageUrl: cartItem.imageUrl),
              // Figma: image right edge 21+165=186 → product text left
              // 204 = 18px.
              const SizedBox(width: 18),
              Expanded(child: _ProductSummaryText(cartItem: cartItem)),
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Figma's two 549px columns (+17px gap) need ~1115px — below that,
        // this app's own responsive fallback stacks them instead of
        // forcing a horizontal overflow (no narrower Figma variant exists).
        if (constraints.maxWidth < 950) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              leftColumn,
              const SizedBox(height: 10),
              rightColumn,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: leftColumn),
            const SizedBox(width: 17),
            Expanded(child: rightColumn),
          ],
        );
      },
    );
  }
}

/// Figma (110:2038)'s "image 14" product photo, sized to spec (165×179) —
/// this screen's cart item is always the SKU the CA started the Last
/// Intent flow with, so its real backend `imageUrl` renders here (falling
/// back to the usual gray "Image" placeholder if it's missing/fails to
/// load, same as every other product photo in the app).
class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SegueProductImage(imageUrl: imageUrl, width: 165, height: 179);
  }
}

/// Product name/color/size (110:2038) — the Latin brand-word run (e.g.
/// "MCM") uses Montserrat SemiBold, the rest Pretendard Bold, matching
/// Figma's "Diamond" run split. Real [CartItem.color]/[CartItem.size] are
/// Korean wire values, so this screen uses the same display-only English
/// option mapping as the cart row (e.g. 블랙/미디움 -> BLACK/M).
class _ProductSummaryText extends StatelessWidget {
  const _ProductSummaryText({required this.cartItem});

  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final String name = cartItem.productName;
    final int spaceIndex = name.indexOf(' ');
    final Widget nameText = spaceIndex == -1
        ? Text(name, style: SegueCardText.itemSummaryName18)
        : Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: name.substring(0, spaceIndex),
                  style: SegueCardText.itemSummaryNameLatin18,
                ),
                TextSpan(
                  text: name.substring(spaceIndex),
                  style: SegueCardText.itemSummaryName18,
                ),
              ],
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        nameText,
        Text(
          displayProductColor(cartItem.color),
          style: SegueCardText.itemSummaryName18,
        ),
        Text(
          displayProductSize(cartItem.size),
          style: SegueCardText.itemSummaryName18,
        ),
      ],
    );
  }
}

/// Figma (110:2109/2110)'s "수정할게요" Continue Button — fixed 118×43,
/// white bg, 1px #222 border, no corner radius, centered ink 18px label.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 118,
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
                  '수정할게요',
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

/// Figma (110:2079/2080/2081)'s "맞아요, 다음 단계로" Continue Button — fixed
/// 198×43, bg #222, no corner radius, centered white 18px label + arrow.
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SegueCardColors.ctaBg,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 198,
          height: 43,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Flexible(
                child: Text(
                  '맞아요, 다음 단계로',
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
