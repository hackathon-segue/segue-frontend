import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_card_screen.dart';

/// Issue #14: a decide() response containing forbidden language must never
/// render as-is — MockSegueRepository's real decide() never produces this,
/// so this spy fakes a "bad AI response" to prove the fallback fires.
class _ForbiddenLanguageRepository extends MockSegueRepository {
  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    return const DecisionResult(
      resultType: DecisionResultType.exactProduct,
      coreConditions: '적합도 95%로 이 제품이 BEST MATCH 입니다.',
      nextAction: '해당 컬러는 품절이라 대체품을 안내합니다.',
      reason: '테스트용 사유',
      difference: '테스트용 차이',
      recommendedProduct: null,
      pathDescription: '테스트 경로',
      actionType: DecisionActionType.otherStoreCheckRequest,
      actionButtonLabel: '타 매장 확인 요청',
    );
  }
}

/// Issue #13: recommendedProduct-driven branching (제안 제품 vs 확보 경로) and
/// per-SKU isolation of the Last Intent Card result.
///
/// MockSegueRepository.decide() always returns recommendedProduct: null, so
/// the "제안 제품" branch is otherwise never exercised — this spies to
/// return a populated recommendedProduct instead.
class _RecommendedProductRepository extends MockSegueRepository {
  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    return const DecisionResult(
      resultType: DecisionResultType.comparisonExperience,
      coreConditions: '가벼운 소재와 데일리 사용 가능한 사이즈를 중요하게 보셨습니다.',
      nextAction: '비교 체험 제품을 매장에서 바로 확인해 드릴 수 있습니다.',
      reason: '원하시는 컬러는 없지만 동일 라인 제품을 지금 체험하실 수 있습니다.',
      difference: '컬러만 다르고 소재/사이즈 조건은 동일하게 충족합니다.',
      recommendedProduct: ProductSkuSummary(
        skuId: 9,
        productId: 9,
        productName: 'MCM 백팩 미디움 (블랙)',
        imageUrl: 'https://example.com/mcm-backpack-black.png',
        color: '블랙',
        size: '미디움',
      ),
      pathDescription: '매장 내 비교 체험',
      actionType: DecisionActionType.productCheckRequest,
      actionButtonLabel: '비교 체험 제품 확인하기',
    );
  }
}

