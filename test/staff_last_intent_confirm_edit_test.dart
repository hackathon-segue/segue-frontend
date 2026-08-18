import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/staff_check_row.dart';

/// Issue #12: 의도 요약 확인 / 의도 수정 화면 — 표시, 저장, 취소, "맞아요" -> decide()
/// -> Last Intent Card 흐름.
void main() {
  Future<void> reachConfirmScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SegueApp());
    Navigator.of(
      tester.element(find.text('앱 로그인 화면')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('고객 조회 시작'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
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

    final Finder checkRows = find.byType(StaffCheckRow);
    for (int i = 0; i < 3; i++) {
      await tester.tap(checkRows.at(i));
      await tester.pump();
    }
    final Finder agreeButton = find.text('동의하고 장바구니 확인');
    await tester.ensureVisible(agreeButton);
    await tester.tap(agreeButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Last Intent 시작').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('고객 의도 입력 시작'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '편한 느낌이면 좋겠어요');
    await tester.pump();
    await tester.tap(find.text('제출'));
    await tester.pumpAndSettle();
    expect(find.text('의도 요약 확인'), findsOneWidget);
  }

  testWidgets('summary screen shows all 8 required StructuredIntent fields', (
    WidgetTester tester,
  ) async {
    await reachConfirmScreen(tester);

    expect(find.text('사용 목적'), findsOneWidget);
    expect(find.text('필수 조건'), findsOneWidget);
    expect(find.text('선호 조건'), findsOneWidget);
    expect(find.text('양보 가능한 조건'), findsOneWidget);
    expect(find.text('구매 시급성'), findsOneWidget);
    expect(find.text('실물로 확인하고 싶은 요소'), findsOneWidget);
    expect(find.text('대기 가능 여부'), findsOneWidget);
    expect(find.text('타 매장 방문 가능 여부'), findsOneWidget);

    // Mock's essentialConditions {logoPosition: 정면중앙, silhouette: 각진} must
    // render with Korean vocabulary labels, not raw API keys.
    expect(find.text('로고 위치: 정면중앙, 실루엣: 각진'), findsOneWidget);
  });

  testWidgets('수정할게요 -> edit fields -> 저장 reflects on the summary screen', (
    WidgetTester tester,
  ) async {
    await reachConfirmScreen(tester);

    await tester.tap(find.text('수정할게요'));
    await tester.pumpAndSettle();
    expect(find.text('고객 구매 조건 수정'), findsOneWidget);

    final Finder purposeField = find.byType(TextFormField).first;
    await tester.enterText(purposeField, '출장용으로 매일 들 예정');
    await tester.pump();

    final Finder saveButton = find.text('저장');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('의도 요약 확인'), findsOneWidget);
    expect(find.text('출장용으로 매일 들 예정'), findsOneWidget);
  });

  testWidgets('수정할게요 -> edit -> 취소 discards the change', (
    WidgetTester tester,
  ) async {
    await reachConfirmScreen(tester);

    await tester.tap(find.text('수정할게요'));
    await tester.pumpAndSettle();

    final Finder purposeField = find.byType(TextFormField).first;
    await tester.enterText(purposeField, '이 값은 저장되면 안 됨');
    await tester.pump();

    final Finder cancelButton = find.text('취소');
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('의도 요약 확인'), findsOneWidget);
    expect(find.text('이 값은 저장되면 안 됨'), findsNothing);
    // purpose was empty originally (mock always returns purpose: ''), so the
    // summary should still show the empty-state label, not the discarded edit.
    expect(find.text('확인 필요'), findsOneWidget);
  });

  testWidgets('맞아요 calls decide() and navigates to the Last Intent Card', (
    WidgetTester tester,
  ) async {
    await reachConfirmScreen(tester);

    await tester.tap(find.text('맞아요, 다음 단계로'));
    await tester.pumpAndSettle();

    // Issue #46: Card is now a lightweight summary (Figma node 164:3213) —
    // deeper per-resultType content/CTA assertions moved to
    // last_intent_card_screen_test.dart and
    // last_intent_result_product_screen_test.dart, which exercise those
    // screens directly instead of walking the full intent-capture flow.
    expect(find.text('SEGUE CARD'), findsOneWidget);
    expect(find.text('상담 제품 요약'), findsOneWidget);
    expect(find.text('고객 핵심 조건'), findsOneWidget);
    expect(find.text('판단 근거'), findsOneWidget);
    // MockSegueRepository.decide()'s canned response has
    // recommendedProduct: null, so the summary card must not claim a
    // suggested product exists, and the single CTA uses the real
    // actionButtonLabel.
    expect(find.text('제안 제품'), findsNothing);
    expect(find.text('타 매장 확인 요청'), findsOneWidget);
    // Issue #13 AC (still holds): never show result-type badges or
    // forbidden language anywhere on this screen.
    expect(find.text('정확한 제품 확인'), findsNothing);
    expect(find.text('오늘 구매 가능한 제품'), findsNothing);
    expect(find.text('추가 상담 필요'), findsNothing);
    expect(find.textContaining('BEST MATCH'), findsNothing);
  });
}
