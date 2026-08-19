import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// SEGUE / Last Intent exit-consultation navigation guard (Figma 500:3875) —
/// sidebar/header taps mid-consultation must be intercepted with a confirm
/// popup instead of navigating immediately, and the popup must route to
/// whatever destination the CA actually clicked, not a hardcoded Home.
void main() {
  Future<void> reachFollowUpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    Navigator.of(
      tester.element(find.text('LXXVI')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('START SEGUE'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '010-1234-5678',
    );
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

    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('고객 의도 입력 시작'));
    await tester.pumpAndSettle();

    // mock_segue_repository.dart: "비슷" triggers needsFollowUp.
    await tester.enterText(find.byType(TextField), '비슷한 제품이어도 괜찮아요');
    await tester.pump();
    await tester.tap(find.text('고객 의도 구조화하기'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);
  }

  const String popupTitle =
      '상담을 종료하시겠습니까? 화면에서 이탈할 시\n진행 중인 상담은 종료되지 않습니다.';

  testWidgets(
    '상담이 진행 중이지 않을 때는 사이드바를 눌러도 팝업 없이 바로 이동한다',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
      Navigator.of(
        tester.element(find.text('LXXVI')),
      ).pushNamed(AppRoutes.consultationHistory);
      await tester.pumpAndSettle();

      await tester.tap(find.text('HOME'));
      await tester.pumpAndSettle();

      expect(find.text('SEGUE HOME'), findsOneWidget);
      expect(find.text(popupTitle), findsNothing);
    },
  );

  testWidgets(
    '상담 진행 중 CURRENT SESSION을 누르면 팝업이 뜨고, 바깥을 눌러도 닫히지 않는다',
    (WidgetTester tester) async {
      await reachFollowUpScreen(tester);

      await tester.tap(find.text('CURRENT SESSION').first);
      await tester.pumpAndSettle();

      expect(find.text(popupTitle), findsOneWidget);
      // Still on the same consultation screen underneath — no navigation
      // happened yet.
      expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);

      // Tapping the dim barrier must not dismiss it (scenario 5).
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text(popupTitle), findsOneWidget);
    },
  );

  testWidgets(
    '"상담으로 돌아가기"는 팝업만 닫고 진행 상태를 그대로 유지한다',
    (WidgetTester tester) async {
      await reachFollowUpScreen(tester);

      await tester.tap(find.text('CURRENT SESSION').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('상담으로 돌아가기'));
      await tester.pumpAndSettle();

      expect(find.text(popupTitle), findsNothing);
      expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);
    },
  );

  testWidgets(
    '"상담 종료하고 나가기"는 세션을 종료하고 원래 클릭했던 목적지로 이동한다 '
    '(Home으로 고정 이동하지 않는다)',
    (WidgetTester tester) async {
      await reachFollowUpScreen(tester);

      // Clicked CURRENT SESSION (→ cart inventory), not Home.
      await tester.tap(find.text('CURRENT SESSION').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('상담 종료하고 나가기'));
      await tester.pumpAndSettle();

      expect(find.text(popupTitle), findsNothing);
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);

      // The session was actually cleared — Home no longer offers to resume
      // it.
      Navigator.of(
        tester.element(find.text('쇼핑백 및 재고 확인')),
      ).pushNamed(AppRoutes.staffHome);
      await tester.pumpAndSettle();
      expect(find.text('상담 이어서 진행'), findsNothing);
    },
  );
}
