import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/product_option_display.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';
import 'last_intent_completion_screen.dart';

/// Shared implementation for Figma nodes 159:2295 (EXACT_PRODUCT),
/// 159:2173 (COMPARISON_EXPERIENCE), and 159:3053 (TODAY_PURCHASE) — all
/// three are structurally identical (`get_design_context` on each returns
/// the same product-box + 3-card + CTA layout, only labels/content differ),
/// so one widget branches internally on `resultType` instead of three
/// near-duplicate screens.
///
/// This is where `execute()` now actually runs (Issue #46 moved it off the
/// Card screen, which only navigates here) — same loading/error/retry
/// handling [LastIntentCardScreen] used to own.
///
/// The CTA's displayed label is a Figma-literal override (per explicit
/// request), not `result.actionButtonLabel` directly — API.md's documented
/// value is "타 매장 확인 요청"/"이 제품 확인하기", but confirmed Figma
/// (159:2295/159:2173/159:3053) shows "...접수"/"해당 제품 상담 완료" instead.
/// `execute()` itself still sends the real `actionType`/`actionButtonLabel`
/// from `decisionResult` — only the on-screen text changes, not the
/// request payload.
String _figmaCtaLabel(DecisionResult result) {
  return switch (result.actionType) {
    DecisionActionType.otherStoreCheckRequest => '타 매장 확인 요청 접수',
    DecisionActionType.restockCheckRequest => result.actionButtonLabel,
    DecisionActionType.productCheckRequest => '해당 제품 상담 완료',
    DecisionActionType.reconsult => result.actionButtonLabel,
  };
}

class LastIntentResultProductScreen extends StatefulWidget {
  const LastIntentResultProductScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  @override
  State<LastIntentResultProductScreen> createState() => _LastIntentResultProductScreenState();
}

class _LastIntentResultProductScreenState extends State<LastIntentResultProductScreen> {
  bool _executing = false;

