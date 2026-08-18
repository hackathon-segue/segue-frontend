import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/staff_check_row.dart';

/// "동의하고 장바구니 확인" must stay disabled (secondary-styled, node
/// 14:637) until all three "동의 범위" checkboxes are checked (each
/// starting unchecked, node 14:663), then switch to enabled/primary.
void main() {
  Future<void> reachConsentScreen(
    WidgetTester tester, {
    String phoneNumber = '010-1234-5678',
  }) async {
    await tester.pumpWidget(const SegueApp());
    Navigator.of(
      tester.element(find.text('앱 로그인 화면')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('고객 조회 시작'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), phoneNumber);
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
  }

  testWidgets(
    '동의하고 장바구니 확인 button is disabled until all three checkboxes are checked',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await reachConsentScreen(tester);

      final Finder agreeButton = find.text('동의하고 장바구니 확인');
      final Finder checkRows = find.byType(StaffCheckRow);
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
      expect(find.text('장바구니 · 재고 확인'), findsOneWidget);
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

    final Finder firstCheck = find.byType(StaffCheckRow).first;
    await tester.tap(firstCheck);
    await tester.pump();
    await tester.tap(firstCheck);
    await tester.pump();

    // After checking then unchecking, the agree button must remain
    // disabled (still not all three checked).
    final Finder agreeButton = find.text('동의하고 장바구니 확인');
    await tester.ensureVisible(agreeButton);
    await tester.tap(agreeButton);
    await tester.pumpAndSettle();
    expect(find.text('상담 데이터 이용 동의'), findsOneWidget);
  });

  testWidgets(
    'agreeing from an unconsented customer loads the cart inventory',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await reachConsentScreen(tester, phoneNumber: '010-9876-5432');

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(StaffCheckRow).at(i));
        await tester.pump();
      }

      final Finder agreeButton = find.text('동의하고 장바구니 확인');
      await tester.ensureVisible(agreeButton);
      await tester.tap(agreeButton);
      await tester.pumpAndSettle();

      expect(find.text('장바구니 · 재고 확인'), findsOneWidget);
      expect(find.text('MCM 백팩 미디움'), findsOneWidget);
      expect(find.text('데이터 이용 동의가 필요합니다'), findsNothing);
    },
  );
}
