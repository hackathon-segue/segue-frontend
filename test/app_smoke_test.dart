import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';

void main() {
  testWidgets('renders the initial customer mobile route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SegueApp());

    expect(find.text('고객 모바일'), findsOneWidget);
    expect(find.text('MCM Last Intent'), findsOneWidget);
  });

  testWidgets('opens the staff web route group', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());

    final Finder staffWebButton = find.widgetWithText(FilledButton, '직원 웹');
    await tester.ensureVisible(staffWebButton);
    await tester.tap(staffWebButton);
    await tester.pumpAndSettle();

    expect(find.text('직원 웹'), findsWidgets);
    expect(find.text('Last Intent 상담'), findsOneWidget);
  });
}
