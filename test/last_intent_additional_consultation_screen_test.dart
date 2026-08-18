import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_additional_consultation_screen.dart';
import 'package:segue_frontend/screens/last_intent_completion_screen.dart';

/// Issue #46: ADDITIONAL_CONSULTATION detail screen (Figma 169:3683/3821).
///
/// Deliberately does NOT test for Figma's 진행/미진행 toggle or "고객 답변
/// 입력하기"/"실행 불가 사유" textareas — those have no backing API field and
/// conflict with this issue's explicit single-CTA rule, so the
/// implementation replaces them with the real actionButtonLabel CTA (see
/// the doc comment on the screen itself).
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

  testWidgets('shows the real coreConditions/reason data, never a hardcoded 진행/미진행 toggle', (
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

    expect(find.text('추가 상담 진행'), findsOneWidget);
    expect(find.text('이전 상담 요약'), findsOneWidget);
    expect(find.text('복수의 조건이 명확하지 않아 우선순위를 확인하지 못했습니다.'), findsOneWidget);
    // Real actionButtonLabel — not Figma's example "요청 접수 완료"/"해당 제품 상담 중단".
    expect(find.text('조건 다시 확인하기'), findsOneWidget);
    expect(find.text('요청 접수 완료'), findsNothing);
    expect(find.text('해당 제품 상담 중단'), findsNothing);
    expect(find.text('추가 상담 미진행'), findsNothing);
    expect(find.text('고객 답변 입력하기'), findsNothing);
  });

  testWidgets('tapping the single CTA calls execute() with RECONSULT and reaches completion', (
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

    await tester.tap(find.text('조건 다시 확인하기'));
    await tester.pumpAndSettle();

    expect(find.byType(LastIntentCompletionScreen), findsOneWidget);
    expect(session.state.decisionResult!.actionType, DecisionActionType.reconsult);
    expect(session.state.executionStatus, ExecutionStatus.requested);
  });
}
