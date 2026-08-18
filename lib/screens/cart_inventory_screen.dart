import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/app_config.dart';
import '../utils/product_option_display.dart';
import '../utils/segue_card_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/segue_card_shell.dart';
import '../widgets/segue_info_card.dart';
import 'general_product_check_screen.dart';
import 'last_intent_intro_screen.dart';

/// Figma node 89:1498 "장바구니 및 재고 확인 화면" (default) and 98:1740 "...-
/// 모든 품목 상담 완료" (all-complete state) — Issue #48's rebuild,
/// superseding the previous 14:1051-based build. Uses the shared
/// [SegueHeaderOnlyShell] (confirmed sidebar-less, same family as the
/// consent screens) — no header markup is built here.
///
/// Business logic unchanged from the previous build: [StaffWebSessionController]
/// still owns customer/consent/cart loading, [LastIntentSessionManager]
/// still owns per-SKU Last Intent session state ("SEGUE 진행"/"재진행"
/// navigates into that flow exactly as before). The old "재고 안내" info
/// panel doesn't exist in either Figma node, so it's dropped rather than
/// kept as a 14:1051-era leftover — it was purely decorative static text
/// with no state/API tie of its own.
///
/// New in this pass: 98:1737 confirms the "상담" column switches from plain
/// "상담 미진행" text to a gray "상담 완료" pill once a row's session
/// completes, and its "다음 행동" button switches from filled to
/// outline+disabled at the same time (98:1740) — both driven by real
/// per-row completion signals: out-of-stock rows use
/// [LastIntentSessionManager.isCompleted], in-stock rows use
/// [StaffWebSessionState.checkedInStockSkuIds] (set via
/// [StaffWebSessionController.markProductChecked] from
/// [GeneralProductCheckScreen]'s "해당 제품 상담 완료" button, Figma 98:1933).
class CartInventoryScreen extends StatelessWidget {
  const CartInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StaffWebSessionController controller = StaffSessionScope.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final StaffWebSessionState state = controller.state;
        final Customer? customer = state.customer;

        if (customer == null) {
          return const SegueHeaderOnlyShell(
            heading: '쇼핑백 및 재고 확인',
            horizontalPadding: 50,
            body: AppStateView.empty(
              title: '조회된 고객이 없습니다',
              message: '고객 조회 화면에서 먼저 고객을 조회해 주세요.',
            ),
          );
        }

        final LastIntentSessionManager lastIntentManager =
            LastIntentSessionScope.of(context);
        final List<CartItem> items = state.cartState.data ?? const <CartItem>[];
        bool isItemCompleted(CartItem item) {
          return item.inventory.currentStoreInStock
              ? state.checkedInStockSkuIds.contains(item.skuId)
              : lastIntentManager.isCompleted(item.skuId);
        }

        final bool allComplete =
            items.isNotEmpty && items.every(isItemCompleted);

