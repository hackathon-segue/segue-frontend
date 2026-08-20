import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';
import 'package:segue_frontend/widgets/segue_info_card.dart';
import 'package:segue_frontend/widgets/segue_product_image.dart';

/// Issue #8/#9: CartInventoryScreen's per-SKU status/action wiring, and
/// (Issue #9) each row's independent Last Intent session.
void main() {
  Future<BuildContext> reachCartInventoryScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    // The mobile customer entry screen no longer has a "직원 웹" button (it's
    // now the real customer-facing app) — reach staff routes via a direct
    // named push instead, same as the app's own wireframe QA does.
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey<String>('customer-mobile-start-logo')),
      ),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    await tester.tap(find.text('START SEGUE'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(
      find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
    );
    await tester.pumpAndSettle();

    final Finder consentButton = find.text('상담 데이터 이용 동의 확인');
    if (consentButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(consentButton);
      await tester.tap(consentButton);
      await tester.pumpAndSettle();

      final Finder checkRows = find.byType(SegueCheckboxRow);
      for (int i = 0; i < 3; i++) {
        await tester.tap(checkRows.at(i));
        await tester.pump();
      }

      final Finder agreeButton = find.text('동의하고 쇼핑백 확인');
      await tester.ensureVisible(agreeButton);
      await tester.tap(agreeButton);
    } else {
      final Finder cartButton = find.text('쇼핑백 확인');
      await tester.ensureVisible(cartButton);
      await tester.tap(cartButton);
    }
    await tester.pumpAndSettle();
    expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);

    return tester.element(find.text('쇼핑백 및 재고 확인'));
  }

  testWidgets('all three cart items render with real color/size details', (
    WidgetTester tester,
  ) async {
    await reachCartInventoryScreen(tester);

    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
    expect(find.text('MCM 숄더백 미니'), findsOneWidget);
    expect(find.text('MCM 벨트백'), findsOneWidget);

    // 89:1498 has no SKU number/saved-time fields at all (dropped along
    // with the rest of the old card-row layout) — only color/size, shown
    // as one combined Text per row.
    expect(find.textContaining('BLACK\nM'), findsOneWidget);
    expect(find.textContaining('BEIGE\nMini'), findsOneWidget);
    expect(find.textContaining('BROWN\nS'), findsOneWidget);
  });

  testWidgets('cart item row keeps the Figma product image and details gap', (
    WidgetTester tester,
  ) async {
    await reachCartInventoryScreen(tester);

    final Rect imageRect = tester.getRect(find.byType(SegueProductImage).first);
    final Rect detailsRect = tester.getRect(find.text('MCM 백팩 미디움'));

    expect(imageRect.width, 228);
    expect(imageRect.height, 247);
    expect(detailsRect.left - imageRect.right, 70);
  });

  testWidgets(
    'cart item row keeps stock, badge, and action on one line when narrow',
    (WidgetTester tester) async {
      await reachCartInventoryScreen(tester);

      tester.view.physicalSize = const Size(820, 900);
      await tester.pumpAndSettle();

      final Rect imageRect = tester.getRect(
        find.byType(SegueProductImage).first,
      );
      final Rect stockRect = tester.getRect(find.text('재고 없음').first);
      final Rect consultRect = tester.getRect(find.text('상담 미진행').first);
      final Rect actionRect = tester.getRect(
        find.widgetWithText(SegueLargeButton, 'Last Intent 시작').first,
      );
      final Iterable<SingleChildScrollView> horizontalScrolls = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .where(
            (SingleChildScrollView scrollView) =>
                scrollView.scrollDirection == Axis.horizontal,
          );

      expect(horizontalScrolls, isEmpty);
      expect(imageRect.width, lessThan(228));
      expect(stockRect.top, lessThan(imageRect.bottom));
      expect(consultRect.top, lessThan(imageRect.bottom));
      expect(actionRect.top, lessThan(imageRect.bottom));
      expect(stockRect.center.dy, closeTo(consultRect.center.dy, 0.5));
      expect(stockRect.center.dy, closeTo(actionRect.center.dy, 0.5));
      expect(
        actionRect.right,
        lessThanOrEqualTo(tester.view.physicalSize.width),
      );
    },
  );

  testWidgets(
    '제품 확인하기 navigates to the general product check screen and back',
    (WidgetTester tester) async {
      await reachCartInventoryScreen(tester);

      await tester.tap(find.text('제품 확인하기'));
      await tester.pumpAndSettle();

      expect(find.text('상담 대상 제품'), findsOneWidget);
      expect(find.text('제품 정보'), findsOneWidget);
      // 98:1933 shows the real in-stock cart item's name + raw (Korean)
      // color, not the display-mapped English color the row meta line uses.
      expect(find.textContaining('MCM 숄더백 미니 베이지'), findsOneWidget);

      final Finder completeButton = find.text('해당 제품 상담 완료');
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);

      // Issue: after confirming an in-stock item's consultation on 98:1933,
      // its cart row must show "상담 완료" and its "제품 확인하기" button
      // must switch to the disabled/outline state (98:1740), not still
      // "상담 미진행"/an enabled button, once back on the cart screen.
      expect(find.text('상담 완료'), findsOneWidget);
      final SegueLargeButton actionButton = tester.widget<SegueLargeButton>(
        find.widgetWithText(SegueLargeButton, '제품 확인하기'),
      );
      expect(actionButton.filled, isFalse);
      expect(actionButton.onPressed, isNull);

      final Rect actionButtonRect = tester.getRect(
        find.widgetWithText(SegueLargeButton, '제품 확인하기'),
      );
      final Rect actionLabelRect = tester.getRect(find.text('제품 확인하기'));
      expect(
        actionLabelRect.center.dx,
        closeTo(actionButtonRect.center.dx, 0.5),
      );
      expect(
        actionLabelRect.center.dy,
        closeTo(actionButtonRect.center.dy, 0.5),
      );
    },
  );

  testWidgets(
    'each out-of-stock row navigates to its own independent Last Intent session',
    (WidgetTester tester) async {
      final BuildContext context = await reachCartInventoryScreen(tester);
      final LastIntentSessionManager manager = LastIntentSessionScope.of(
        context,
      );
      final Customer customer = StaffSessionScope.of(
        context,
      ).state.currentCustomer!;
      final List<CartItem> items = StaffSessionScope.of(
        context,
      ).state.cartState.data!;
      final CartItem sku1Item = items.firstWhere((CartItem i) => i.skuId == 1);
      final CartItem sku5Item = items.firstWhere((CartItem i) => i.skuId == 5);

      expect(find.text('Last Intent 시작'), findsNWidgets(2));

      await tester.tap(find.text('Last Intent 시작').first);
      await tester.pumpAndSettle();
      expect(find.text('상담 대상 제품'), findsOneWidget);
      final LastIntentSessionController sku1Session = manager.sessionFor(
        customer: customer,
        cartItem: sku1Item,
      );
      expect(sku1Session.state.selectedCartItem?.skuId, 1);

      // StaffAppShell screens have no AppBar/back button (custom shell
      // chrome), so pop directly via Navigator instead of tester.pageBack().
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);

      final Finder secondLastIntentButton = find.text('Last Intent 시작').last;
      await tester.ensureVisible(secondLastIntentButton);
      await tester.tap(secondLastIntentButton);
      await tester.pumpAndSettle();
      expect(find.text('상담 대상 제품'), findsOneWidget);
      final LastIntentSessionController sku5Session = manager.sessionFor(
        customer: customer,
        cartItem: sku5Item,
      );
      expect(sku5Session.state.selectedCartItem?.skuId, 5);

      // Starting SKU 5's session did not overwrite or replace SKU 1's — same
      // controller instance, still pointed at SKU 1.
      expect(
        identical(
          sku1Session,
          manager.sessionFor(customer: customer, cartItem: sku1Item),
        ),
        isTrue,
      );
      expect(sku1Session.state.selectedCartItem?.skuId, 1);
    },
  );
}