  // MockSegueRepository resolves near-instantly, so without an artificial
  // floor the loading state would flash by too fast to see.
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
      return; // AC: CTA/재시도 중복 클릭·중복 요청 금지.
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
      // "해당 제품 상담 완료" (COMPARISON_EXPERIENCE/TODAY_PURCHASE's
      // productCheckRequest CTA) skips the "요청 접수 완료" hand-off screen and
      // returns straight to the cart — that screen's row already reflects
      // this SKU's session via LastIntentSessionManager.isCompleted(), which
      // just flipped true because executionResponse is now set. Every other
      // actionType keeps going to the completion screen.
      if (session.state.decisionResult?.actionType == DecisionActionType.productCheckRequest) {
        Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.cartInventory));
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LastIntentCompletionScreen(customer: widget.customer, cartItem: widget.cartItem),
          ),
        );
      }
    }
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
        if (result == null) {
          return const _ResultScaffold(
            step: '5/5',
            title: '',
            subtitle: '',
            child: Text('생성된 결과가 없습니다.', style: SegueCardText.body18),
          );
        }

        final _ResultTypeConfig config = _ResultTypeConfig.of(result, widget.cartItem);

        if (_executing || session.state.executionState.isLoading) {
          return _ResultScaffold(
            step: '5/5',
            title: config.title,
            subtitle: config.subtitle,
            child: AppStateView.loading(
              title: session.state.executionState.isLoading ? '요청을 접수하고 있습니다' : '상담 결과를 저장하고 있습니다',
            ),
          );
        }

        if (session.state.executionState.hasError) {
          return _ResultScaffold(
            step: '5/5',
            title: config.title,
            subtitle: config.subtitle,
            child: AppStateView.error(
              message: '요청 접수에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleExecute(session),
            ),
          );
        }

        if (session.state.resultSaveState.hasError) {
          return _ResultScaffold(
            step: '5/5',
            title: config.title,
            subtitle: config.subtitle,
            child: AppStateView.error(
              message: '상담 결과 저장에 실패했습니다. 다시 시도해 주세요.',
              onAction: () => _handleRetrySave(session),
            ),
          );
        }

        return _ResultScaffold(
          step: '5/5',
          title: config.title,
          subtitle: config.subtitle,
          onCta: () => _handleExecute(session),
          ctaLabel: _figmaCtaLabel(result),
          // Figma (159:2213/169:4101): the "해당 제품 상담 완료" button has no
          // trailing arrow, unlike every other Continue Button in this flow.
          ctaShowArrow: result.actionType != DecisionActionType.productCheckRequest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    // Figma (159:2295): fixed 295px card — real dynamic
                    // `nextAction` text can be longer than the example
                    // copy, so this scrolls internally (matching every
                    // other fixed-height card below) instead of forcing
                    // the whole page to grow/scroll.
                    height: 295,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(border: Border.all(color: SegueCardColors.border, width: 2)),
                    child: SingleChildScrollView(
                      child: _ProductRow(
                        imageUrl: config.imageUrl,
                        productName: config.productName,
                        color: config.color,
                        size: config.size,
                        description: result.nextAction,
                      ),
                    ),
                  ),
                  // Figma (159:2295/Rectangle 10): pinned to the card's own
                  // top-right corner (18px from top, 16px from right) — not
                  // flowing inline with the product details column.
                  Positioned(
                    top: 18,
                    right: 16,
                    child: Container(
                      width: 108,
                      height: 39,
                      alignment: Alignment.center,
                      color: SegueCardColors.chipBg,
                      child: Text(config.chipLabel, style: SegueCardText.chipLabel16White),
                    ),
                  ),
                ],
              ),
              // Figma measures a 23px gap here (product box bottom 571 →
              // 3-card row top 594), but the page needs every spare pixel
              // to avoid the whole body needing to scroll at the 900px
              // baseline — 13px of that gap is traded directly into the
              // card row's own height below (23→10, 177→190), so the
              // row's bottom edge (and everything positioned after it:
              // the CTA row, "처음으로 돌아가기") lands exactly where it did
              // before. Nothing below this point moved.
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // See the gap comment above — 177+13=190, so cards get
                  // more real breathing room (less likely to need their
                  // own internal scroll for typical content) without
                  // changing the total space this row+gap occupies.
                  const double cardHeight = 190;
                  final List<Widget> cards = <Widget>[
                    SegueInfoCard(
                      title: '고객 핵심 조건',
                      height: cardHeight,
                      child: Text(result.coreConditions, style: SegueCardText.body18),
                    ),
                    SegueInfoCard(
                      title: config.card2Label,
                      height: cardHeight,
                      child: config.card2Content,
                    ),
                    SegueInfoCard(
                      title: '선정 근거',
                      height: cardHeight,
                      child: Text(result.reason, style: SegueCardText.body18),
                    ),
                  ];
                  // Figma: card widths 350 with 27px gaps (0, 377, 754).
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (int i = 0; i < cards.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: 27),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: <Widget>[
                      for (final Widget c in cards) ...<Widget>[c, const SizedBox(height: 16)],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultScaffold extends StatelessWidget {
  const _ResultScaffold({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    this.ctaLabel,
    this.onCta,
    this.ctaShowArrow = true,
  });

  final String step;
  final String title;
  final String subtitle;
  final Widget child;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool ctaShowArrow;

  @override
  Widget build(BuildContext context) {
    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: LastIntentSessionScope.of(context).activeCount,
      stepBadge: step,
      screenTitle: title,
      subtitle: subtitle,
      body: child,
      bottomBar: SegueBottomActionRow(
        onBackToStart: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
        cta: ctaLabel != null
            ? SegueCtaButton(label: ctaLabel!, onPressed: onCta, showArrow: ctaShowArrow)
            : null,
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.imageUrl,
    required this.productName,
    required this.color,
    required this.size,
    required this.description,
  });

  final String imageUrl;
  final String productName;
  final String color;
  final String size;
  final String description;

  @override
  Widget build(BuildContext context) {
    final int spaceIndex = productName.indexOf(' ');
    final Widget nameText = spaceIndex == -1
        ? Text(productName, style: SegueCardText.productName30)
        : Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: productName.substring(0, spaceIndex),
                  style: SegueCardText.productNameLatin30,
                ),
                TextSpan(
                  text: productName.substring(spaceIndex),
                  style: SegueCardText.productName30,
                ),
              ],
            ),
          );
    // Figma positions the description relative to the CARD (top 494), not
    // chained after the image's own 256px height — real data only ever
    // fills 2 of the meta block's 3 example lines (no price field), so
    // this is derived from the real 2-line meta bottom (366+48=414) up to
    // the description top (494) = 80px, not Figma's 3-line-example gap.
    // Folding description into `details` (instead of positioning it below
    // the whole image+details Row) keeps the card's total height pinned
    // to the image's 256px regardless of description length, matching
    // Figma's compact ~295px card instead of growing past it.
    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        nameText,
        // Figma: name bottom 296+43=339 → details top 366 = 27px.
        const SizedBox(height: 27),
        Text(color, style: SegueCardText.productMeta20),
        Text(size, style: SegueCardText.productMeta20),
        const SizedBox(height: 80),
        Text(description, style: SegueCardText.body18),
      ],
    );

    // Figma's fixed 237px-wide image doesn't fit alongside the details
    // column below ~360px of available width (narrow tablet portrait) —
    // stack the image above instead of forcing a horizontal overflow.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SegueProductImage(imageUrl: imageUrl),
              const SizedBox(height: 21),
              details,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Figma (159:2295): image 314,295 237x256 — the box's actual
            // product photo size, not a small thumbnail.
            SegueProductImage(imageUrl: imageUrl),
            // Figma: image right edge 314+237=551 → name left 572 = 21px.
            const SizedBox(width: 21),
            Expanded(child: details),
          ],
        );
      },
    );
  }
}

