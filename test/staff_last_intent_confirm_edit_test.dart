import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';
import 'package:segue_frontend/widgets/segue_product_image.dart';

/// Issue #12: 의도 요약 확인 / 의도 수정 화면 — 표시, 저장, 취소, "맞아요" -> decide()
/// -> Last Intent Card 흐름.
void main() {
  Future<void> reachConfirmScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
    // The mobile customer entry screen no longer has a "직원 웹" button (it's
    // now the real customer-facing app) — reach staff routes via a direct
    // named push instead, same as the app's own wireframe QA does.
    Navigator.of(
      tester.element(find.text('LXXVI')),
    ).pushNamed(AppRoutes.staffHome);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1440, 900);
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

    final Finder checkRows = find.byType(SegueCheckboxRow);
    for (int i = 0; i < 3; i++) {
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

    await tester.enterText(find.byType(TextField), '편한 느낌이면 좋겠어요');
    await tester.pump();
    await tester.tap(find.text('고객 의도 구조화하기'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 요약 확인'), findsOneWidget);
  }

  testWidgets('summary screen shows the 110:2038 card fields', (
    WidgetTester tester,
  ) async {
    await reachConfirmScreen(tester);

    // 고객 핵심 조건 요약
    expect(find.text('필수 조건'), findsOneWidget);
    expect(find.text('구매 상황'), findsOneWidget);
    expect(find.text('중요도 순위'), findsOneWidget);
    expect(find.text('보충 답변'), findsOneWidget);
    // 상세 구매 상황
    expect(find.text('사용 목적'), findsOneWidget);
    expect(find.text('구매 시급성'), findsOneWidget);
    expect(find.text('예산 범위'), findsOneWidget);
    expect(find.text('보충 질문 여부'), findsOneWidget);
    // 쇼핑백 품목
    expect(find.text('쇼핑백 품목'), findsOneWidget);
    expect(find.text('BLACK'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);

    final Rect productImageRect = tester.getRect(
      find.byType(SegueProductImage).last,
    );
    final Rect productNameRect = tester.getRect(find.text('MCM 백팩 미디움'));
    expect(productNameRect.top, productImageRect.top);

    // Mock's essentialConditions {logoPosition: 정면중앙, silhouette: 각진} must
    // render with Korean vocabulary labels, not raw API keys.
    expect(find.text('로고 위치: 정면중앙, 실루엣: 각진'), findsOneWidget);
  });

  testWidgets('처음으로 돌아가기는 모바일 홈이 아니라 직원 홈으로 이동한다', (WidgetTester tester) async {
    await reachConfirmScreen(tester);

    await tester.tap(find.text('처음으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('SEGUE HOME'), findsOneWidget);
    expect(find.text('고객 모바일'), findsNothing);
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

    expect(find.text('고객 의도 요약 확인'), findsOneWidget);
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

    expect(find.text('고객 의도 요약 확인'), findsOneWidget);
    expect(find.text('이 값은 저장되면 안 됨'), findsNothing);
    // purpose was empty originally (mock always returns purpose: ''), so the
    // summary should still show the empty-state label, not the discarded
    // edit — "확인 필요" also covers "중요도 순위"/"예산 범위" (no such fields
    // exist in the model), so multiple instances are expected now.
    expect(find.text('확인 필요'), findsWidgets);
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
