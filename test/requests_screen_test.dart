import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/utils/app_config.dart';

void main() {
  testWidgets('requests screen scales down without overflow on small screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    Navigator.of(
      tester.element(find.text('LXXVI')),
    ).pushNamed(AppRoutes.requests);
    await tester.pumpAndSettle();

    expect(find.text('REQUESTS'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
