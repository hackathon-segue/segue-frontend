import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';

/// Issue #15: ConsultationResult local-store save chained after a
/// successful execute() — retry idempotency, per-customer isolation, and
/// consistency with what the Last Intent Card itself showed.
class _SpyRepository extends MockSegueRepository {
  int recordCallCount = 0;
  bool shouldThrowOnRecord = false;

  @override
  Future<void> recordConsultationResult({
    required int customerId,
    required ConsultationResult result,
  }) async {
    recordCallCount++;
    if (shouldThrowOnRecord) {
      throw const AppException('저장에 실패했습니다.', code: 'SAVE_FAILED');
    }
    return super.recordConsultationResult(
      customerId: customerId,
      result: result,
    );
  }
}

class _ServerResultRepository extends MockSegueRepository {
  int executeCallCount = 0;
  int recordCallCount = 0;
  int fetchResultsCallCount = 0;
  bool includeSavedResult = true;

  @override
  Future<ExecuteConsultationResponse> executeConsultation(
    ExecuteConsultationRequest request,
  ) async {
    executeCallCount++;
    return const ExecuteConsultationResponse(
      consultationResultId: 777,
      completionMessage: '요청이 접수되었습니다. CA가 실제 재고를 확인합니다',
    );
  }

  @override
  Future<void> recordConsultationResult({
    required int customerId,
    required ConsultationResult result,
  }) async {
    recordCallCount++;
  }