/// Every per-`resultType` difference between the 3 shared frames, computed
/// once from real session/product data — never Figma's example copy.
class _ResultTypeConfig {
  const _ResultTypeConfig({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.productName,
    required this.color,
    required this.size,
    required this.chipLabel,
    required this.card2Label,
    required this.card2Content,
  });

  factory _ResultTypeConfig.of(DecisionResult result, CartItem cartItem) {
    switch (result.resultType) {
      case DecisionResultType.exactProduct:
        final bool otherStore = cartItem.inventory.otherStoreInStock;
        final bool restock = cartItem.inventory.restockPlanned;
        return _ResultTypeConfig(
          title: '정확한 제품 확인',
          subtitle: '고객의 디자인 조건을 유지하기 위해 동일 제품의 확보를 제안합니다.',
          // EXACT_PRODUCT always shows the ORIGINAL cart item's own photo,
          // never recommendedProduct (there isn't one for this resultType).
          imageUrl: cartItem.imageUrl,
          productName: cartItem.productName,
          color: displayProductColor(cartItem.color),
          size: displayProductSize(cartItem.size),
          chipLabel: otherStore ? '타 매장 보유' : (restock ? '입고 예정' : '확인 필요'),
          card2Label: '제품 확보 정보',
          card2Content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SegueLabelValueRow(
                label: '현재 매장',
                value: cartItem.inventory.currentStoreInStock ? '보유' : '미보유',
              ),
              SegueLabelValueRow(label: '보유 매장', value: result.pathDescription),
              SegueLabelValueRow(label: '입고 예정', value: restock ? '입고 예정 있음' : '확인 필요'),
            ],
          ),
        );
      case DecisionResultType.comparisonExperience:
      case DecisionResultType.todayPurchase:
        final ProductSkuSummary product = result.recommendedProduct ?? cartItem.skuSummary;
        return _ResultTypeConfig(
          title: result.resultType == DecisionResultType.comparisonExperience ? '비교 체험 제품' : '오늘 구매 가능한 제품',
          subtitle: '원제품의 소재와 시그니처 인상을 현재 매장에서 직접 확인할 수 있는 제품입니다.',
          imageUrl: product.imageUrl,
          productName: product.productName,
          color: product.color,
          size: product.size,
          // Figma (159:2173/159:3053) — confirmed both use "타 매장 보유".
          chipLabel: '타 매장 보유',
          card2Label: '원제품과의 차이',
          card2Content: Text(result.difference, style: SegueCardText.body18),
        );
      case DecisionResultType.additionalConsultation:
        // Unreachable — LastIntentCardScreen routes this resultType to
        // LastIntentAdditionalConsultationScreen instead.
        return _ResultTypeConfig(
          title: '',
          subtitle: '',
          imageUrl: cartItem.imageUrl,
          productName: cartItem.productName,
          color: cartItem.color,
          size: cartItem.size,
          chipLabel: '',
          card2Label: '',
          card2Content: const SizedBox.shrink(),
        );
    }
  }

  final String title;
  final String subtitle;
  final String imageUrl;
  final String productName;
  final String color;
  final String size;
  final String chipLabel;
  final String card2Label;
  final Widget card2Content;
}
