import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/staff_button.dart';
import 'package:segue_frontend/widgets/staff_check_row.dart';

/// Issue #10: LastIntentUtteranceScreen's input/validation/loading/success
/// states, reached through the real Issue #7-9 flow with the app's default
/// (never-throwing) MockSegueRepository.
void main() {
  Future<void> reachUtteranceScreen(WidgetTester tester) async {
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
    expect(find.text('Last Intent 상담 시작'), findsOneWidget);

    await tester.tap(find.text('고객 의도 입력 시작'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 입력'), findsOneWidget);
  }

  testWidgets('empty utterance keeps submit disabled and blocks the request', (
    WidgetTester tester,
  ) async {
    await reachUtteranceScreen(tester);

    final StaffButton submitButton = tester.widget(
      find.ancestor(of: find.text('제출'), matching: find.byType(StaffButton)),
    );
    expect(submitButton.onPressed, isNull);
    expect(submitButton.variant, StaffButtonVariant.secondary);
  });

  testWidgets('상담 시작으로 돌아가기 navigates back to the Last Intent intro screen', (
    WidgetTester tester,
  ) async {
    await reachUtteranceScreen(tester);

    await tester.tap(find.text('상담 시작으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('Last Intent 상담 시작'), findsOneWidget);
  });

  testWidgets(
    'submitting without a follow-up need navigates straight to the confirm screen',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      final BuildContext context = tester.element(find.text('고객 의도 입력'));
      final LastIntentSessionManager manager = LastIntentSessionScope.of(
        context,
      );
      final Customer customer = StaffSessionScope.of(context).state.customer!;
      final CartItem sku1Item = StaffSessionScope.of(
        context,
      ).state.cartState.data!.firstWhere((CartItem i) => i.skuId == 1);
      final LastIntentSessionController session = manager.sessionFor(
        customer: customer,
        cartItem: sku1Item,
      );

      await tester.enterText(find.byType(TextFormField), '편한 느낌이면 좋겠어요');
      await tester.pump();

      final StaffButton enabledButton = tester.widget(
        find.ancestor(of: find.text('제출'), matching: find.byType(StaffButton)),
      );
      expect(enabledButton.onPressed, isNotNull);
      expect(enabledButton.variant, StaffButtonVariant.primary);

      await tester.tap(find.text('제출'));
      // MockSegueRepository resolves with no artificial delay, so by the
      // time tap() returns the request has already gone loading -> data —
      // the loading-state transition itself is verified at the state layer
      // in last_intent_utterance_flow_test.dart. This checks the request
      // actually fired and the screen navigated to the right next step.
      await tester.pumpAndSettle();
      expect(session.state.intentState.hasData, isTrue);
      expect(find.text('의도 요약 확인'), findsOneWidget);
      expect(find.text('구매 시급성'), findsOneWidget);
      expect(find.text('구매 시급성 낮음'), findsOneWidget);
    },
  );

  testWidgets(
    'popping back to the utterance screen shows an editable input form, not '
    'the stale analysis-complete state',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      await tester.enterText(find.byType(TextFormField), '편한 느낌이면 좋겠어요');
      await tester.pump();
      await tester.tap(find.text('제출'));
      await tester.pumpAndSettle();
      expect(find.text('의도 요약 확인'), findsOneWidget);

      // Issue #12 repurposed the confirm screen's "수정할게요" button to open
      // the StructuredIntent edit screen instead of returning here, so this
      // exercises the same regression (system/back navigation landing back
      // on this screen) directly via Navigator.pop().
      Navigator.of(tester.element(find.text('의도 요약 확인'))).pop();
      await tester.pumpAndSettle();

      // Bug: this used to show the persisted "고객 의도 분석이 완료되었습니다"
      // success state instead of the input form, because it branched on
      // session-level intentState.hasData (which stays true forever once
      // set) rather than a per-visit local flag.
      expect(find.text('고객 의도 입력'), findsOneWidget);
      expect(find.text('고객 의도 분석이 완료되었습니다'), findsNothing);
      final Finder field = find.byType(TextFormField);
      expect(field, findsOneWidget);
      expect(
        (tester.widget(field) as TextFormField).controller!.text,
        '편한 느낌이면 좋겠어요',
      );

      // And it's actually editable/re-submittable, not just visually reset.
      await tester.enterText(field, '역시 이 색상이 좋을 것 같아요');
      await tester.pump();
      await tester.tap(find.text('제출'));
      await tester.pumpAndSettle();
      expect(find.text('의도 요약 확인'), findsOneWidget);
    },
  );

  testWidgets(
    'submitting an utterance that needs follow-up navigates to the follow-up screen',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      await tester.enterText(find.byType(TextFormField), '비슷한 제품이어도 괜찮아요');
      await tester.pump();
      await tester.tap(find.text('제출'));
      await tester.pumpAndSettle();

      expect(find.text('Last Intent 상담'), findsOneWidget);
      expect(find.text('보충 질문'), findsWidgets);
      expect(
        find.text('혹시 오늘 바로 구매를 원하시나요, 아니면 여유를 두고 보셔도 괜찮으실까요?'),
        findsOneWidget,
      );

      // AC: 빈 보충 답변은 제출되지 않는다.
      final StaffButton disabledButton = tester.widget(
        find.ancestor(
          of: find.text('답변 제출 후 의도 확인'),
          matching: find.byType(StaffButton),
        ),
      );
      expect(disabledButton.onPressed, isNull);
      expect(disabledButton.variant, StaffButtonVariant.secondary);
    },
  );

  testWidgets(
    'Issue #11 AC: 보충 질문은 최대 1회만 발생한다 — completing it once, then '
    're-submitting another utterance that would need follow-up skips straight to confirm',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      await tester.enterText(find.byType(TextFormField), '비슷한 제품이어도 괜찮아요');
      await tester.pump();
      await tester.tap(find.text('제출'));
      await tester.pumpAndSettle();
      expect(find.text('AI 보충 질문'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '오늘 바로 사고 싶어요');
      await tester.pump();
      await tester.tap(find.text('답변 제출 후 의도 확인'));
      await tester.pumpAndSettle();
      expect(find.text('의도 요약 확인'), findsOneWidget);

      // Back to the utterance screen (Confirm -> FollowUp -> Utterance),
      // then submit a NEW utterance that would independently trigger
      // needsFollowUp again per the mock's own '비슷' rule. Each context is
      // grabbed fresh from whatever's on screen right now — a context
      // captured before these transitions gets deactivated once its
      // element is rebuilt away (e.g. by the loading/success state swap).
      Navigator.of(tester.element(find.text('의도 요약 확인'))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('AI 보충 질문'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('고객 의도 입력'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '비슷한 걸로 다시 확인해주세요');
      await tester.pump();
      await tester.tap(find.text('제출'));
      await tester.pumpAndSettle();

      // Must land on the confirm screen directly — never a second visit to
      // the follow-up screen.
      expect(find.text('의도 요약 확인'), findsOneWidget);
      expect(find.text('AI 보충 질문'), findsNothing);
    },
  );
}