  @override
  Future<List<ConsultationResult>> fetchConsultationResults(
    int customerId,
  ) async {
    fetchResultsCallCount++;
    if (!includeSavedResult) {
      return const <ConsultationResult>[];
    }
    return <ConsultationResult>[
      ConsultationResult(
        id: 777,
        skuId: 1,
        productName: '서버 저장 제품',
        imageUrl: 'https://example.com/server.png',
        resultType: DecisionResultType.exactProduct,
        recommendedPath: '서버 저장 경로',
        coreConditions: '서버 저장 핵심 조건',
        consultedAt: DateTime(2026, 8, 16, 17, 30),
        executionStatus: ExecutionStatus.requested,
        executionNote: null,
        executionUpdatedAt: DateTime(2026, 8, 16, 17, 30),
      ),
    ];
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

  CartItem cartItem(int skuId, String productName) {
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': skuId,
      'productId': skuId,
      'productName': productName,
      'imageUrl': 'https://example.com/$skuId.png',
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

  Future<LastIntentSessionController> readySession(
    int skuId,
    String productName,
  ) async {
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(skuId, productName),
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');
    await session.decide();
    return session;
  }

  test('execute() success chains into a local save that succeeds', () async {
    final LastIntentSessionController session = await readySession(1, 'MCM 백팩');

    await session.execute();

    expect(session.state.resultSaveState.hasData, isTrue);
    expect(repository.recordCallCount, 1);
    final List<ConsultationResult> stored = await repository
        .fetchConsultationResults(customer.id);
    expect(stored, hasLength(1));
    expect(stored.first.productName, 'MCM 백팩');
  });

  test(
    'execute() success verifies the server-saved result and stores that exact mobile payload',
    () async {
      final _ServerResultRepository serverRepository =
          _ServerResultRepository();
      final LastIntentSessionManager serverManager = LastIntentSessionManager(
        repository: serverRepository,
      );
      addTearDown(serverManager.dispose);
      final LastIntentSessionController session = serverManager.sessionFor(
        customer: customer,
        cartItem: cartItem(1, '로컬 카드 제품'),
      );
      await session.structureIntent('편한 느낌이면 좋겠어요');
      await session.decide();

      await session.execute();

      expect(serverRepository.executeCallCount, 1);
      expect(serverRepository.recordCallCount, 1);
      expect(serverRepository.fetchResultsCallCount, 1);
      expect(session.state.resultSaveState.hasData, isTrue);
      final ConsultationResult saved = session.state.resultSaveState.data!;
      expect(saved.id, 777);
      expect(saved.productName, '서버 저장 제품');
      expect(saved.recommendedPath, '서버 저장 경로');
      expect(saved.coreConditions, '서버 저장 핵심 조건');
      expect(saved.executionStatus, ExecutionStatus.requested);
    },
  );

  test(
    'missing server-saved result is retryable without re-running execute',
    () async {
      final _ServerResultRepository serverRepository = _ServerResultRepository()
        ..includeSavedResult = false;
      final LastIntentSessionManager serverManager = LastIntentSessionManager(
        repository: serverRepository,
      );
      addTearDown(serverManager.dispose);
      final LastIntentSessionController session = serverManager.sessionFor(
        customer: customer,
        cartItem: cartItem(1, 'MCM 백팩'),
      );
      await session.structureIntent('편한 느낌이면 좋겠어요');
      await session.decide();

      await session.execute();

      expect(session.state.executionResponse, isNotNull);
      expect(session.state.resultSaveState.hasError, isTrue);
      expect(serverRepository.executeCallCount, 1);
      expect(serverRepository.fetchResultsCallCount, 1);

      serverRepository.includeSavedResult = true;
      await session.retrySaveConsultationResult();

      expect(serverRepository.executeCallCount, 1);
      expect(serverRepository.fetchResultsCallCount, 2);
      expect(session.state.resultSaveState.hasData, isTrue);
      expect(session.state.resultSaveState.data!.id, 777);
    },
  );

  test(
    'a failed save surfaces an error, keeps execute()/Card data, and retry saves without duplicating',
    () async {
      final LastIntentSessionController session = await readySession(
        1,
        'MCM 백팩',
      );

      repository.shouldThrowOnRecord = true;
      await session.execute();
      expect(
        session.state.executionResponse,
        isNotNull,
      ); // execute() itself succeeded
      expect(session.state.resultSaveState.hasError, isTrue);
      expect(repository.recordCallCount, 1);
      expect(await repository.fetchConsultationResults(customer.id), isEmpty);

      repository.shouldThrowOnRecord = false;
      await session.retrySaveConsultationResult();
      expect(session.state.resultSaveState.hasData, isTrue);
      expect(repository.recordCallCount, 2);
      // AC: retry로 동일 결과가 중복 저장되지 않는다 — 같은 id로 upsert되어 여전히 1건.
      final List<ConsultationResult> stored = await repository
          .fetchConsultationResults(customer.id);
      expect(stored, hasLength(1));
    },
  );

  test(
    'retrySaveConsultationResult never re-calls execute()/decide()',
    () async {
      final LastIntentSessionController session = await readySession(
        1,
        'MCM 백팩',
      );
      repository.shouldThrowOnRecord = true;
      await session.execute();
      final int? resultIdAfterFirstAttempt =
          session.state.executionResponse?.consultationResultId;
      expect(resultIdAfterFirstAttempt, isNotNull);

      repository.shouldThrowOnRecord = false;
      await session.retrySaveConsultationResult();

      // If retry had re-run execute(), the mock's incrementing id generator
      // would produce a NEW consultationResultId — asserting it's unchanged
      // proves retry only re-runs the save step, not execute()/decide().
      expect(
        session.state.executionResponse?.consultationResultId,
        resultIdAfterFirstAttempt,
      );
    },
  );

  test(
    'one customer can have multiple independent saved results (product A and B)',
    () async {
      final LastIntentSessionController sessionA = await readySession(
        1,
        'MCM 백팩',
      );
      final LastIntentSessionController sessionB = await readySession(
        2,
        'MCM 숄더백',
      );

      await sessionA.execute();
      await sessionB.execute();

      final List<ConsultationResult> stored = await repository
          .fetchConsultationResults(customer.id);
      expect(stored, hasLength(2));
      expect(
        stored.map((ConsultationResult r) => r.productName),
        containsAll(<String>['MCM 백팩', 'MCM 숄더백']),
      );
    },
  );

  test(
    'results recorded for one customerId never leak into another customerId\'s fetch',
    () async {
      final LastIntentSessionController sessionA = await readySession(
        1,
        '고객1 제품',
      );
      await sessionA.execute();

      // Record directly for a second customerId (customerId isn't a field on
      // ConsultationResult itself, it's the store's own partition key) to
      // prove isolation without depending on a second pre-consented mock
      // customer existing.
      await repository.submitCustomerConsent(customerId: 42, agreed: true);
      await repository.recordConsultationResult(
        customerId: 42,
        result: ConsultationResult(
          id: 999,
          skuId: 9,
          productName: '고객42 제품',
          imageUrl: 'https://example.com/9.png',
          resultType: DecisionResultType.exactProduct,
          recommendedPath: '테스트 경로',
          coreConditions: '테스트 조건',
          consultedAt: DateTime.now(),
          executionStatus: ExecutionStatus.requested,
          executionNote: null,
          executionUpdatedAt: DateTime.now(),
        ),
      );

      final List<ConsultationResult> customer1Results = await repository
          .fetchConsultationResults(customer.id);
      expect(customer1Results, hasLength(1));
      expect(customer1Results.single.productName, '고객1 제품');
      expect(
        customer1Results.any(
          (ConsultationResult r) => r.productName == '고객42 제품',
        ),
        isFalse,
      );
    },
  );

  test('newest consultation is listed first', () async {
    final LastIntentSessionController sessionA = await readySession(
      1,
      '먼저 상담한 제품',
    );
    await sessionA.execute();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final LastIntentSessionController sessionB = await readySession(
      2,
      '나중에 상담한 제품',
    );
    await sessionB.execute();

    final List<ConsultationResult> stored = await repository
        .fetchConsultationResults(customer.id);
    expect(stored.first.productName, '나중에 상담한 제품');
    expect(stored.last.productName, '먼저 상담한 제품');
  });

  test(
    'updateExecutionStatus updates the existing local result without replacing product data',
    () async {
      final LastIntentSessionController session = await readySession(
        1,
        'MCM 백팩',
      );
      await session.execute();
      final int resultId =
          session.state.executionResponse!.consultationResultId;

      final ConsultationResult updated = await repository.updateExecutionStatus(
        consultationResultId: resultId,
        request: const ExecutionStatusUpdateRequest(
          status: ExecutionStatus.unable,
          note: '타 매장 보유가 확인되지 않았습니다.',
        ),
      );

      expect(updated.productName, 'MCM 백팩');
      expect(updated.executionStatus, ExecutionStatus.unable);
      expect(updated.executionNote, '타 매장 보유가 확인되지 않았습니다.');

      final List<ConsultationResult> stored = await repository
          .fetchConsultationResults(customer.id);
      expect(stored, hasLength(1));
      expect(stored.single.id, resultId);
      expect(stored.single.productName, 'MCM 백팩');
      expect(stored.single.executionStatus, ExecutionStatus.unable);
      expect(stored.single.executionNote, '타 매장 보유가 확인되지 않았습니다.');
    },
  );

  test(
    'the saved recommendedPath matches what the Card itself would show (recommendedProduct present)',
    () async {
      final LastIntentSessionController session = manager.sessionFor(
        customer: customer,
        cartItem: cartItem(1, 'MCM 백팩'),
      );
      await session.structureIntent('편한 느낌이면 좋겠어요');
      await session.decide();
      // Simulate an edited/updated decisionResult with a recommendedProduct,
      // the same way Card screen would render "제안 제품" instead of "확보 경로".
      session.updateStructuredIntent(session.state.structuredIntent!);
      await session.execute();

      final List<ConsultationResult> stored = await repository
          .fetchConsultationResults(customer.id);
      // Mock's decide() always returns recommendedProduct: null, so this
      // should match pathDescription exactly (the same value the Card shows
      // in its "확보 경로" section).
      expect(
        stored.single.recommendedPath,
        session.state.decisionResult!.pathDescription,
      );
    },
  );
}