void main() {
  CartItem cartItem(int skuId, String name) {
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': skuId,
      'productId': skuId,
      'productName': name,
      'imageUrl': 'https://example.com/x.png',
      'category': '백팩',
      'skuId': skuId,
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

  testWidgets('recommendedProduct != null shows 제안 제품, never 확보 경로', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: _RecommendedProductRepository(),
    );
    final CartItem item = cartItem(1, 'MCM 백팩 미디움');
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: item,
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');
    await session.decide();
    expect(session.state.decisionResult!.recommendedProduct, isNotNull);

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(home: LastIntentCardScreen(customer: customer, cartItem: item)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('제안 제품'), findsOneWidget);
    expect(find.text('MCM 백팩 미디움 (블랙)'), findsOneWidget);
    expect(find.text('확보 경로'), findsNothing);
    expect(find.text('비교 체험 제품 확인하기'), findsOneWidget);
    // Exactly one CTA — no alternate/second button anywhere on the card.
    expect(find.text('타 매장 확인 요청'), findsNothing);
  });

  test('decide() sets the loading state before the request resolves', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: MockSegueRepository(),
    );
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(1, 'A'),
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');

    // decide() sets decisionState to loading synchronously before its
    // first await, so this is true immediately — without awaiting the
    // call — proving the AC ("loading 상태가 명확하게 보인다") independently of
    // how fast the mock repository itself resolves.
    final Future<void> pending = session.decide();
    expect(session.state.decisionState.isLoading, isTrue);

    await pending;
    expect(session.state.decisionState.hasData, isTrue);
  });

  test('each SKU keeps its own decisionResult — product A and B never mix', () async {
    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: MockSegueRepository(),
    );
    final LastIntentSessionController sessionA = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(1, 'A'),
    );
    final LastIntentSessionController sessionB = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(2, 'B'),
    );

    await sessionA.structureIntent('편한 느낌이면 좋겠어요');
    await sessionA.decide();
    expect(sessionA.state.decisionResult, isNotNull);
    expect(sessionB.state.decisionResult, isNull);

    await sessionB.structureIntent('편한 느낌이면 좋겠어요');
    await sessionB.decide();
    expect(sessionB.state.decisionResult, isNotNull);

    // Switching back to A (via the manager, as every screen does) still
    // returns the SAME instance with A's own decisionResult intact.
    final LastIntentSessionController sessionAAgain = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(1, 'A'),
    );
    expect(identical(sessionAAgain, sessionA), isTrue);
    expect(sessionAAgain.state.decisionResult, isNotNull);
  });

  testWidgets(
    'a decide() result with forbidden language never renders — shows the fallback instead',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final LastIntentSessionManager manager = LastIntentSessionManager(
        repository: _ForbiddenLanguageRepository(),
      );
      final CartItem item = cartItem(1, 'MCM 백팩 미디움');
      final LastIntentSessionController session = manager.sessionFor(
        customer: customer,
        cartItem: item,
      );
      await session.structureIntent('편한 느낌이면 좋겠어요');
      await session.decide();
      expect(session.state.decisionResult, isNotNull); // decide() itself succeeded

      await tester.pumpWidget(
        LastIntentSessionScope(
          manager: manager,
          child: MaterialApp(home: LastIntentCardScreen(customer: customer, cartItem: item)),
        ),
      );
      await tester.pumpAndSettle();

      // None of the raw forbidden text ever reaches the screen.
      expect(find.textContaining('품절'), findsNothing);
      expect(find.textContaining('대체품'), findsNothing);
      expect(find.textContaining('BEST MATCH', findRichText: true), findsNothing);
      expect(find.textContaining('95%'), findsNothing);
      expect(find.text('결과를 표시할 수 없습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the single CTA calls execute() and reaches the 요청 접수 완료 screen with the right message',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final LastIntentSessionManager manager = LastIntentSessionManager(
        repository: MockSegueRepository(),
      );
      final CartItem item = cartItem(1, 'MCM 백팩 미디움');
      final LastIntentSessionController session = manager.sessionFor(
        customer: customer,
        cartItem: item,
      );
      await session.structureIntent('편한 느낌이면 좋겠어요');
      await session.decide();
      expect(session.state.decisionResult!.actionType, DecisionActionType.otherStoreCheckRequest);

      await tester.pumpWidget(
        LastIntentSessionScope(
          manager: manager,
          child: MaterialApp(home: LastIntentCardScreen(customer: customer, cartItem: item)),
        ),
      );
      await tester.pumpAndSettle();

      final Finder cta = find.text('타 매장 확인 요청');
      expect(cta, findsOneWidget); // exactly one CTA on the card
      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('요청 접수 완료'), findsOneWidget);
      expect(find.text('접수됨'), findsOneWidget); // REQUESTED status label
      // Figma node 14:2301 "접수 내용" — the actual request type, sourced from
      // the same actionButtonLabel the Card's single CTA showed.
      expect(find.text('타 매장 확인 요청'), findsOneWidget);
      // AC: never implies the real-world action itself is done.
      expect(find.textContaining('완료'), findsWidgets); // only in "요청 접수 완료"/disclaimer, not "구매 완료" etc.
      expect(find.textContaining('구매 완료'), findsNothing);
      expect(find.textContaining('예약 완료'), findsNothing);
      expect(find.textContaining('제품 이동 완료'), findsNothing);
      expect(session.state.executionStatus, ExecutionStatus.requested);
    },
  );
}
