import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// "동의하고 쇼핑백 확인" must stay disabled (secondary-styled, node
/// 14:637) until all three "동의 범위" checkboxes are checked (each
/// starting unchecked, node 14:663), then switch to enabled/primary.
void main() {
  Future<void> reachConsentScreen(WidgetTester tester) async {
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
    await tester.ensureVisible(consentButton);
    await tester.tap(consentButton);
    await tester.pumpAndSettle();
  }

  testWidgets(
    '동의하고 쇼핑백 확인 button is disabled until all three checkboxes are checked',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await reachConsentScreen(tester);

      final Finder agreeButton = find.text('동의하고 쇼핑백 확인');
      final Finder checkRows = find.byType(SegueCheckboxRow);
      expect(checkRows, findsNWidgets(3));

      Future<void> tapAgree() async {
        await tester.ensureVisible(agreeButton);
        await tester.tap(agreeButton);
        await tester.pumpAndSettle();
      }

      // Disabled with none checked: tapping must not navigate away.
      await tapAgree();
      expect(find.text('상담 데이터 이용 동의'), findsOneWidget);

      // Still disabled with only 2 of 3 checked.
      await tester.tap(checkRows.at(0));
      await tester.pump();
      await tester.tap(checkRows.at(1));
      await tester.pump();
      await tapAgree();
      expect(find.text('상담 데이터 이용 동의'), findsOneWidget);

      // Checking the third row enables it and navigation proceeds.
      await tester.tap(checkRows.at(2));
      await tester.pump();
      await tapAgree();
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);
    },
  );

  testWidgets('checkbox toggles back to unchecked on a second tap', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await reachConsentScreen(tester);

    final Finder firstCheck = find.byType(SegueCheckboxRow).first;
    await tester.tap(firstCheck);
    await tester.pump();
    await tester.tap(firstCheck);
    await tester.pump();

    // After checking then unchecking, the agree button must remain
    // disabled (still not all three checked).
    final Finder agreeButton = find.text('동의하고 쇼핑백 확인');
    await tester.ensureVisible(agreeButton);
    await tester.tap(agreeButton);
    await tester.pumpAndSettle();
    expect(find.text('상담 데이터 이용 동의'), findsOneWidget);
  });
}
