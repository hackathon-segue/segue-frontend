import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_completion_screen.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// Issue #46/#64: ADDITIONAL_CONSULTATION detail screen — Figma 169:3683
/// ("진행" checked) / 169:3821 ("미진행" checked), a single screen with a
/// local 진행/미진행 toggle. Issue #64 changed what happens after the CTA:
/// both branches now return straight to the cart (never the "요청 접수
/// 완료" hand-off screen), differing only in the cart row's badge
/// ("상담 완료" vs Figma 98:1740's darker "상담 중단").
void main() {
  Future<void> reachAdditionalConsultationScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    // The mobile customer entry screen no longer has a "직원 웹" button
    // (it's now the real customer-facing app) — reach staff routes via a
    // direct named push instead, same as the app's own wireframe QA does.
    Navigator.of(tester.element(find.text('LXXVI'))).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    await tester.tap(find.text('START SEGUE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.descendant(of: find.byType(Form), matching: find.text('고객 조회')));
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

    // mock_segue_repository.dart: "비슷" triggers needsFollowUp, and a
    // "모르겠"/"글쎄" follow-up answer keeps canWait/canVisitOtherStore
    // null with empty essentialConditions → decide() resolves to
    // ADDITIONAL_CONSULTATION.
    await tester.enterText(find.byType(TextField), '그냥 비슷한 느낌이면 다 좋아요');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('고객 의도 구조화하기'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '음.. 글쎄요 모르겠어요');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.text('답변 제출 후 의도 확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('맞아요, 다음 단계로'));
    await tester.pumpAndSettle();
    expect(find.text('조건 다시 확인하기'), findsOneWidget);

    final Finder cardCta = find.text('조건 다시 확인하기');
    await tester.ensureVisible(cardCta);
    await tester.tap(cardCta);
    await tester.pumpAndSettle();
    expect(find.text('추가 상담 진행'), findsWidgets);
  }

  testWidgets('defaults to the 진행 state (169:3683) with 상담 내용 기록하기 placeholder', (
    WidgetTester tester,
  ) async {
    await reachAdditionalConsultationScreen(tester);

    expect(find.text('추가 상담 미진행'), findsOneWidget);
    expect(find.text('이전 상담 요약'), findsOneWidget);
    // Figma-literal CTA display override for the 진행 state (169:3724) —
    // execute()'s real payload still uses decisionResult.actionType/
    // actionButtonLabel, this is on-screen text only.
    expect(find.text('상담 완료'), findsOneWidget);
    expect(find.text('해당 제품 상담 중단'), findsNothing);
    expect(find.text('상담 내용 기록하기'), findsOneWidget);
    expect(find.text('실행 불가 사유 입력하기 (예: 고객 동의 거절, 시간 부족 등)'), findsNothing);
  });

  testWidgets('tapping 추가 상담 미진행 switches to the 169:3821 state instantly', (
    WidgetTester tester,
  ) async {
    await reachAdditionalConsultationScreen(tester);

    await tester.tap(find.text('추가 상담 미진행'));
    await tester.pump();

    expect(find.text('해당 제품 상담 중단'), findsOneWidget);
    expect(find.text('상담 완료'), findsNothing);
    expect(find.text('실행 불가 사유 입력하기 (예: 고객 동의 거절, 시간 부족 등)'), findsOneWidget);
    expect(find.text('상담 내용 기록하기'), findsNothing);

    // Tapping "진행" switches straight back to the 169:3683 state.
    await tester.tap(find.text('추가 상담 진행').last);
    await tester.pump();
    expect(find.text('상담 완료'), findsOneWidget);
  });

  testWidgets(
    '진행 branch: 상담 완료 tap executes then returns to the cart with the normal 상담 완료 badge',
    (WidgetTester tester) async {
      await reachAdditionalConsultationScreen(tester);

      await tester.enterText(find.byType(TextField), '고객과 다시 통화해 조건을 확정했습니다.');
      await tester.pump();

      final Finder submitCta = find.text('상담 완료');
      await tester.ensureVisible(submitCta);
      await tester.tap(submitCta);
      await tester.pumpAndSettle();

      // Never shows the "요청 접수 완료" hand-off screen for this flow.
      expect(find.byType(LastIntentCompletionScreen), findsNothing);
      expect(find.text('요청 접수 완료'), findsNothing);
      // Lands back on the cart, with this SKU's row marked complete via the
      // normal (not "중단") badge.
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);
      expect(find.text('상담 완료'), findsOneWidget);
      expect(find.text('상담 중단'), findsNothing);
    },
  );

  testWidgets(
    '미진행 branch: 해당 제품 상담 중단 tap executes then returns to the cart with the darker 상담 중단 badge',
    (WidgetTester tester) async {
      await reachAdditionalConsultationScreen(tester);

      await tester.tap(find.text('추가 상담 미진행'));
      await tester.pump();

      final Finder abortCta = find.text('해당 제품 상담 중단');
      await tester.ensureVisible(abortCta);
      await tester.tap(abortCta);
      await tester.pumpAndSettle();

      expect(find.byType(LastIntentCompletionScreen), findsNothing);
      expect(find.text('요청 접수 완료'), findsNothing);
      expect(find.text('쇼핑백 및 재고 확인'), findsOneWidget);
      // The declined outcome shows the darker "상담 중단" badge, never the
      // normal "상담 완료" one, for this SKU's row.
      expect(find.text('상담 중단'), findsOneWidget);
      expect(find.text('상담 완료'), findsNothing);
    },
  );
}
