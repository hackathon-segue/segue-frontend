import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_demo_fixtures.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';

void main() {
  test('mock fixture exposes exactly the SCHEMA.md demo scenarios A-D', () {
    expect(
      MockDemoFixtures.scenarios.map(
        (MockDemoScenario scenario) => scenario.id.label,
      ),
      <String>['A', 'B', 'C', 'D'],
    );
  });

  test(
    'mock fixture StructuredIntent values stay inside API.md vocabulary',
    () {
      const Map<String, List<String>> allowedVocabulary =
          <String, List<String>>{
            'colorFamily': <String>['블랙', '브라운', '베이지'],
            'colorTone': <String>['웜', '쿨', '뉴트럴'],
            'material': <String>['가죽', '캔버스', '패브릭'],
            'glossLevel': <String>['높음', '중간', '낮음'],
            'logoVisibility': <String>['높음', '중간', '낮음'],
            'logoPosition': <String>['정면중앙', '정면하단', '스트랩'],
            'patternDensity': <String>['높음', '중간', '낮음'],
            'silhouette': <String>['각진', '라운드', '사각'],
            'structure': <String>['하드', '소프트'],
            'sizeGrade': <String>['미니', '스몰', '미디움', '라지'],
            'strapType': <String>['체인스트랩', '패브릭스트랩', '패브릭+레더콤보', '벨트스트랩'],
            'hardwareColor': <String>['골드', '실버', '건메탈'],
            'usageContext': <String>['데일리', '오피스', '이브닝'],
            'weightGrade': <String>['가벼움', '보통', '무거움'],
            'lockType': <String>['지퍼', '플립', '마그네틱'],
            'internalStorageLevel': <String>['심플', '구획많음'],
            'laptopCompatible': <String>['true', 'false'],
          };

      void expectVocabulary(Map<String, String> values) {
        for (final MapEntry<String, String> entry in values.entries) {
          expect(allowedVocabulary.keys, contains(entry.key));
          expect(allowedVocabulary[entry.key], contains(entry.value));
        }
      }

      for (final MockDemoScenario scenario in MockDemoFixtures.scenarios) {
        for (final StructuredIntent intent in <StructuredIntent>[
          scenario.initialIntent,
          scenario.finalIntent,
        ]) {
          expectVocabulary(intent.essentialConditions);
          expectVocabulary(intent.preferredConditions);
          expectVocabulary(intent.negotiableConditions);
          for (final String key in intent.physicalCheckAttributes) {
            expect(allowedVocabulary.keys, contains(key));
          }
        }
      }
    },
  );

  group('SCHEMA.md demo scenario QA', () {
    for (final MockDemoScenario scenario in MockDemoFixtures.scenarios) {
      test(
        'Scenario ${scenario.id.label}: ${scenario.title} reaches the expected saved result',
        () async {
          final MockSegueRepository repository = MockSegueRepository();
          final Customer customer = await repository.lookupCustomerByPhone(
            MockDemoFixtures.consentedCustomerPhone,
          );
          final List<CartItem> cartItems = await repository.fetchCart(
            customerId: customer.id,
            storeId: MockDemoFixtures.storeId,
          );
          final CartItem originalItem = cartItems.firstWhere(
            (CartItem item) => item.skuId == MockDemoFixtures.originalSkuId,
          );
          final LastIntentSessionManager manager = LastIntentSessionManager(
            repository: repository,
          );
          addTearDown(manager.dispose);

          final LastIntentSessionController session = manager.sessionFor(
            customer: customer,
            cartItem: originalItem,
          );
          await session.structureIntent(scenario.utterance);

          expect(session.state.intentState.hasData, isTrue);
          expect(
            session.state.structuredIntent!.toJson(),
            scenario.initialIntent.toJson(),
          );

          if (scenario.needsFollowUp) {
            await session.requestFollowUpQuestion();
            expect(
              session.state.followUpQuestion?.question,
              MockDemoFixtures.defaultFollowUpQuestion.question,
            );
            await session.submitFollowUpAnswer(scenario.followUpAnswer!);
          }

          expect(
            session.state.structuredIntent!.toJson(),
            scenario.finalIntent.toJson(),
          );

          await session.decide();
          expect(session.state.decisionState.hasData, isTrue);
          expect(
            session.state.decisionResult!.toJson(),
            scenario.decisionResult.toJson(),
          );

          await session.execute();
          expect(session.state.executionStatus, ExecutionStatus.requested);
          expect(session.state.executionState.hasData, isTrue);
          expect(session.state.resultSaveState.hasData, isTrue);

          final List<ConsultationResult> storedResults = await repository
              .fetchConsultationResults(customer.id);
          expect(storedResults, hasLength(1));
          final ConsultationResult saved = storedResults.single;
          final ProductSkuSummary? recommended =
              scenario.decisionResult.recommendedProduct;
          final String expectedSavedPath = recommended == null
              ? scenario.decisionResult.pathDescription
              : '${recommended.productName} (${recommended.color})';

          expect(saved.skuId, MockDemoFixtures.originalSkuId);
          expect(saved.productName, MockDemoFixtures.originalProductName);
          expect(saved.resultType, scenario.decisionResult.resultType);
          expect(saved.recommendedPath, expectedSavedPath);
          expect(saved.coreConditions, scenario.decisionResult.coreConditions);
          expect(saved.executionStatus, ExecutionStatus.requested);
          expect(saved.executionNote, isNull);
        },
      );
    }
  });

  test(
    'unmatched utterances keep the default exact-product demo path',
    () async {
      final MockSegueRepository repository = MockSegueRepository();
      final StructureIntentResponse response = await repository.structureIntent(
        const StructureIntentRequest(
          storeId: MockDemoFixtures.storeId,
          skuId: MockDemoFixtures.originalSkuId,
          utterance: '편한 느낌이면 좋겠어요',
        ),
      );
      final DecisionResult result = await repository.decide(
        DecisionRequest(
          storeId: MockDemoFixtures.storeId,
          skuId: MockDemoFixtures.originalSkuId,
          structuredIntent: response.structuredIntent,
        ),
      );

      expect(response.needsFollowUp, isFalse);
      expect(result.toJson(), MockDemoFixtures.scenarioAResult.toJson());
    },
  );
}
