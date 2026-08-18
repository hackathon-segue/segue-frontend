import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/staff_check_row.dart';

/// Issue #8/#9: CartInventoryScreen's per-SKU status/action wiring, and
/// (Issue #9) each row's independent Last Intent session.
void main() {
  Future<BuildContext> reachCartInventoryScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    Navigator.of(
      tester.element(find.text('LXXVI')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('고객 조회 시작'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(
      find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
    );
    await tester.pumpAndSettle();

    final Finder consentButton = find.text('데이터 이용 동의 확인');
    await tester.ensureVisible(consentButton);
    await tester.tap(consentButton);
    await tester.pumpAndSettle();

    final Finder checkRows = find.byType(StaffCheckRow);
    for (int i = 0; i < 3; i++) {
      await tester.tap(checkRows.at(i));
      await tester.pump();
    }

    final Finder agreeButton = find.text('동의하고 장바구니 확인');
    await tester.ensureVisible(agreeButton);
    await tester.tap(agreeButton);
    await tester.pumpAndSettle();
    expect(find.text('장바구니 · 재고 확인'), findsOneWidget);

    return tester.element(find.text('장바구니 · 재고 확인'));
  }

  testWidgets('all three cart items render with size/SKU/saved-time details', (
    WidgetTester tester,
  ) async {
    await reachCartInventoryScreen(tester);

    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
    expect(find.text('MCM 숄더백 미니'), findsOneWidget);
    expect(find.text('MCM 벨트백'), findsOneWidget);

    expect(find.textContaining('사이즈: 미디움'), findsOneWidget);
    expect(find.textContaining('SKU: 1 · 담은 시각:'), findsOneWidget);
    expect(find.textContaining('SKU: 5 · 담은 시각:'), findsOneWidget);

    expect(find.text('재고/입고 확인 상태'), findsNWidgets(3));
    expect(find.text('현재 매장 재고'), findsNWidgets(3));
    expect(find.text('타 매장 보유'), findsNWidgets(3));
    expect(find.text('입고 예정'), findsNWidgets(3));
    expect(find.text('확인 완료'), findsNWidgets(3));
    expect(find.text('오래된 정보'), findsOneWidget);
    expect(find.textContaining('기준 2026.08.16'), findsWidgets);
    expect(
      find.text('확인 필요 또는 오래된 정보는 구매 가능 경로로 확정하지 않고 CA가 다시 확인합니다.'),
      findsNWidgets(3),
    );
  });

  testWidgets(
    '제품 확인하기 navigates to the general product check screen and back',
    (WidgetTester tester) async {
      await reachCartInventoryScreen(tester);

      await tester.tap(find.text('제품 확인하기'));
      await tester.pumpAndSettle();

      expect(find.text('현재 매장 보유 제품'), findsOneWidget);
      expect(find.text('직접 확인 가능합니다'), findsOneWidget);
      expect(find.text('이 제품은 현재 매장에 보유 중입니다'), findsOneWidget);

      await tester.tap(find.text('상담 홈으로'));
      await tester.pumpAndSettle();
      expect(find.text('MCM 상담 지원'), findsOneWidget);
    },
  );

  testWidgets(
    'each out-of-stock row navigates to its own independent Last Intent session',
    (WidgetTester tester) async {
      final BuildContext context = await reachCartInventoryScreen(tester);
      final LastIntentSessionManager manager = LastIntentSessionScope.of(
        context,
      );
      final Customer customer = StaffSessionScope.of(context).state.customer!;
      final List<CartItem> items = StaffSessionScope.of(
        context,
      ).state.cartState.data!;
      final CartItem sku1Item = items.firstWhere((CartItem i) => i.skuId == 1);
      final CartItem sku5Item = items.firstWhere((CartItem i) => i.skuId == 5);

      expect(find.text('Last Intent 시작'), findsNWidgets(2));

      final Finder firstLastIntentButton = find.text('Last Intent 시작').first;
      await tester.ensureVisible(firstLastIntentButton);
      await tester.pumpAndSettle();
      await tester.tap(firstLastIntentButton);
      await tester.pumpAndSettle();
      expect(find.text('Last Intent 상담 시작'), findsOneWidget);
      final LastIntentSessionController sku1Session = manager.sessionFor(
        customer: customer,
        cartItem: sku1Item,
      );
      expect(sku1Session.state.selectedCartItem?.skuId, 1);

      // StaffAppShell screens have no AppBar/back button (custom shell
      // chrome), so pop directly via Navigator instead of tester.pageBack().
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(find.text('장바구니 · 재고 확인'), findsOneWidget);

      final Finder secondLastIntentButton = find.text('Last Intent 시작').last;
      await tester.ensureVisible(secondLastIntentButton);
      await tester.pumpAndSettle();
      await tester.tap(secondLastIntentButton);
      await tester.pumpAndSettle();
      expect(find.text('Last Intent 상담 시작'), findsOneWidget);
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
