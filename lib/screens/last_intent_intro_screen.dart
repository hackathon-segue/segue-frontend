import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';
import 'last_intent_utterance_screen.dart';

/// Figma node 89:1559 "상담 시작 - 1단계" — reused shell ([SegueCardShell],
/// same family as [GeneralProductCheckScreen]'s 98:1933), so no
/// header/sidebar/CA-footer markup is built here.
///
/// Reached from [CartInventoryScreen]'s "Last Intent 시작" button for a
/// specific out-of-stock cart item. Business logic unchanged from the
/// previous (14:1256-based) build: starts/resumes this SKU's own
/// [LastIntentSessionController] via `sessionFor` on build, and "고객 의도
/// 입력 시작" still hands off to [LastIntentUtteranceScreen] with the same
/// customer/cartItem. "쇼핑백 확인" is new on this Figma pass — it has no
/// dedicated state of its own, so it just pops back to the
/// [CartInventoryScreen] already directly below this screen on the nav
/// stack (the screen the CA came from), rather than inventing a new
/// navigation target.
class LastIntentIntroScreen extends StatelessWidget {
  const LastIntentIntroScreen({required this.customer, required this.cartItem, super.key});

  final Customer customer;
  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager manager = LastIntentSessionScope.of(context);
    // Starts (or resumes) this SKU's own session — a different SKU's
    // session, if one exists, is untouched.
    manager.sessionFor(customer: customer, cartItem: cartItem);

    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: manager.activeCount,
      // Figma (89:1559): a literal "1/5" step badge, same convention as
      // every other screen in this flow.
      stepBadge: '1/5',
      subtitle: '고객이 앱에서 선택한 제품을 바탕으로 상담을 진행합니다. 아래 제품과 컬러를 확인한 후 다음 단계로 이동하세요.',
      // Figma: subtitle bottom 146+21=167 → "상담 대상 제품" heading top 202 = 35px.
      bodyTopGap: 35,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('상담 대상 제품', style: SegueCardText.screenTitle22),
          // Figma: heading bottom 202+31=233 → Details Container top 245 = 12px.
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const Widget image = _ProductImage(width: 296, height: 321);
              final Widget buttons = Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: <Widget>[
                  SegueCompactButton(
                    label: '쇼핑백 확인',
                    backgroundColor: SegueCardColors.compactButtonSecondaryBg,
                    height: 43,
                    width: 122,
                    textStyle: SegueCardText.ctaLabel18White,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SegueCompactButton(
                    label: '고객 의도 입력 시작',
                    backgroundColor: SegueCardColors.ctaBg,
                    height: 43,
                    width: 191,
                    showArrow: true,
                    textStyle: SegueCardText.ctaLabel18White,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              LastIntentUtteranceScreen(customer: customer, cartItem: cartItem),
                          settings: const RouteSettings(name: AppRoutes.lastIntentIntro),
                        ),
                      );
                    },
                  ),
                ],
              );
              final Widget info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('제품 정보', style: SegueCardText.productInfoLabel15),
                  // Figma: label bottom 28+21=49 → product line top 65 = 16px.
                  const SizedBox(height: 16),
                  _ProductDetailsText(cartItem: cartItem),
                ],
              );
              // Figma's fixed 296px-wide image doesn't fit alongside the
              // details column below ~500px of available width — stack the
              // image above instead of forcing a horizontal overflow, and
              // drop the fixed 375px card height (only sized to fit the Row
              // layout) since the stacked content no longer fits it.
              if (constraints.maxWidth < 500) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(25, 28, 19, 15),
                  decoration: BoxDecoration(border: Border.all(color: SegueCardColors.border, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      image,
                      const SizedBox(height: 21),
                      info,
                      const SizedBox(height: 21),
                      buttons,
                    ],
                  ),
                );
              }
              return SizedBox(
                width: double.infinity,
                height: 375,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 28, 19, 15),
                  decoration: BoxDecoration(border: Border.all(color: SegueCardColors.border, width: 2)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      image,
                      // Figma: image right edge 25+296=321 → details left 359 = 38px.
                      const SizedBox(width: 38),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            info,
                            const Spacer(),
                            Align(alignment: Alignment.bottomRight, child: buttons),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Figma (89:1559)'s "image 14" product photo — this specific screen's spec
/// explicitly calls for the real Figma-authored asset (not this app's usual
/// gray "Image" placeholder box), since no per-SKU photo exists in the data
/// layer to swap in instead.
class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(border: Border.all(color: SegueCardColors.border)),
      child: Image.asset('assets/images/last_intent_product.png', fit: BoxFit.cover),
    );
  }
}

/// "쇼핑백 제품  [브랜드 라틴 단어][나머지 상품명/컬러]" (89:1559) — the Latin
/// brand-word run (e.g. "MCM") uses Montserrat Medium, the rest Pretendard
/// Medium, matching Figma's "M Diamond" run split. Real
/// [CartItem.productName] values are consistently
/// "<Latin brand> <Korean description>" (see mock_segue_repository.dart),
/// so splitting on the first space reflects real data, not a guess.
class _ProductDetailsText extends StatelessWidget {
  const _ProductDetailsText({required this.cartItem});

  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final String value = '${cartItem.productName} ${cartItem.color}';
    final int spaceIndex = value.indexOf(' ');
    final List<InlineSpan> valueSpans = spaceIndex == -1
        ? <InlineSpan>[TextSpan(text: value, style: SegueCardText.cartProductValue20)]
        : <InlineSpan>[
            TextSpan(
              text: value.substring(0, spaceIndex),
              style: SegueCardText.cartProductValueLatin20,
            ),
            TextSpan(
              text: value.substring(spaceIndex),
              style: SegueCardText.cartProductValue20,
            ),
          ];
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          const TextSpan(text: '쇼핑백 제품  ', style: SegueCardText.cartProductLabel20),
          ...valueSpans,
        ],
      ),
    );
  }
}
