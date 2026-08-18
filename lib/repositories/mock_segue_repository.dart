import '../exceptions/app_exception.dart';
import '../models/models.dart';
import 'mobile_product_catalog.dart';
import 'mock_demo_fixtures.dart';
import 'segue_repository.dart';

class MockSegueRepository implements SegueRepository {
  MockSegueRepository({bool seedDemoConsultationResults = false}) {
    if (seedDemoConsultationResults) {
      _consultationResultsByCustomer[1] = <int, ConsultationResult>{
        5: MockDemoFixtures.seededConsultationResult(),
      };
    }
  }

  final Map<int, bool> _consents = <int, bool>{
    MockDemoFixtures.consentedCustomerId: true,
    MockDemoFixtures.unconsentedCustomerId: false,
  };
  final Map<int, List<CartItem>> _savedCartItems = <int, List<CartItem>>{};
  int _nextCartItemId = 20;

  // Issue #15: mock/local ConsultationResult store — customerId -> (result
  // id -> result). Keyed by id (not a plain list) so recordConsultationResult
  // is idempotent: retrying a save after a failure overwrites the same
  // entry instead of creating a duplicate.
  final Map<int, Map<int, ConsultationResult>> _consultationResultsByCustomer =
      <int, Map<int, ConsultationResult>>{};
  int _nextConsultationResultId = 100;

  @override
  Future<Customer> lookupCustomerByPhone(String phoneNumber) async {
    return switch (phoneNumber) {
      MockDemoFixtures.consentedCustomerPhone =>
        MockDemoFixtures.consentedCustomer,
      MockDemoFixtures.unconsentedCustomerPhone =>
        MockDemoFixtures.unconsentedCustomer,
      _ => throw const AppException(
        '회원 정보를 다시 확인해 주세요.',
        code: 'CUSTOMER_NOT_FOUND',
      ),
    };
  }

  @override
  Future<CustomerConsent> submitCustomerConsent({
    required int customerId,
    required bool agreed,
  }) async {
    _consents[customerId] = agreed;
    return CustomerConsent(
      customerId: customerId,
      status: agreed ? ConsentStatus.agree : ConsentStatus.disagree,
      scope: MockDemoFixtures.consentScope,
      consentedAt: MockDemoFixtures.demoNow,
    );
  }

  @override
  Future<CustomerConsent> fetchCustomerConsent(int customerId) async {
    final bool? agreed = _consents[customerId];
    if (agreed == null) {
      throw const AppException('동의 기록이 없습니다.', code: 'CONSENT_NOT_FOUND');
    }
    return CustomerConsent(
      customerId: customerId,
      status: agreed ? ConsentStatus.agree : ConsentStatus.disagree,
      scope: MockDemoFixtures.consentScope,
      consentedAt: MockDemoFixtures.demoNow,
    );
  }

  @override
  Future<CartItem> saveCartItem(CartSaveRequest request) async {
    final MobileProduct product = MobileProductCatalog.productById(
      request.productId,
    );
    final MobileSkuOption? sku = product.skuFor(
      color: request.color,
      size: request.size,
    );
    if (sku == null) {
      throw const AppException(
        '선택한 옵션의 SKU를 찾을 수 없습니다.',
        code: 'SKU_NOT_FOUND',
      );
    }

    final CartItem cartItem = CartItem.fromJson(<String, Object?>{
      'cartItemId': _nextCartItemId,
      'productId': product.id,
      'productName': product.name,
      'imageUrl': 'https://example.com/mcm-product-${product.id}.png',
      'category': product.category,
      'skuId': sku.skuId,
      'color': request.color,
      'size': request.size,
      'currentStoreInStock': false,
      'otherStoreInStock': false,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': MockDemoFixtures.demoNow.toIso8601String(),
    });
    _nextCartItemId += 1;

    final List<CartItem> savedItems = _savedCartItems.putIfAbsent(
      request.customerId,
      () => <CartItem>[],
    );
    savedItems.removeWhere((CartItem item) => item.skuId == cartItem.skuId);
    savedItems.insert(0, cartItem);

    return cartItem;
  }

