import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/mock_segue_repository.dart';

/// Issue #14: execute() request/response flow, retry, executionStatus, and
/// per-SKU isolation. LastIntentSessionController.execute() itself predates
/// this issue (Issue #7/#8) — these tests exercise it the way
/// LastIntentCardScreen actually calls it now.
class _SpyRepository extends MockSegueRepository {
  ExecuteConsultationRequest? lastRequest;
  int callCount = 0;
  bool shouldThrow = false;

  @override
  Future<ExecuteConsultationResponse> executeConsultation(
    ExecuteConsultationRequest request,
  ) async {
    lastRequest = request;
    callCount++;
    if (shouldThrow) {
      throw const AppException('요청 접수에 실패했습니다.', code: 'EXECUTE_FAILED');
    }
    return super.executeConsultation(request);
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

  Future<LastIntentSessionController> readySession(int skuId) async {
    final LastIntentSessionController session = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(skuId),
    );
    await session.structureIntent('편한 느낌이면 좋겠어요');
    await session.decide();
    return session;
  }

  test('execute() sends the current customer/SKU context and sets REQUESTED on success', () async {
    final LastIntentSessionController session = await readySession(1);

    await session.execute();

    expect(repository.lastRequest?.customerId, customer.id);
    expect(repository.lastRequest?.skuId, 1);
    expect(repository.lastRequest?.resultType, session.state.decisionResult!.resultType);
    expect(repository.lastRequest?.actionType, session.state.decisionResult!.actionType);
    expect(session.state.executionResponse, isNotNull);
    expect(session.state.executionStatus, ExecutionStatus.requested);
  });

  test('execute() sets the loading state before the request resolves', () async {
    final LastIntentSessionController session = await readySession(1);

    final Future<void> pending = session.execute();
    expect(session.state.executionState.isLoading, isTrue);

    await pending;
    expect(session.state.executionState.hasData, isTrue);
  });

  test('a failed execute() surfaces an error state, keeps prior data, and retry resends it', () async {
    final LastIntentSessionController session = await readySession(1);
    final DecisionResult? decisionResultBeforeFailure = session.state.decisionResult;

    repository.shouldThrow = true;
    await session.execute();
    expect(session.state.executionState.hasError, isTrue);
    expect(session.state.executionResponse, isNull);
    expect(session.state.executionStatus, isNull);
    expect(repository.callCount, 1);
    // AC: 실패해도 기존 Card/StructuredIntent/decide 결과는 유지된다.
    expect(session.state.decisionResult, same(decisionResultBeforeFailure));
    expect(session.state.structuredIntent, isNotNull);

    repository.shouldThrow = false;
    await session.execute();
    expect(repository.callCount, 2);
    expect(session.state.executionState.hasData, isTrue);
    expect(session.state.executionStatus, ExecutionStatus.requested);
  });

  test('completionMessage matches each actionType, not one canned string', () async {
    final MockSegueRepository mock = MockSegueRepository();
    Future<String> messageFor(DecisionActionType actionType) async {
      final ExecuteConsultationResponse response = await mock.executeConsultation(
        ExecuteConsultationRequest(
          customerId: 1,
          skuId: 1,
          resultType: DecisionResultType.exactProduct,
          actionType: actionType,
          recommendedSkuId: null,
          pathDescription: '테스트 경로',
          coreConditionsSummary: '테스트 조건',
        ),
      );
      return response.completionMessage;
    }

    expect(
      await messageFor(DecisionActionType.otherStoreCheckRequest),
      '요청이 접수되었습니다. CA가 실제 재고를 확인합니다',
    );
    expect(await messageFor(DecisionActionType.restockCheckRequest), '확인 신청이 접수되었습니다');
    expect(await messageFor(DecisionActionType.productCheckRequest), 'CA에게 제품 확인을 요청했습니다');
    expect(await messageFor(DecisionActionType.reconsult), '고객의 조건을 다시 확인합니다');

    // None of these are worded as final completion (구매/예약/이동 완료).
    for (final DecisionActionType type in DecisionActionType.values) {
      final String message = await messageFor(type);
      expect(message.contains('완료'), isFalse, reason: '"$message" must not read as final completion');
    }
  });

  test('execution results (response + status) never mix across SKUs', () async {
    final LastIntentSessionController sessionA = await readySession(1);
    final LastIntentSessionController sessionB = await readySession(2);

    await sessionA.execute();
    expect(sessionA.state.executionStatus, ExecutionStatus.requested);
    expect(sessionB.state.executionStatus, isNull);
    expect(sessionB.state.executionResponse, isNull);

    // Switching back to A (via the manager, as every screen does) still
    // returns the SAME instance with A's own execution result intact.
    final LastIntentSessionController sessionAAgain = manager.sessionFor(
      customer: customer,
      cartItem: cartItem(1),
    );
    expect(identical(sessionAAgain, sessionA), isTrue);
    expect(sessionAAgain.state.executionStatus, ExecutionStatus.requested);
  });
}
