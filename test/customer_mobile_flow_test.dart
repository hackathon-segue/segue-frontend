import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';

void main() {
  testWidgets('customer mobile login opens home and product list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());

    await tester.tap(find.text('앱으로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.text('앱 홈 화면'), findsOneWidget);
    expect(find.text('MCM 월드'), findsOneWidget);

    await tester.tap(find.text('제품 전체 보기'));
    await tester.pumpAndSettle();

    expect(find.text('제품 목록 화면'), findsOneWidget);
    expect(find.text('Himmel Large Backpack'), findsOneWidget);
  });

  testWidgets('product detail requires a valid color and size SKU', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    await tester.tap(find.text('앱으로 계속하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 전체 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Himmel Large Backpack').first);
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

    await tester.ensureVisible(find.text('라지'));
    await tester.tap(find.text('라지'));
    await tester.pumpAndSettle();

    button = tester.widget<FilledButton>(cartButton);
    expect(button.onPressed, isNotNull);
  });
}