  @override
  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  }) async {
    if (_consents[customerId] != true) {
      throw const ApiException(
        '고객 동의가 필요합니다. 장바구니 조회·상담 결과 저장 전에 데이터 이용 동의를 먼저 받아 주세요.',
        statusCode: 403,
        code: 'CONSENT_REQUIRED',
      );
    }

    final List<CartItem> savedItems =
        _savedCartItems[customerId] ?? <CartItem>[];
    final List<CartItem> seededItems = MockDemoFixtures.seededCartItems();
    final Set<int> savedSkuIds = <int>{
      for (final CartItem item in savedItems) item.skuId,
    };

    return <CartItem>[
      ...savedItems,
      for (final CartItem item in seededItems)
        if (!savedSkuIds.contains(item.skuId)) item,
    ];
  }

  @override
  Future<StructureIntentResponse> structureIntent(
    StructureIntentRequest request,
  ) async {
    return MockDemoFixtures.structureIntentFor(request.utterance);
  }

  @override
  Future<FollowUpQuestion> requestFollowUpQuestion(
    FollowUpQuestionRequest request,
  ) async {
    return MockDemoFixtures.defaultFollowUpQuestion;
  }

  @override
  Future<StructureIntentResponse> submitFollowUpAnswer(
    FollowUpAnswerRequest request,
  ) async {
    return MockDemoFixtures.followUpAnswerFor(request.followUpAnswer);
  }

  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    return MockDemoFixtures.decide(request.structuredIntent);
  }

  @override
  Future<ExecuteConsultationResponse> executeConsultation(
    ExecuteConsultationRequest request,
  ) async {
    if (_consents[request.customerId] != true) {
      throw const ApiException(
        '고객 동의가 필요합니다. 장바구니 조회·상담 결과 저장 전에 데이터 이용 동의를 먼저 받아 주세요.',
        statusCode: 403,
        code: 'CONSENT_REQUIRED',
      );
    }

    return ExecuteConsultationResponse(
      // Issue #15: unique per call (not a fixed "5") so multiple executed
      // consultations for the same customer get distinct ConsultationResult
      // ids instead of colliding when recorded into the local store.
      consultationResultId: _nextConsultationResultId++,
      // Issue #14: completionMessage varies by actionType per the real API
      // contract, not one canned string regardless of what was requested.
      completionMessage: switch (request.actionType) {
        DecisionActionType.otherStoreCheckRequest =>
          '요청이 접수되었습니다. CA가 실제 재고를 확인합니다',
        DecisionActionType.restockCheckRequest => '확인 신청이 접수되었습니다',
        DecisionActionType.productCheckRequest => 'CA에게 제품 확인을 요청했습니다',
        DecisionActionType.reconsult => '고객의 조건을 다시 확인합니다',
      },
    );
  }

  @override
  Future<void> recordConsultationResult({
    required int customerId,
    required ConsultationResult result,
  }) async {
    if (_consents[customerId] != true) {
      throw const ApiException(
        '고객 동의가 필요합니다. 장바구니 조회·상담 결과 저장 전에 데이터 이용 동의를 먼저 받아 주세요.',
        statusCode: 403,
        code: 'CONSENT_REQUIRED',
      );
    }

    final Map<int, ConsultationResult> forCustomer =
        _consultationResultsByCustomer.putIfAbsent(
          customerId,
          () => <int, ConsultationResult>{},
        );
    // Keyed by result.id: retrying the same save (same id) overwrites in
    // place instead of appending a duplicate entry.
    forCustomer[result.id] = result;
  }

  @override
  Future<List<ConsultationResult>> fetchConsultationResults(
    int customerId,
  ) async {
    if (_consents[customerId] != true) {
      throw const ApiException(
        '고객 동의가 필요합니다. 장바구니 조회·상담 결과 저장 전에 데이터 이용 동의를 먼저 받아 주세요.',
        statusCode: 403,
        code: 'CONSENT_REQUIRED',
      );
    }
    final List<ConsultationResult> results =
        _consultationResultsByCustomer[customerId]?.values.toList() ??
        <ConsultationResult>[];
    // AC: 최신 상담 결과가 먼저 표시된다.
    results.sort(
      (ConsultationResult a, ConsultationResult b) =>
          b.consultedAt.compareTo(a.consultedAt),
    );
    return results;
  }

  @override
  Future<ConsultationResult> updateExecutionStatus({
    required int consultationResultId,
    required ExecutionStatusUpdateRequest request,
  }) async {
    final String? trimmedNote = request.note?.trim();
    if (request.status != ExecutionStatus.requested &&
        (trimmedNote == null || trimmedNote.isEmpty)) {
      throw const AppException(
        '실행 불가 또는 후속 확인 필요 상태에는 사유가 필요합니다.',
        code: 'EXECUTION_NOTE_REQUIRED',
      );
    }

    for (final Map<int, ConsultationResult> results
        in _consultationResultsByCustomer.values) {
      final ConsultationResult? existing = results[consultationResultId];
      if (existing == null) {
        continue;
      }
      final ConsultationResult updated = existing.copyWith(
        executionStatus: request.status,
        executionNote: trimmedNote == null || trimmedNote.isEmpty
            ? null
            : trimmedNote,
        clearExecutionNote: trimmedNote == null || trimmedNote.isEmpty,
        executionUpdatedAt: DateTime.now(),
      );
      results[consultationResultId] = updated;
      return updated;
    }

    throw const AppException(
      '상담 결과를 찾을 수 없습니다.',
      code: 'CONSULTATION_RESULT_NOT_FOUND',
    );
  }
}
