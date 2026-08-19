import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// "진행 중인 상담 없음" popup (Figma 500:3902) — CURRENT SESSION's sidebar row
/// shows this instead of navigating when there's no active consultation.
void main() {
  const String popupTitle = '현재 진행 중인 상담이 없습니다.';

  Future<void> reachStaffHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    Navigator.of(
      tester.element(find.text('LXXVI')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();
  }

  Future<void> lookupAndConsent(WidgetTester tester) async {
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
    final Finder checkRows = find.byType(SegueCheckboxRow);
    for (int i = 0; i < tester.widgetList(checkRows).length; i++) {
      await tester.tap(checkRows.at(i));
      await tester.pump();
    }
    final Finder agreeButton = find.text('동의하고 쇼핑백 확인');
    await tester.ensureVisible(agreeButton);
    await tester.tap(agreeButton);
    await tester.pumpAndSettle();
  }

  testWidgets(
    '조회된 고객이 없을 때 CURRENT SESSION을 누르면 팝업이 뜨고, '
    '"SEGUE 진행하기"를 누르면 고객 조회 페이지로 이동한다',
    (WidgetTester tester) async {
      await reachStaffHome(tester);

      await tester.tap(find.text('CURRENT SESSION').first);
      await tester.pumpAndSettle();

      expect(find.text(popupTitle), findsOneWidget);
      expect(find.text('SEGUE 진행하기'), findsOneWidget);

      await tester.tap(find.text('SEGUE 진행하기'));
      await tester.pumpAndSettle();

      expect(find.text(popupTitle), findsNothing);
      expect(find.text('CUSTOMER SEARCH'), findsWidgets);
      expect(find.text('고객 검색'), findsOneWidget);
    },
  );

  testWidgets(
    '이미 조회된 고객이 있을 때 CURRENT SESSION을 누르면 팝업이 뜨고, '
    '"SEGUE 진행하기"를 누르면 해당 고객의 장바구니로 이동한다',
    (WidgetTester tester) async {
      await reachStaffHome(tester);
      await lookupAndConsent(tester);

      // lookupAndConsent lands on the cart (sidebar-less
      // SegueHeaderOnlyShell) — back to a sidebar-bearing screen first.
      Navigator.of(
        tester.element(find.text('쇼핑백 및 재고 확인')),
      ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CURRENT SESSION').first);
      await tester.pumpAndSettle();
      expect(find.text(popupTitle), findsOneWidget);

      await tester.tap(find.text('SEGUE 진행하기'));
      await tester.pumpAndSettle();

      expect(find.text(popupTitle), findsNothing);
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);
      expect(find.textContaining('김세계 님의 쇼핑백'), findsOneWidget);
    },
  );

  testWidgets('X를 누르면 팝업만 닫히고 현재 페이지에 그대로 남는다', (
    WidgetTester tester,
  ) async {
    await reachStaffHome(tester);

    await tester.tap(find.text('CURRENT SESSION').first);
    await tester.pumpAndSettle();
    expect(find.text(popupTitle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text(popupTitle), findsNothing);
    expect(find.text('SEGUE HOME'), findsOneWidget);
  });
}