        return SegueHeaderOnlyShell(
          heading: '쇼핑백 및 재고 확인',
          horizontalPadding: 50,
          headingTrailing: _CustomerInfoBar(customer: customer, state: state),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget title = Text(
                    '${customer.name} 님의 쇼핑백(${items.length}개 품목)',
                    style: SegueCardText.screenTitle24,
                  );
                  if (!allComplete) {
                    return title;
                  }
                  final Widget banner = Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: SegueCardColors.scopeBoxBg,
                    alignment: Alignment.center,
                    child: const Text(
                      '쇼핑백의 모든 품목이 상담 완료되었습니다.',
                      style: SegueCardText.allCompleteBanner22,
                    ),
                  );
                  if (constraints.maxWidth >= 700) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(child: title),
                        const SizedBox(width: 16),
                        banner,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      title,
                      const SizedBox(height: 12),
                      banner,
                    ],
                  );
                },
              ),
              // Figma: section title bottom 248+33=281 → table header top
              // 327 = 46px (minus the header text's own ~26px line box
              // already counted, matching header top 306(line1) directly:
              // title bottom 281 → line1 306 = 25px).
              const SizedBox(height: 25),
              const _CartTableHeaderRow(),
              // Figma: header row bottom 327+26=353 → line2 377 = 24px, but
              // line1 sits right under the header labels (306) and line2
              // right under the divider gap below them (377) — both
              // fixed 2px dividers bracketing the header row.
              const SizedBox(height: 21),
              const Divider(
                height: 2,
                thickness: 2,
                color: SegueCardColors.border,
              ),
              const SizedBox(height: 24),
              _CartList(
                customer: customer,
                cartState: state.cartState,
                checkedInStockSkuIds: state.checkedInStockSkuIds,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Masks a `010-1234-5678`-shaped phone number to `010-****-5678` — Figma
/// (89:1498) shows the middle segment masked; this app's own [Customer]
/// model only ever has the real unmasked number, so the mask is applied
/// for display only, never sent anywhere.
String _maskPhoneNumber(String phoneNumber) {
  final List<String> parts = phoneNumber.split('-');
  if (parts.length != 3) {
    return phoneNumber;
  }
  return '${parts[0]}-****-${parts[2]}';
}

class _CustomerInfoBar extends StatelessWidget {
  const _CustomerInfoBar({required this.customer, required this.state});

  final Customer customer;
  final StaffWebSessionState state;

  @override
  Widget build(BuildContext context) {
    final CustomerConsent? consent = state.consentState.data;
    final String consentDate = consent != null
        ? _formatDate(consent.consentedAt)
        : '-';
    final int itemCount = state.cartState.data?.length ?? 0;

    return Container(
      // Figma: Details Container 1028x92.
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(27, 20, 27, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SegueCardColors.border, width: 2),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final List<Widget> columns = <Widget>[
            _InfoColumn(
              label: '고객',
              value: customer.name,
              valueStyle: SegueCardText.customerName22,
            ),
            _InfoColumn(
              label: '회원번호',
              value: 'MCM-${customer.id.toString().padLeft(5, '0')}',
            ),
            _InfoColumn(
              label: '전화번호',
              value: _maskPhoneNumber(customer.phoneNumber),
            ),
            _InfoColumn(label: '상담 일시', value: consentDate, alignEnd: true),
            _InfoColumn(label: '쇼핑백 제품', value: '$itemCount개', alignEnd: true),
          ];
          if (constraints.maxWidth >= 500) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < columns.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 24),
                  Expanded(child: columns[i]),
                ],
              ],
            );
          }
          return Wrap(spacing: 24, runSpacing: 12, children: columns);
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const List<String> weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
    final String weekday = weekdays[dt.weekday - 1];
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.'
        '${dt.day.toString().padLeft(2, '0')}($weekday)';
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    this.valueStyle = SegueCardText.customerInfoValue20,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: SegueCardText.detailLabel16),
        const SizedBox(height: 5),
        Text(value, style: valueStyle, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CartTableHeaderRow extends StatelessWidget {
  const _CartTableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The column labels only mean anything once rows actually render
        // as aligned columns — below _CartItemRow's own 1250 breakpoint
        // rows stack vertically instead, so the header is hidden rather
        // than rendered mid-air over content it no longer describes.
        if (constraints.maxWidth < 1250) {
          return const SizedBox.shrink();
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 298,
              child: Text('품목', style: SegueCardText.tableHeader20),
            ),
            SizedBox(
              width: 442,
              child: Text('설명', style: SegueCardText.tableHeader20),
            ),
            SizedBox(
              width: 212,
              child: Text('재고', style: SegueCardText.tableHeader20),
            ),
            SizedBox(
              width: 199,
              child: Text('상담', style: SegueCardText.tableHeader20),
            ),
            Expanded(child: Text('다음 행동', style: SegueCardText.tableHeader20)),
          ],
        );
      },
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({
    required this.customer,
    required this.cartState,
    required this.checkedInStockSkuIds,
  });

  final Customer customer;
  final AsyncValue<List<CartItem>> cartState;
  final Set<int> checkedInStockSkuIds;

  @override
  Widget build(BuildContext context) {
    if (!customer.hasConsented) {
      return const AppStateView.empty(
        title: '데이터 이용 동의가 필요합니다',
        message: '동의 확인 후 장바구니 목록을 볼 수 있습니다.',
      );
    }
    if (cartState.isLoading || cartState.isIdle) {
      return const AppStateView.loading(title: '장바구니를 불러오고 있습니다');
    }
    if (cartState.hasError) {
      final Object? error = cartState.error;
      final String message = error is AppException
          ? error.message
          : '장바구니를 불러오지 못했습니다.';
      // A stale `hasConsented: true` on the looked-up Customer (consent
      // revoked/expired server-side since lookup) surfaces here as a 403
      // instead of the pre-check above — same messaging/redirect either way.
      final bool consentRequired = error is ApiException && error.isConsentRequired;
      if (consentRequired) {
        return AppStateView.error(
          title: '데이터 이용 동의가 필요합니다',
          message: '동의 확인 후 장바구니 목록을 볼 수 있습니다.',
          actionLabel: '동의 화면으로 이동',
          onAction: () => Navigator.of(context).pushNamed(AppRoutes.customerConsent),
        );
      }
      return AppStateView.error(message: message);
    }
    final List<CartItem> items = cartState.data ?? const <CartItem>[];
    if (items.isEmpty) {
      return const AppStateView.empty(title: '장바구니가 비어 있습니다');
    }

    return Column(
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          _CartItemRow(
            customer: customer,
            item: items[i],
            checkedInStockSkuIds: checkedInStockSkuIds,
          ),
          // Figma: each row (incl. its own trailing divider) is 276px tall
          // with a 26px gap before the next — the divider itself sits at
          // the very bottom of each row's own 276px box.
          const SizedBox(height: 26),
        ],
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.customer,
    required this.item,
    required this.checkedInStockSkuIds,
  });

  final Customer customer;
  final CartItem item;
  final Set<int> checkedInStockSkuIds;

  @override
  Widget build(BuildContext context) {
    final LastIntentSessionManager lastIntentManager =
        LastIntentSessionScope.of(context);
    final bool inStock = item.inventory.currentStoreInStock;
    final String stockLabel = inStock ? '재고 확인' : '재고 없음';

    // In-stock rows ("제품 확인하기") have no Last Intent session, so their
    // completion comes from GeneralProductCheckScreen's "해당 제품 상담 완료"
    // button (StaffWebSessionController.markProductChecked) instead of
    // LastIntentSessionManager.isCompleted.
    final bool completed = inStock
        ? checkedInStockSkuIds.contains(item.skuId)
        : lastIntentManager.isCompleted(item.skuId);
    // Issue #64: "추가 상담 미진행" (169:3821) still completes the session
    // (execute() ran) but shows Figma 98:1740's darker "상담 중단" badge
    // instead of the normal one — in-stock rows have no Last Intent
    // session at all, so this never applies to them.
    final bool declined = !inStock && lastIntentManager.isDeclined(item.skuId);
    const String consultLabel = '상담 미진행';
    final String actionLabel = inStock ? '제품 확인하기' : item.actionButtonLabel;

    void handlePressed() {
      if (inStock) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                GeneralProductCheckScreen(customer: customer, cartItem: item),
            settings: const RouteSettings(name: AppRoutes.generalProductCheck),
          ),
        );
      } else {
        lastIntentManager.sessionFor(customer: customer, cartItem: item);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                LastIntentIntroScreen(customer: customer, cartItem: item),
            settings: const RouteSettings(name: AppRoutes.lastIntentIntro),
          ),
        );
      }
    }

    final Widget image = SegueProductImage(imageUrl: item.imageUrl, width: 228, height: 247);
    final Widget description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ItemNameText(item.productName),
        // Figma: name bottom (33) → price block top 160 = 127px. No price
        // field exists anywhere in the model layer (confirmed: not in
        // CartItem/ProductSkuSummary, not in API.md/SCHEMA.md) — the ₩
        // line Figma shows is dropped rather than fabricated; only real
        // fields (color/size) render here.
        const SizedBox(height: 127),
        Text(
          '${displayProductColor(item.color)}\n${displayProductSize(item.size)}',
          style: SegueCardText.itemMeta22,
        ),
      ],
    );
    final Widget stockStatus = Text(
      stockLabel,
      style: SegueCardText.rowStatus22,
    );
    final Widget consultStatus = completed
        ? SegueCompactButton(
            label: declined ? '상담 중단' : '상담 완료',
            backgroundColor: declined
                ? SegueCardColors.consultationAbortedBg
                : SegueCardColors.stepBadgeBg,
            height: 48,
            // Figma (98:1737/98:1780/98:1803): fixed 123×48 box, ~4px
            // horizontal padding around the label — much tighter than this
            // shared widget's 16px default.
            width: 123,
            horizontalPadding: 4,
            textStyle: SegueCardText.largeButtonLabel20White,
            onPressed: null,
          )
        : const Padding(
            padding: EdgeInsets.only(top: 9),
            child: Text(consultLabel, style: SegueCardText.rowStatus22),
          );
    final Widget actionButton = SegueLargeButton(
      label: actionLabel,
      filled: !completed,
      onPressed: completed ? null : handlePressed,
      // Figma (98:1725): "SEGUE 진행"'s outline border measures 2px, not
      // this shared widget's unverified 1px default used elsewhere.
      borderWidth: 2,
      horizontalPadding: 14,
      centerContent: true,
    );
    const double rowContentWidth = 1340;
    const double rowContentHeight = 247;
    Widget horizontalRow() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 298,
            child: Align(alignment: Alignment.centerLeft, child: image),
          ),
          SizedBox(width: 442, child: description),
          SizedBox(
            width: 212,
            child: Padding(
              // Text labels are 9px lower than the 48px controls so their
              // visual centerline matches the consultation badge/action.
              padding: const EdgeInsets.only(top: 110),
              child: stockStatus,
            ),
          ),
          SizedBox(
            width: 199,
            child: Padding(
              padding: const EdgeInsets.only(top: 101),
              // Without Align, the SizedBox's tight 199px width
              // constraint overrides SegueCompactButton's own explicit
              // 123px width (BoxConstraints.enforce clamps the child's
              // tight width into the parent's tight range), stretching the
              // "상담 완료" badge full column width instead of staying
              // 123px like Figma (98:1737). Align loosens that constraint
              // so the badge's own width wins.
              child: Align(
                alignment: Alignment.centerLeft,
                heightFactor: 1,
                child: consultStatus,
              ),
            ),
          ),
          SizedBox(
            width: 189,
            child: Padding(
              padding: const EdgeInsets.only(top: 101),
              child: Align(
                alignment: Alignment.centerLeft,
                heightFactor: 1,
                child: SizedBox(width: 189, child: actionButton),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Keep the item, stock, consultation badge, and action button in
            // one horizontal row at every viewport width. Narrow screens
            // scale the complete row down proportionally instead of adding a
            // horizontal scroll or wrapping the status/action group onto a
            // second line.
            if (constraints.maxWidth >= rowContentWidth) {
              return horizontalRow();
            }
            return SizedBox(
              width: constraints.maxWidth,
              height: rowContentHeight * constraints.maxWidth / rowContentWidth,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: rowContentWidth,
                  height: rowContentHeight,
                  child: horizontalRow(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 25),
        const Divider(height: 2, thickness: 2, color: SegueCardColors.border),
      ],
    );
  }
}

/// Renders [productName] with 216:484's dual-font styling: the Latin
/// brand-word run (before the first space) in Montserrat Bold, the rest in
/// Pretendard Bold. Real [CartItem.productName] values are consistently
/// "<Latin brand> <Korean description>" (e.g. "MCM 백팩 미디움" — see
/// mock_segue_repository.dart), so splitting on the first space reflects
/// real data rather than a guess. Falls back to a single Pretendard-Bold
/// run if there's no space (e.g. a one-word name).
class _ItemNameText extends StatelessWidget {
  const _ItemNameText(this.productName);

  final String productName;

  @override
  Widget build(BuildContext context) {
    final int spaceIndex = productName.indexOf(' ');
    if (spaceIndex == -1) {
      return Text(productName, style: SegueCardText.itemName24);
    }
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: productName.substring(0, spaceIndex),
            style: SegueCardText.itemNameLatin24,
          ),
          TextSpan(
            text: productName.substring(spaceIndex),
            style: SegueCardText.itemName24,
          ),
        ],
      ),
    );
  }
}
