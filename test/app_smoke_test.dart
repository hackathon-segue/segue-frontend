import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';

void main() {
  testWidgets('renders the initial customer mobile route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SegueApp());

    expect(find.text('앱 로그인 화면'), findsOneWidget);
    expect(find.text('로그인'), findsWidgets);
  });

  testWidgets('opens the staff web route group', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());

    Navigator.of(tester.element(find.text('앱 로그인 화면'))).pushNamed('/staff');
    await tester.pumpAndSettle();

    expect(find.text('직원 웹'), findsWidgets);
    expect(find.text('Last Intent 상담'), findsOneWidget);
  });
}
