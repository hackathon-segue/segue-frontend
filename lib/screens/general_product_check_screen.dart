import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/product_option_display.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';

/// Figma node 98:1933 "매장 보유 제품 확인하기 화면 (얘는 매장에 잇는 거)" —
/// reached from [CartInventoryScreen]'s "제품 확인하기" button for a cart item
/// currently held at this store. Unlike the out-of-stock branch, there is no
/// Last Intent flow here: the CA just confirms the physical product with the
/// customer, so this screen shows the real [cartItem] directly instead of
/// running structureIntent/decide/execute.
class GeneralProductCheckScreen extends StatelessWidget {
  const GeneralProductCheckScreen({
    required this.customer,
    required this.cartItem,
    super.key,
  });

  final Customer customer;
  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    return SegueCardShell(
      pageTitle: 'CURRENT SESSION',
      activeMenuItem: TabletMenuItem.currentSession,
      sessionCount: LastIntentSessionScope.of(context).activeCount,
      // Figma (98:1933): a literal "1/5" step badge, same convention as
      // every other screen in this flow (last_intent_card_screen.dart etc.
      // hardcode their own step number from Figma rather than computing one).
      stepBadge: '1/5',
      subtitle: '선택한 제품은 현재 매장에 보유 중입니다. 고객과 함께 매장 내 제품을 직접 확인해 주세요.',
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
              final Widget image = SegueProductImage(
                imageUrl: cartItem.imageUrl,
                width: 296,
                height: 321,
              );
              final Widget button = SegueCtaButton(
                label: '해당 제품 상담 완료',
                showArrow: false,
                onPressed: () {
                  StaffSessionScope.of(
                    context,
                  ).markProductChecked(cartItem.skuId);
                  navigateToTabletRoute(context, AppRoutes.cartInventory);
                },
              );
              final Widget info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('제품 정보', style: SegueCardText.productInfoLabel15),
                  // Figma: label bottom 28+21=49 → product line top 65 = 16px.
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        const TextSpan(
                          text: '쇼핑백 제품  ',
                          style: SegueCardText.cartProductLabel20,
                        ),
                        TextSpan(
                          text:
                              '${cartItem.productName} ${displayProductColor(cartItem.color)}',
                          style: SegueCardText.cartProductValue20,
                        ),
                      ],
                    ),
                  ),
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
                  decoration: BoxDecoration(
                    border: Border.all(color: SegueCardColors.border, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      image,
                      const SizedBox(height: 21),
                      info,
                      const SizedBox(height: 21),
                      Align(alignment: Alignment.centerRight, child: button),
                    ],
                  ),
                );
              }
              return SizedBox(
                width: double.infinity,
                height: 375,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 28, 19, 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: SegueCardColors.border, width: 2),
                  ),
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
                            Align(
                              alignment: Alignment.bottomRight,
                              child: button,
                            ),
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
