import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_additional_consultation_screen.dart';
import 'package:segue_frontend/screens/last_intent_completion_screen.dart';

/// Issue #46: ADDITIONAL_CONSULTATION detail screen — Figma 169:3683 ("진행"
/// checked) / 169:3821 ("미진행" checked), a single screen with a local
/// 진행/미진행 toggle (see the doc comment on the screen itself for why the
/// toggle/free-text input have no backing API field).
class _AdditionalConsultationRepository extends MockSegueRepository {
  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    return const DecisionResult(
      resultType: DecisionResultType.additionalConsultation,
      coreConditions: '복수의 조건이 명확하지 않아 우선순위를 확인하지 못했습니다.',
      nextAction: '고객과 함께 핵심 조건을 다시 확인한 뒤 상담을 재개합니다.',
      reason: '필수 조건과 선호 조건이 상충되어 하나의 제품으로 좁혀지지 않습니다.',
      difference: '',
      recommendedProduct: null,
      pathDescription: '',
      actionType: DecisionActionType.reconsult,
      actionButtonLabel: '조건 다시 확인하기',
    );
  }
}

void main() {
  CartItem cartItem() {
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': 1,
      'productId': 1,
      'productName': 'MCM 백팩 미디움',
      'imageUrl': 'https://example.com/x.png',
      'category': '백팩',
      'skuId': 1,
      'color': '블랙',
      'size': '미디움',
      'currentStoreInStock': false,
      'otherStoreInStock': false,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': DateTime(2026, 8, 16).toIso8601String(),
    });
  }

  const Customer customer = Customer(
    id: 1,
    name: '김세계',
    phoneNumber: '010-1234-5678',
    hasConsented: true,
  );

  testWidgets('defaults to the 진행 state (169:3683) with real coreConditions/reason data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: _AdditionalConsultationRepository(),
    );
    final CartItem item = cartItem();
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: item,
    );
    await session.structureIntent('그냥 비슷한 느낌이면 다 좋아요');
    await session.decide();

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(
          home: LastIntentAdditionalConsultationScreen(customer: customer, cartItem: item),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Screen title + the toggle's own "진행" checkbox label both render
    // this string (169:3683's default checked state).
    expect(find.text('추가 상담 진행'), findsWidgets);
    expect(find.text('추가 상담 미진행'), findsOneWidget);
    expect(find.text('이전 상담 요약'), findsOneWidget);
    expect(find.text('복수의 조건이 명확하지 않아 우선순위를 확인하지 못했습니다.'), findsOneWidget);
    // Figma-literal CTA display override for the 진행 state — execute()'s
    // real payload still uses decisionResult.actionType/actionButtonLabel
    // (asserted separately below), this is on-screen text only.
    expect(find.text('요청 접수 완료'), findsOneWidget);
    expect(find.text('해당 제품 상담 중단'), findsNothing);
    expect(find.text('고객 답변 입력하기'), findsOneWidget);
    expect(find.text('실행 불가 사유 입력하기 (예: 고객 동의 거절, 시간 부족 등)'), findsNothing);
  });

  testWidgets('tapping 추가 상담 미진행 switches to the 169:3821 state instantly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: _AdditionalConsultationRepository(),
    );
    final CartItem item = cartItem();
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: item,
    );
    await session.structureIntent('그냥 비슷한 느낌이면 다 좋아요');
    await session.decide();

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(
          home: LastIntentAdditionalConsultationScreen(customer: customer, cartItem: item),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('추가 상담 미진행'));
    await tester.pump();

    expect(find.text('해당 제품 상담 중단'), findsOneWidget);
    expect(find.text('요청 접수 완료'), findsNothing);
    expect(find.text('실행 불가 사유 입력하기 (예: 고객 동의 거절, 시간 부족 등)'), findsOneWidget);
    expect(find.text('고객 답변 입력하기'), findsNothing);

    // Tapping "진행" switches straight back to the 169:3683 state.
    await tester.tap(find.text('추가 상담 진행').last);
    await tester.pump();
    expect(find.text('요청 접수 완료'), findsOneWidget);
  });

  testWidgets('tapping the CTA calls execute() with RECONSULT and reaches completion', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: _AdditionalConsultationRepository(),
    );
    final CartItem item = cartItem();
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: item,
    );
    await session.structureIntent('그냥 비슷한 느낌이면 다 좋아요');
    await session.decide();

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(
          home: LastIntentAdditionalConsultationScreen(customer: customer, cartItem: item),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('요청 접수 완료'));
    await tester.pumpAndSettle();

    expect(find.byType(LastIntentCompletionScreen), findsOneWidget);
    // execute() sends the real actionType/actionButtonLabel from
    // decisionResult regardless of the toggle's display-only CTA label.
    expect(session.state.decisionResult!.actionType, DecisionActionType.reconsult);
    expect(session.state.decisionResult!.actionButtonLabel, '조건 다시 확인하기');
    expect(session.state.executionStatus, ExecutionStatus.requested);
  });
}
