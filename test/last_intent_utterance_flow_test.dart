import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';

/// Issue #10: structureIntent request/response flow, retry, and per-SKU
/// isolation of the structured result. LastIntentSessionController.
/// structureIntent itself predates this issue (Issue #7/#8) — these tests
/// exercise it through LastIntentSessionManager, the way the new
/// LastIntentUtteranceScreen actually calls it.
class _SpyRepository extends MockSegueRepository {
  StructureIntentRequest? lastRequest;
  int callCount = 0;
  bool shouldThrow = false;
  bool followUpAnswerShouldThrow = false;
  int followUpAnswerCallCount = 0;

  @override
  Future<StructureIntentResponse> structureIntent(StructureIntentRequest request) async {
    lastRequest = request;
    callCount++;
    if (shouldThrow) {
      throw const AppException('AI 분석에 실패했습니다.', code: 'AI_INTENT_FAILED');
    }
    return super.structureIntent(request);
  }

  @override
  Future<StructureIntentResponse> submitFollowUpAnswer(FollowUpAnswerRequest request) async {
    followUpAnswerCallCount++;
    if (followUpAnswerShouldThrow) {
      throw const AppException('답변 제출에 실패했습니다.', code: 'AI_FOLLOWUP_FAILED');
    }
    return super.submitFollowUpAnswer(request);
  }
}

void main() {
  late _SpyRepository repository;
  late LastIntentSessionManager manager;

  const Customer customer = Customer(
    id: 1,
    name: '김세계',
    phoneNumber: '010-1234-5678',
    hasConsented: true,
  );

  CartItem cartItem(int skuId) {
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': skuId,
      'productId': skuId,
      'productName': 'MCM 백팩',
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

  setUp(() {
    repository = _SpyRepository();
    manager = LastIntentSessionManager(repository: repository);
  });

  test('structureIntent sets the loading state before the request resolves', () async {
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(1),
    );

    // structureIntent() sets intentState to loading synchronously before
    // its first await, so this is true immediately — without awaiting the
    // call — proving the AC ("AI 분석 중 loading 상태가 표시된다") independently
    // of how fast the mock repository itself resolves.
    final Future<void> pending = session.structureIntent('편한 느낌이면 좋겠어요');
    expect(session.state.intentState.isLoading, isTrue);

    await pending;
    expect(session.state.intentState.hasData, isTrue);
  });

  test('submitting an utterance sends the selected store/SKU context', () async {
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(1),
    );

    await session.structureIntent('편한 느낌이면 좋겠어요');

    expect(repository.lastRequest?.skuId, 1);
    expect(repository.lastRequest?.storeId, session.state.storeId);
    expect(repository.lastRequest?.utterance, '편한 느낌이면 좋겠어요');
    expect(session.state.intentState.hasData, isTrue);
    expect(session.state.structuredIntent, isNotNull);
  });

  test('a failed request surfaces an error state and retry resends the request', () async {
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(1),
    );

    repository.shouldThrow = true;
    await session.structureIntent('편한 느낌이면 좋겠어요');
    expect(session.state.intentState.hasError, isTrue);
    expect(repository.callCount, 1);

    repository.shouldThrow = false;
    await session.structureIntent(session.state.utterance);
    expect(repository.callCount, 2);
    expect(session.state.intentState.hasData, isTrue);
  });

  test(
    'a failed follow-up answer submission surfaces an error state and retry resends it',
    () async {
      final LastIntentSessionController session = manager.sessionFor(
        customer: customer,
        cartItem: cartItem(1),
      );
      await session.structureIntent('비슷한 제품도 괜찮아요');
      await session.requestFollowUpQuestion();
      expect(session.state.followUpQuestion, isNotNull);

      repository.followUpAnswerShouldThrow = true;
      await session.submitFollowUpAnswer('오늘 바로 사고 싶어요');
      expect(session.state.intentState.hasError, isTrue);
      expect(repository.followUpAnswerCallCount, 1);
      // The answer itself is still recorded even though the request failed
      // — so the CA doesn't have to retype it before retrying.
      expect(session.state.followUpAnswer, '오늘 바로 사고 싶어요');

      repository.followUpAnswerShouldThrow = false;
      await session.submitFollowUpAnswer(session.state.followUpAnswer);
      expect(repository.followUpAnswerCallCount, 2);
      expect(session.state.intentState.hasData, isTrue);
    },
  );

  test(
    'switching between SKUs (product A -> product B -> back to A) never mixes their data',
    () async {
      final LastIntentSessionController sessionA = manager.sessionFor(
        customer: customer,
        cartItem: cartItem(1),
      );

      // Product A: submit an answer.
      await sessionA.structureIntent('비슷한 제품도 괜찮아요');
      expect(sessionA.state.intentState.data?.needsFollowUp, isTrue);
      expect(sessionA.state.utterance, '비슷한 제품도 괜찮아요');

      // Switch to product B: it must start with no trace of A's answer.
      final LastIntentSessionController sessionB = manager.sessionFor(
        customer: customer,
        cartItem: cartItem(2),
      );
      expect(sessionB.state.utterance, isEmpty);
      expect(sessionB.state.structuredIntent, isNull);
      expect(sessionB.state.intentState.hasData, isFalse);

      await sessionB.structureIntent('편한 느낌이면 좋겠어요');
      expect(sessionB.state.intentState.data?.needsFollowUp, isFalse);

      // Switching back to A returns the SAME instance with A's own data
      // still intact — visiting B did not overwrite or reset it.
      final LastIntentSessionController sessionAAgain = manager.sessionFor(
        customer: customer,
        cartItem: cartItem(1),
      );
      expect(identical(sessionAAgain, sessionA), isTrue);
      expect(sessionAAgain.state.utterance, '비슷한 제품도 괜찮아요');
      expect(sessionAAgain.state.intentState.data?.needsFollowUp, isTrue);
    },
  );
}
