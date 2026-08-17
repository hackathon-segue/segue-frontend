import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/widgets/staff_check_row.dart';

/// Issue #8: CartInventoryScreen's per-SKU status/action wiring.
void main() {
  Future<BuildContext> reachCartInventoryScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await tester.tap(find.widgetWithText(FilledButton, '직원 웹'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ca@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('고객 조회 시작'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Form), matching: find.text('고객 조회')));
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
  });

  testWidgets('제품 확인하기 navigates to the general product check screen and back', (
    WidgetTester tester,
  ) async {
    await reachCartInventoryScreen(tester);

    await tester.tap(find.text('제품 확인하기'));
    await tester.pumpAndSettle();

    expect(find.text('현재 매장 보유 제품'), findsOneWidget);
    expect(find.text('직접 확인 가능합니다'), findsOneWidget);
    expect(find.text('이 제품은 현재 매장에 보유 중입니다'), findsOneWidget);

    await tester.tap(find.text('상담 홈으로'));
    await tester.pumpAndSettle();
    expect(find.text('MCM 상담 지원'), findsOneWidget);
  });

  testWidgets(
    'each out-of-stock row has an independent Last Intent 시작 button that sets session context',
    (WidgetTester tester) async {
      final BuildContext context = await reachCartInventoryScreen(tester);
      final LastIntentSessionController lastIntentController = LastIntentSessionScope.of(
        context,
      );

      expect(find.text('Last Intent 시작'), findsNWidgets(2));

      await tester.tap(find.text('Last Intent 시작').first);
      await tester.pump();
      expect(lastIntentController.state.selectedCartItem?.skuId, 1);

      await tester.tap(find.text('Last Intent 시작').last);
      await tester.pump();
      expect(lastIntentController.state.selectedCartItem?.skuId, 5);

      // Tapping the second button did not navigate away or otherwise
      // disturb the first item's row — both remain independently visible.
      expect(find.text('MCM 백팩 미디움'), findsOneWidget);
      expect(find.text('MCM 벨트백'), findsOneWidget);
    },
  );
}
