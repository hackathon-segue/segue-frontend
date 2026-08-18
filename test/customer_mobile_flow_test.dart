import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';

Future<void> _openNewProducts(WidgetTester tester) async {
  await tester.tap(find.byTooltip('메뉴 열기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('신상품').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('customer mobile start opens menu and product list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());

    expect(find.text('LXXVI'), findsOneWidget);

    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();

    expect(find.text('쇼핑백'), findsOneWidget);
    expect(find.text('토트백 & 쇼퍼백'), findsWidgets);

    await tester.tap(find.text('모두보기'));
    await tester.pumpAndSettle();

    expect(find.text('AUTUMN WINTER 2026'), findsOneWidget);
    expect(find.text('Diamond 3D 카프스킨 숄더백'), findsOneWidget);
  });

  testWidgets('product detail requires a valid color and size SKU', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await _openNewProducts(tester);

    await tester.tap(find.text('Diamond 3D 카프스킨 숄더백').first);
    await tester.pumpAndSettle();

    expect(find.text('제품 상세 화면'), findsOneWidget);
    expect(find.text('컬러 선택'), findsOneWidget);
    expect(find.text('사이즈 선택'), findsOneWidget);

    final Finder cartButton = find.ancestor(
      of: find.text('장바구니 담기', skipOffstage: false),
      matching: find.byType(FilledButton, skipOffstage: false),
    );
    FilledButton button = tester.widget<FilledButton>(cartButton);
    expect(button.onPressed, isNull);

    await tester.ensureVisible(find.text('스몰'));
    await tester.tap(find.text('스몰'));
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(cartButton);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('selected SKU is saved and shown in the mobile cart', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await _openNewProducts(tester);

    await tester.tap(find.text('Diamond 3D 카프스킨 숄더백').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('스몰'));
    await tester.tap(find.text('스몰'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장바구니 담기'));
    await tester.pumpAndSettle();

    expect(find.text('장바구니 추가 완료'), findsOneWidget);
    expect(find.text('장바구니에 추가되었습니다'), findsOneWidget);
    expect(find.text('선택 컬러 오렌지'), findsOneWidget);
    expect(find.text('선택 사이즈 스몰'), findsOneWidget);

    await tester.tap(find.text('장바구니 보기'));
    await tester.pumpAndSettle();

    expect(find.text('앱 장바구니 목록'), findsOneWidget);
    expect(find.text('최근 담은 순서'), findsOneWidget);
    expect(find.text('오렌지 · 스몰'), findsOneWidget);
    expect(find.text('2026. 08. 16 추가'), findsOneWidget);
  });

  testWidgets('consultation result opens online and store visit guidance', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await tester.tap(find.byTooltip('SEGUE 내역 확인'));
    await tester.pumpAndSettle();

    expect(find.text('앱 상담 결과 확인'), findsOneWidget);
    expect(find.text('MCM 백팩 미디움'), findsOneWidget);
    expect(find.text('정확한 제품 확인'), findsOneWidget);
    expect(find.text('온라인 구매하기'), findsOneWidget);

    await tester.tap(find.text('온라인 구매하기'));
    await tester.pumpAndSettle();

    expect(find.text('온라인 구매 화면'), findsOneWidget);
    expect(find.text('온라인 구매 안내'), findsOneWidget);
    await tester.ensureVisible(find.text('온라인 스토어에서 구매하기'));
    expect(find.text('온라인 스토어에서 구매하기'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('매장 재방문 안내 보기'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('매장 재방문 안내 보기'));
    await tester.pumpAndSettle();

    expect(find.text('매장 재방문 안내'), findsWidgets);
    expect(find.text('방문 전 준비 사항'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('요청 접수 안내'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('요청 접수 안내'), findsOneWidget);
  });
}
