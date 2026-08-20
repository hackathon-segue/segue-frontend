import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_additional_consultation_screen.dart';
import 'package:segue_frontend/screens/last_intent_card_screen.dart';

/// Issue #46: ADDITIONAL_CONSULTATION must route to
/// [LastIntentAdditionalConsultationScreen], never treated as a 4th
/// product-recommendation result.
class _AdditionalConsultationRepository extends MockSegueRepository {
  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    return const DecisionResult(
      resultType: DecisionResultType.additionalConsultation,
      coreConditions: '복수의 조건이 명확하지 않습니다.',
      nextAction: '고객과 함께 핵심 조건을 다시 확인합니다.',
      reason: '필수 조건과 선호 조건이 상충됩니다.',
      difference: '',
      recommendedProduct: null,
      pathDescription: '',
      actionType: DecisionActionType.reconsult,
      actionButtonLabel: '조건 다시 확인하기',
    );
  }
}

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

    // Issue #46: Card's summary card shows a "제안 제품" line (populated with
    // the recommended product's name) when recommendedProduct exists —
    // deeper 제안 제품 vs 확보 경로 rendering now lives on the result-detail
    // screen this CTA navigates to.
    expect(find.text('제안 제품'), findsOneWidget);
    expect(find.text('MCM 백팩 미디움 (블랙)'), findsOneWidget);
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
    'tapping the single CTA navigates by resultType instead of calling execute() directly',
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

      // Issue #46: Card's CTA only navigates — EXACT_PRODUCT goes to the
      // shared result-detail screen (159:2295), which shows its own real
      // execute() CTA. execute() itself hasn't been called yet.
      expect(find.text('정확한 제품 확인'), findsOneWidget);
      expect(session.state.executionResponse, isNull);
      expect(session.state.executionStatus, isNull);
    },
  );

  testWidgets('ADDITIONAL_CONSULTATION routes to the additional-consultation screen, not a product screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: _AdditionalConsultationRepository(),
    );
    final CartItem item = cartItem(1, 'MCM 백팩 미디움');
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: item,
    );
    await session.structureIntent('그냥 비슷한 느낌이면 다 좋아요');
    await session.decide();

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(home: LastIntentCardScreen(customer: customer, cartItem: item)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('조건 다시 확인하기'));
    await tester.pumpAndSettle();

    expect(find.byType(LastIntentAdditionalConsultationScreen), findsOneWidget);
    // Appears twice now: the screenTitle, and the "추가 상담 진행" toggle
    // checkbox's own label (169:3683/169:3821's real 진행/미진행 toggle).
    expect(find.text('추가 상담 진행'), findsWidgets);
  });
}
