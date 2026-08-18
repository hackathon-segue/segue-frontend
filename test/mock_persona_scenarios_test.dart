import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';

/// Deterministic keyword-triggered persona scenarios (SCHEMA.md 페르소나
/// 1~5) so all 4 resultTypes are reachable from the real running app, not
/// just from spy-repository widget tests. Typing these exact utterances
/// into the "고객 의도 입력" screen reproduces each result screen.
void main() {
  const Customer customer = Customer(
    id: 1,
    name: '김세계',
    phoneNumber: '010-1234-5678',
    hasConsented: true,
  );

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
      'otherStoreInStock': true,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': DateTime(2026, 8, 16).toIso8601String(),
    });
  }

  test('페르소나 1 (다이아몬드+직사각) → COMPARISON_EXPERIENCE, SKU 2', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(repository: MockSegueRepository());
    final LastIntentSessionController session = manager.sessionFor(customer: customer, cartItem: cartItem());
    await session.structureIntent('이 직사각형 형태와 다이아몬드 모양 핸들이 가장 좋아요. 색이나 소재는 달라도 괜찮아요.');
    await session.decide();

    expect(session.state.decisionResult!.resultType, DecisionResultType.comparisonExperience);
    expect(session.state.decisionResult!.recommendedProduct!.skuId, 2);
  });

  test('페르소나 2 (가죽/비세토스) → COMPARISON_EXPERIENCE, SKU 3', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(repository: MockSegueRepository());
    final LastIntentSessionController session = manager.sessionFor(customer: customer, cartItem: cartItem());
    await session.structureIntent('저는 이 모양보다 꼬냑 비세토스 가죽 패턴이 더 중요해요.');
    await session.decide();

    expect(session.state.decisionResult!.resultType, DecisionResultType.comparisonExperience);
    expect(session.state.decisionResult!.recommendedProduct!.skuId, 3);
  });

  test('페르소나 3 (노트북) → TODAY_PURCHASE, SKU 4', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(repository: MockSegueRepository());
    final LastIntentSessionController session = manager.sessionFor(customer: customer, cartItem: cartItem());
    await session.structureIntent('오늘 출장 전에 꼭 필요하고 16인치 노트북이 들어가야 해요.');
    await session.decide();

    expect(session.state.decisionResult!.resultType, DecisionResultType.todayPurchase);
    expect(session.state.decisionResult!.recommendedProduct!.skuId, 4);
  });

  test('페르소나 4 (색이나 소재가 다른 건 원하지) → EXACT_PRODUCT', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(repository: MockSegueRepository());
    final LastIntentSessionController session = manager.sessionFor(customer: customer, cartItem: cartItem());
    await session.structureIntent('색이나 소재가 다른 건 원하지 않아요. 다른 매장에 있으면 거기서 받고 싶어요.');
    await session.decide();

    expect(session.state.decisionResult!.resultType, DecisionResultType.exactProduct);
    expect(session.state.decisionResult!.recommendedProduct, isNull);
  });

  test('페르소나 5 (비슷 → 보충질문 → 여전히 모르겠음) → ADDITIONAL_CONSULTATION', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(repository: MockSegueRepository());
    final LastIntentSessionController session = manager.sessionFor(customer: customer, cartItem: cartItem());
    await session.structureIntent('그냥 비슷한 느낌의 가방이면 다 좋아요.');
    expect(session.state.structuredIntent!.needsFollowUp, isTrue);

    await session.requestFollowUpQuestion();
    await session.submitFollowUpAnswer('음.. 그것도 잘 모르겠어요');
    await session.decide();

    expect(session.state.decisionResult!.resultType, DecisionResultType.additionalConsultation);
    expect(session.state.decisionResult!.recommendedProduct, isNull);
  });

  test('기본값(키워드 미매칭 발화)은 기존 EXACT_PRODUCT 응답과 동일하게 유지된다', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(repository: MockSegueRepository());
    final LastIntentSessionController session = manager.sessionFor(customer: customer, cartItem: cartItem());
    await session.structureIntent('편한 느낌이면 좋겠어요');
    await session.decide();

    expect(session.state.decisionResult!.resultType, DecisionResultType.exactProduct);
    expect(session.state.decisionResult!.coreConditions, '로고가 정면 중앙에 오는 각진 실루엣을 중요하게 보고 계셨습니다.');
    expect(session.state.decisionResult!.actionButtonLabel, '타 매장 확인 요청');
  });
}
