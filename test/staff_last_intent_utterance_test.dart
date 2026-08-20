import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/main.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/repositories/segue_repository.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/segue_card_shell.dart';

/// Issue #10: LastIntentUtteranceScreen's input/validation/loading/success
/// states, reached through the real Issue #7-9 flow with the app's default
/// (never-throwing) MockSegueRepository.

/// Throws on demand so tests can exercise structureIntent()'s error state —
/// same pattern as last_intent_utterance_flow_test.dart's `_SpyRepository`,
/// duplicated locally since that one is file-private.
class _ThrowingRepository extends MockSegueRepository {
  bool shouldThrow = false;

  @override
  Future<StructureIntentResponse> structureIntent(
    StructureIntentRequest request,
  ) async {
    if (shouldThrow) {
      throw const AppException('AI 분석에 실패했습니다.', code: 'AI_INTENT_FAILED');
    }
    return super.structureIntent(request);
  }
}

void main() {
  Future<void> reachUtteranceScreen(
    WidgetTester tester, {
    SegueRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SegueApp(repository: repository ?? MockSegueRepository()),
    );
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
    expect(find.text('상담 대상 제품'), findsOneWidget);

    await tester.tap(find.text('고객 의도 입력 시작'));
    await tester.pumpAndSettle();
    expect(find.text('고객 의도 입력'), findsOneWidget);
  }

  /// The submit button (98:1922's "고객 의도 구조화하기") is a private
  /// screen-local widget, not a reusable [StaffButton], so tests probe its
  /// enabled/disabled state via the [InkWell] Flutter itself provides
  /// rather than a custom widget type.
  InkWell submitInkWell(WidgetTester tester) {
    return tester.widget(
      find.ancestor(
        of: find.text('고객 의도 구조화하기'),
        matching: find.byType(InkWell),
      ),
    );
  }

  testWidgets('empty utterance keeps submit disabled and blocks the request', (
    WidgetTester tester,
  ) async {
    await reachUtteranceScreen(tester);

    expect(submitInkWell(tester).onTap, isNull);
  });

  testWidgets('처음으로 돌아가기 navigates back to the Last Intent intro screen', (
    WidgetTester tester,
  ) async {
    await reachUtteranceScreen(tester);

    await tester.tap(find.text('처음으로 돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('상담 대상 제품'), findsOneWidget);
  });

  testWidgets(
    'submitting without a follow-up need navigates straight to the confirm screen',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      final BuildContext context = tester.element(find.text('고객 의도 입력'));
      final LastIntentSessionManager manager = LastIntentSessionScope.of(
        context,
      );
      final Customer customer = StaffSessionScope.of(
        context,
      ).state.currentCustomer!;
      final CartItem sku1Item = StaffSessionScope.of(
        context,
      ).state.cartState.data!.firstWhere((CartItem i) => i.skuId == 1);
      final LastIntentSessionController session = manager.sessionFor(
        customer: customer,
        cartItem: sku1Item,
      );

      await tester.enterText(find.byType(TextField), '편한 느낌이면 좋겠어요');
      await tester.pump();

      expect(submitInkWell(tester).onTap, isNotNull);

      await tester.tap(find.text('고객 의도 구조화하기'));
      // MockSegueRepository resolves with no artificial delay, so by the
      // time tap() returns the request has already gone loading -> data —
      // the loading-state transition itself is verified at the state layer
      // in last_intent_utterance_flow_test.dart. This checks the request
      // actually fired and the screen navigated to the right next step.
      await tester.pumpAndSettle();
      expect(session.state.intentState.hasData, isTrue);
      expect(find.text('고객 의도 요약 확인'), findsOneWidget);
      expect(find.text('구매 시급성'), findsOneWidget);
      expect(find.text('구매 시급성 낮음'), findsOneWidget);
    },
  );

  testWidgets(
    'popping back to the utterance screen shows an editable input form, not '
    'the stale analysis-complete state',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      await tester.enterText(find.byType(TextField), '편한 느낌이면 좋겠어요');
      await tester.pump();
      await tester.tap(find.text('고객 의도 구조화하기'));
      await tester.pumpAndSettle();
      expect(find.text('고객 의도 요약 확인'), findsOneWidget);

      // Issue #12 repurposed the confirm screen's "수정할게요" button to open
      // the StructuredIntent edit screen instead of returning here, so this
      // exercises the same regression (system/back navigation landing back
      // on this screen) directly via Navigator.pop().
      Navigator.of(tester.element(find.text('고객 의도 요약 확인'))).pop();
      await tester.pumpAndSettle();

      // Bug: this used to show the persisted "고객 의도 분석이 완료되었습니다"
      // success state instead of the input form, because it branched on
      // session-level intentState.hasData (which stays true forever once
      // set) rather than a per-visit local flag.
      expect(find.text('고객 의도 입력'), findsOneWidget);
      expect(find.text('고객 의도 분석이 완료되었습니다'), findsNothing);
      final Finder field = find.byType(TextField);
      expect(field, findsOneWidget);
      expect(
        (tester.widget(field) as TextField).controller!.text,
        '편한 느낌이면 좋겠어요',
      );

      // And it's actually editable/re-submittable, not just visually reset.
      await tester.enterText(field, '역시 이 색상이 좋을 것 같아요');
      await tester.pump();
      await tester.tap(find.text('고객 의도 구조화하기'));
      await tester.pumpAndSettle();
      expect(find.text('고객 의도 요약 확인'), findsOneWidget);
    },
  );

  testWidgets(
    'submitting an utterance that needs follow-up navigates to the follow-up screen',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      await tester.enterText(find.byType(TextField), '비슷한 제품이어도 괜찮아요');
      await tester.pump();
      await tester.tap(find.text('고객 의도 구조화하기'));
      await tester.pumpAndSettle();

      expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);
      expect(
        find.text('혹시 오늘 바로 구매를 원하시나요, 아니면 여유를 두고 보셔도 괜찮으실까요?'),
        findsOneWidget,
      );

      // AC: 빈 보충 답변은 제출되지 않는다. The submit button (98:2019's
      // "답변 제출 후 의도 확인") is a private screen-local widget, not a
      // reusable [StaffButton], so probe its enabled state via the
      // [InkWell] Flutter itself provides.
      final InkWell disabledInkWell = tester.widget(
        find.ancestor(
          of: find.text('답변 제출 후 의도 확인'),
          matching: find.byType(InkWell),
        ),
      );
      expect(disabledInkWell.onTap, isNull);
    },
  );

  testWidgets(
    'Issue #11 AC: 보충 질문은 최대 1회만 발생한다 — completing it once, then '
    're-submitting another utterance that would need follow-up skips straight to confirm',
    (WidgetTester tester) async {
      await reachUtteranceScreen(tester);

      await tester.enterText(find.byType(TextField), '비슷한 제품이어도 괜찮아요');
      await tester.pump();
      await tester.tap(find.text('고객 의도 구조화하기'));
      await tester.pumpAndSettle();
      expect(find.text('고객 의도 입력 - 보충 질문'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '오늘 바로 사고 싶어요');
      await tester.pump();
      await tester.tap(find.text('답변 제출 후 의도 확인'));
      await tester.pumpAndSettle();
      expect(find.text('고객 의도 요약 확인'), findsOneWidget);

      // Back to the utterance screen (Confirm -> FollowUp -> Utterance),
      // then submit a NEW utterance that would independently trigger
      // needsFollowUp again per the mock's own '비슷' rule. Each context is
      // grabbed fresh from whatever's on screen right now — a context
      // captured before these transitions gets deactivated once its
      // element is rebuilt away (e.g. by the loading/success state swap).
      Navigator.of(tester.element(find.text('고객 의도 요약 확인'))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('고객 의도 입력 - 보충 질문'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('고객 의도 입력'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '비슷한 걸로 다시 확인해주세요');
      await tester.pump();
      await tester.tap(find.text('고객 의도 구조화하기'));
      await tester.pumpAndSettle();

      // Must land on the confirm screen directly — never a second visit to
      // the follow-up screen.
      expect(find.text('고객 의도 요약 확인'), findsOneWidget);
      expect(find.text('고객 의도 입력 - 보충 질문'), findsNothing);
    },
  );

  testWidgets('구조화 요청이 실패하면 에러 카드가 뜨고, 뒤로가기로 입력창에 남아있는 텍스트를 '
      '고쳐서 다시 제출할 수 있다', (WidgetTester tester) async {
    final _ThrowingRepository repository = _ThrowingRepository();
    await reachUtteranceScreen(tester, repository: repository);

    repository.shouldThrow = true;
    await tester.enterText(find.byType(TextField), '편한 느낌이면 좋겠어요');
    await tester.pump();
    await tester.tap(find.text('고객 의도 구조화하기'));
    await tester.pumpAndSettle();

    expect(find.text('고객 의도 분석에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);
    // The error card replaces the text field entirely — nothing to edit.
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('뒤로가기'));
    await tester.pump();

    // Back to the editable input, with the previously typed text intact.
    expect(find.text('고객 의도 분석에 실패했습니다. 다시 시도해 주세요.'), findsNothing);
    final Finder field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      (tester.widget(field) as TextField).controller!.text,
      '편한 느낌이면 좋겠어요',
    );

    // Revise the text and succeed on the next attempt.
    repository.shouldThrow = false;
    await tester.enterText(field, '역시 이 색상이 좋을 것 같아요');
    await tester.pump();
    await tester.tap(find.text('고객 의도 구조화하기'));
    await tester.pumpAndSettle();

    expect(find.text('고객 의도 요약 확인'), findsOneWidget);
  });
}
