import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';
import 'package:segue_frontend/screens/last_intent_completion_screen.dart';
import 'package:segue_frontend/screens/last_intent_result_product_screen.dart';

/// Issue #46: the shared result-detail screen for EXACT_PRODUCT /
/// COMPARISON_EXPERIENCE / TODAY_PURCHASE (Figma 159:2295/159:2173/159:3053)
/// — this is where `execute()` now actually runs (moved off the Card
/// screen, which only navigates here).
class _ComparisonRepository extends MockSegueRepository {
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
      actionButtonLabel: '이 제품 확인하기',
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
      'otherStoreInStock': true,
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

  Future<LastIntentSessionController> pumpReady(
    WidgetTester tester,
    MockSegueRepository repository,
    CartItem item,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final LastIntentSessionManager manager = LastIntentSessionManager(
      repository: repository,
    );
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: item,
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');
    await session.decide();

    await tester.pumpWidget(
      LastIntentSessionScope(
        manager: manager,
        child: MaterialApp(
          home: LastIntentResultProductScreen(
            customer: customer,
            cartItem: item,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets(
    'EXACT_PRODUCT shows the ORIGINAL cart item and inventory-derived chip/card content',
    (WidgetTester tester) async {
      final CartItem item = cartItem(1, 'MCM 백팩 미디움');
      await pumpReady(tester, MockSegueRepository(), item);

      expect(find.text('정확한 제품 확인'), findsOneWidget);
      expect(
        find.text('MCM 백팩 미디움'),
        findsOneWidget,
      ); // the ORIGINAL product, not a recommendation
      expect(find.text('제품 확보 정보'), findsOneWidget);
      expect(find.text('타 매장 확인 필요'), findsOneWidget);
      expect(find.textContaining('보유 가능성 있음 · 확인 필요 · 기준'), findsOneWidget);
      expect(find.textContaining('CA 재확인 필요'), findsOneWidget);
      // Figma-literal CTA label override (per explicit request) — the real
      // actionButtonLabel ("타 매장 확인 요청") still drives execute()'s actual
      // request payload, only the on-screen text differs.
      expect(find.text('타 매장 확인 요청 접수'), findsOneWidget);
    },
  );

  testWidgets(
    'COMPARISON_EXPERIENCE shows the recommendedProduct and difference-based card',
    (WidgetTester tester) async {
      final CartItem item = cartItem(1, 'MCM 백팩 미디움');
      final LastIntentSessionController session = await pumpReady(
        tester,
        _ComparisonRepository(),
        item,
      );
      expect(session.state.decisionResult!.recommendedProduct, isNotNull);

      expect(find.text('비교 체험 제품'), findsOneWidget);
      expect(
        find.text('MCM 백팩 미디움 (블랙)'),
        findsOneWidget,
      ); // the RECOMMENDED product
      expect(find.text('원제품과의 차이'), findsOneWidget);
      expect(find.text('컬러만 다르고 소재/사이즈 조건은 동일하게 충족합니다.'), findsOneWidget);
      expect(find.text('재고 확인 필요'), findsOneWidget);
      // Figma-literal CTA label override (159:2173) — real actionButtonLabel
      // is "이 제품 확인하기".
      expect(find.text('해당 제품 상담 완료'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the CTA calls execute() and reaches the completion screen',
    (WidgetTester tester) async {
      final CartItem item = cartItem(1, 'MCM 백팩 미디움');
      final LastIntentSessionController session = await pumpReady(
        tester,
        MockSegueRepository(),
        item,
      );

      final Finder cta = find.text('타 매장 확인 요청 접수');
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.byType(LastIntentCompletionScreen), findsOneWidget);
      expect(session.state.executionStatus, ExecutionStatus.requested);
      expect(session.state.resultSaveState.hasData, isTrue);
    },
  );
}
