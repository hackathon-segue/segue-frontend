import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// "브라우저 뒤로가기가 가끔 앱 홈으로 튐" 버그 — this app has no
/// usePathUrlStrategy()/Router2 setup, so on Flutter Web an UNNAMED pushed
/// route never gets its own browser history entry, making the browser's
/// own back button skip past several screens instead of always landing on
/// the immediately-previous one. Every Last Intent flow screen push now
/// carries a unique RouteSettings.name (see AppRoutes' lastIntent* constants)
/// so each screen gets exactly one history entry. This test verifies that
/// wiring directly — it can't simulate a real browser back button (that's
/// not something flutter_test can drive), but it proves the underlying
/// mechanism the fix depends on is actually in place at every step.
void main() {
  String? currentRouteName(WidgetTester tester) {
    return ModalRoute.of(
      tester.element(find.byType(Scaffold).first),
    )?.settings.name;
  }

  Future<void> reachUtteranceScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(SegueApp(repository: MockSegueRepository()));
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
    // last_intent_intro_screen.dart's own push — already named before this fix.
    expect(currentRouteName(tester), AppRoutes.lastIntentIntro);

    await tester.tap(find.text('고객 의도 입력 시작'));
    await tester.pumpAndSettle();
  }

  testWidgets('발화 -> 보충질문 -> 의도확인 -> Last Intent Card 화면까지, 화면마다 서로 다른 '
      'RouteSettings.name이 붙는다 (브라우저 히스토리 항목이 화면 수만큼 생기게)', (
    WidgetTester tester,
  ) async {
    await reachUtteranceScreen(tester);
    expect(currentRouteName(tester), AppRoutes.lastIntentUtterance);

    // mock_segue_repository.dart: "비슷" triggers needsFollowUp.
    await tester.enterText(find.byType(TextField), '비슷한 제품이어도 괜찮아요');
    await tester.pump();
    await tester.tap(find.text('고객 의도 구조화하기'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);
    expect(currentRouteName(tester), AppRoutes.lastIntentFollowUp);

    await tester.enterText(find.byType(TextField).last, '오늘 바로 사고 싶어요');
    await tester.pump();
    await tester.tap(find.text('답변 제출 후 의도 확인'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 요약 확인'), findsOneWidget);
    expect(currentRouteName(tester), AppRoutes.lastIntentConfirm);

    final Finder editButton = find.text('수정할게요');
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(currentRouteName(tester), AppRoutes.lastIntentEdit);
    // Back to confirm — a plain pop, unaffected by naming.
    final Finder cancelButton = find.text('취소');
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    expect(currentRouteName(tester), AppRoutes.lastIntentConfirm);

    final Finder confirmButton = find.text('맞아요, 다음 단계로');
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(find.text('SEGUE CARD'), findsOneWidget);
    expect(currentRouteName(tester), AppRoutes.lastIntentCard);
  });

  testWidgets(
    'utterance -> confirm 직행(보충 질문 없이)도 lastIntentConfirm으로 이름이 붙는다',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      await tester.enterText(find.byType(TextField), '편한 느낌이면 좋겠어요');
      await tester.pump();
      await tester.tap(find.text('고객 의도 구조화하기'));
      await tester.pumpAndSettle();
      expect(find.text('고객 의도 요약 확인'), findsOneWidget);
      expect(currentRouteName(tester), AppRoutes.lastIntentConfirm);
    },
  );
}
