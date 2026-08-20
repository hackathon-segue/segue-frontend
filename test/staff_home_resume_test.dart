import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// "고객/상담 상태 관리" — Home의 "상담 이어서 진행"이 currentStep 기준으로
/// 정확한 화면부터 재개하는지, 그리고 Customer Lookup 화면이 재진입 시 이전
/// 고객 잔상 없이 항상 빈 조회 상태로 뜨는지 검증한다.
void main() {
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

  Future<void> lookupAndConsent(
    WidgetTester tester, {
    String phone = '010-1234-5678',
  }) async {
    await tester.tap(find.text('START SEGUE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), phone);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(
      find.descendant(of: find.byType(Form), matching: find.text('고객 조회')),
    );
    await tester.pumpAndSettle();

    final Finder consentButton = find.text('상담 데이터 이용 동의 확인');
    if (consentButton.evaluate().isNotEmpty) {
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
    } else {
      final Finder cartButton = find.text('쇼핑백 확인');
      await tester.ensureVisible(cartButton);
      await tester.tap(cartButton);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('발화 제출 후 보충 질문 단계에서 홈으로 나갔다가 "상담 이어서 진행"을 누르면 '
      '처음(발화 입력)이 아니라 보충 질문 화면부터 정확히 재개된다', (WidgetTester tester) async {
    await reachStaffHome(tester);
    await lookupAndConsent(tester);

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

    // Leave without answering the follow-up question — directly via the
    // Navigator (not the sidebar's HOME link/navigateToTabletRoute), same
    // as this file's other tests below. The sidebar link itself now goes
    // through the exit-consultation guard (Figma 500:3875, see
    // navigation_guard_test.dart) which would intercept a raw tap here;
    // this test's own concern is resume-by-step, not the guard.
    Navigator.of(
      tester.element(find.text('고객 의도 입력 - 보충 질문')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();
    expect(find.text('SEGUE HOME'), findsOneWidget);

    final Finder resumeButton = find.text('상담 이어서 진행');
    expect(resumeButton, findsOneWidget);
    await tester.tap(resumeButton);
    await tester.pumpAndSettle();

    // Landed directly on the follow-up screen — never re-showed the
    // utterance input the CA already filled in.
    expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);
    expect(find.text('고객 의도 입력'), findsNothing);
  });

  testWidgets('Customer Lookup 화면은 재진입할 때마다 이전 조회 결과 없이 항상 빈 상태로 뜨지만, '
      'Home의 진행 중 상담은 그대로 유지된다', (WidgetTester tester) async {
    await reachStaffHome(tester);
    await lookupAndConsent(tester);

    // Start a Last Intent session so Home has an active consultation to
    // preserve across the Customer Lookup round-trip below.
    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('상담 대상 제품')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();
    expect(find.text('상담 이어서 진행'), findsOneWidget);

    // Re-enter Customer Lookup — must NOT show 김세계's card again even
    // though currentCustomer/the active consultation both still exist.
    await tester.tap(find.text('START SEGUE'));
    await tester.pumpAndSettle();
    expect(find.text('김세계'), findsNothing);
    for (final TextFormField field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller?.text ?? '', isEmpty);
    }

    // Back to Home — the active consultation card is still there.
    Navigator.of(
      tester.element(find.text('고객 검색')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();
    expect(find.text('상담 이어서 진행'), findsOneWidget);
  });

  testWidgets('발화 입력 단계(아직 제출 전)에서 나갔다가 "상담 이어서 진행"으로 재진입한 뒤 '
      '"처음으로 돌아가기"를 누르면 Home이 아니라 상담 대상 제품(직전 단계) 화면으로 간다', (
    WidgetTester tester,
  ) async {
    await reachStaffHome(tester);
    await lookupAndConsent(tester);

    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('고객 의도 입력 시작'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 입력'), findsOneWidget);

    // Leave before ever submitting an utterance — currentStep stays at
    // its default (utterance).
    Navigator.of(
      tester.element(find.text('고객 의도 입력')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 이어서 진행'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 입력'), findsOneWidget);

    await tester.tap(find.text('처음으로 돌아가기'));
    await tester.pumpAndSettle();

    // The real previous step (LastIntentIntroScreen), not Home.
    expect(find.text('상담 대상 제품'), findsOneWidget);
    expect(find.text('SEGUE HOME'), findsNothing);
  });

  testWidgets('진행 중인 상담 카드의 "쇼핑백 확인" 버튼을 누르면 현재 고객의 쇼핑백 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    await reachStaffHome(tester);
    await lookupAndConsent(tester);

    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('상담 대상 제품')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();

    await tester.tap(find.text('쇼핑백 확인'));
    await tester.pumpAndSettle();

    expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);
    expect(find.textContaining('김세계 님의 쇼핑백'), findsOneWidget);
  });

  testWidgets('서로 다른 두 고객이 각각 진행 중인 상담을 갖고 있으면 Home에 카드가 1개가 아니라 '
      '2개 다 뜬다', (WidgetTester tester) async {
    await reachStaffHome(tester);

    // Customer A (김세계) starts a Last Intent session, then leaves.
    await lookupAndConsent(tester, phone: '010-1234-5678');
    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('상담 대상 제품')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();
    expect(find.text('상담 이어서 진행'), findsOneWidget);

    // Customer B (이수현) looks up separately and also starts one.
    await lookupAndConsent(tester, phone: '010-9876-5432');
    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('상담 대상 제품')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();

    // Both customers' cards show — 김세계's session wasn't wiped by
    // looking up 이수현.
    expect(find.text('김세계'), findsOneWidget);
    expect(find.text('이수현'), findsOneWidget);
    expect(find.text('상담 이어서 진행'), findsNWidgets(2));
    expect(find.text('현재 진행 중 상담'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('진행 중인 상담 카드가 2개일 때, currentCustomer가 다른 고객을 가리키고 있어도 '
      '각 카드의 "쇼핑백 확인"은 항상 그 카드 자신의 고객 쇼핑백을 연다 — 마지막으로 '
      '조회했던(또는 완료되어 사라진) 다른 고객의 쇼핑백이 잘못 뜨면 안 된다', (WidgetTester tester) async {
    await reachStaffHome(tester);

    await lookupAndConsent(tester, phone: '010-1234-5678'); // 김세계
    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('상담 대상 제품')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();

    await lookupAndConsent(tester, phone: '010-9876-5432'); // 이수현
    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('상담 대상 제품')),
    ).popUntil(ModalRoute.withName(AppRoutes.staffHome));
    await tester.pumpAndSettle();

    // At this point currentCustomer is 이수현 (looked up most recently).
    // Tapping 김세계's card's "쇼핑백 확인" must still show 김세계's cart,
    // not 이수현's (the bug: it used to just navigate to whatever
    // currentCustomer already was).
    final Finder shoppingBagButtons = find.text('쇼핑백 확인');
    expect(shoppingBagButtons, findsNWidgets(2));
    final Finder kimCard = find.ancestor(
      of: find.text('김세계'),
      matching: find.byType(Container),
    );
    await tester.tap(
      find.descendant(of: kimCard.first, matching: find.text('쇼핑백 확인')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('김세계 님의 쇼핑백'), findsOneWidget);
    expect(find.textContaining('이수현 님의 쇼핑백'), findsNothing);
  });
}
