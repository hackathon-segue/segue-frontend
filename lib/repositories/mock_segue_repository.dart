import '../exceptions/app_exception.dart';
import '../models/models.dart';
import 'segue_repository.dart';

class MockSegueRepository implements SegueRepository {
  MockSegueRepository();

  final Map<int, bool> _consents = <int, bool>{1: true, 2: false};

  static final DateTime _demoNow = DateTime(2026, 8, 16, 17, 30);

  @override
  Future<Customer> lookupCustomerByPhone(String phoneNumber) async {
    return switch (phoneNumber) {
      '010-1234-5678' => const Customer(
        id: 1,
        name: '김세계',
        phoneNumber: '010-1234-5678',
        hasConsented: true,
      ),
      '010-9876-5432' => const Customer(
        id: 2,
        name: '이수현',
        phoneNumber: '010-9876-5432',
        hasConsented: false,
      ),
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
      scope: '장바구니 조회, 구매 의도·상담 결과 저장, 고객 모바일 재확인',
      consentedAt: _demoNow,
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
      scope: '장바구니 조회, 구매 의도·상담 결과 저장, 고객 모바일 재확인',
      consentedAt: _demoNow,
    );
  }

  @override
  Future<CartItem> saveCartItem(CartSaveRequest request) async {
    return CartItem.fromJson(<String, Object?>{
      'cartItemId': 10,
      'productId': request.productId,
      'productName': 'MCM 백팩 미디움',
      'imageUrl': 'https://example.com/mcm-backpack.png',
      'category': '백팩',
      'skuId': 1,
      'color': request.color,
      'size': request.size,
      'currentStoreInStock': false,
      'otherStoreInStock': false,
      'restockPlanned': false,
      'actionButtonLabel': 'Last Intent 시작',
      'savedAt': _demoNow.toIso8601String(),
    });
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

    return <CartItem>[
      CartItem.fromJson(<String, Object?>{
        'cartItemId': 1,
        'productId': 1,
        'productName': 'MCM 백팩 미디움',
        'imageUrl': 'https://example.com/mcm-backpack.png',
        'category': '백팩',
        'skuId': 1,
        'color': '블랙',
        'size': '미디움',
        'currentStoreInStock': false,
        'otherStoreInStock': true,
        'restockPlanned': false,
        'actionButtonLabel': 'Last Intent 시작',
        'savedAt': DateTime(2026, 8, 16, 16, 54, 29).toIso8601String(),
      }),
      CartItem.fromJson(<String, Object?>{
        'cartItemId': 3,
        'productId': 4,
        'productName': 'MCM 숄더백 미니',
        'imageUrl': 'https://example.com/mcm-shoulder.png',
        'category': '숄더백',
        'skuId': 4,
        'color': '베이지',
        'size': '미니',
        'currentStoreInStock': true,
        'otherStoreInStock': true,
        'restockPlanned': false,
        'actionButtonLabel': '제품 확인하기',
        'savedAt': DateTime(2026, 8, 16, 16, 19, 29).toIso8601String(),
      }),
    ];
  }

  @override
  Future<StructureIntentResponse> structureIntent(
    StructureIntentRequest request,
  ) async {
    final bool needsFollowUp = request.utterance.contains('비슷');
    final StructuredIntent intent = StructuredIntent(
      purpose: '',
      essentialConditions: needsFollowUp
          ? <String, String>{}
          : <String, String>{'logoPosition': '정면중앙', 'silhouette': '각진'},
      preferredConditions: const <String, String>{},
      negotiableConditions: const <String, String>{},
      purchaseUrgency: PurchaseUrgency.flexible,
      physicalCheckAttributes: const <String>[],
      canWait: needsFollowUp ? null : true,
      canVisitOtherStore: needsFollowUp ? null : true,
      needsFollowUp: needsFollowUp,
      followUpReason: needsFollowUp ? '구매 시급성 확인 필요' : '',
    );

    return StructureIntentResponse(
      structuredIntent: intent,
      needsFollowUp: needsFollowUp,
    );
  }

  @override
  Future<FollowUpQuestion> requestFollowUpQuestion(
    FollowUpQuestionRequest request,
  ) async {
    return const FollowUpQuestion(
      question: '혹시 오늘 바로 구매를 원하시나요, 아니면 여유를 두고 보셔도 괜찮으실까요?',
    );
  }

  @override
  Future<StructureIntentResponse> submitFollowUpAnswer(
    FollowUpAnswerRequest request,
  ) async {
    final StructuredIntent intent = StructuredIntent.empty().copyWith(
      purchaseUrgency: PurchaseUrgency.flexible,
      canWait: true,
      canVisitOtherStore: true,
      needsFollowUp: false,
    );
    return StructureIntentResponse(
      structuredIntent: intent,
      needsFollowUp: false,
    );
  }

  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    return const DecisionResult(
      resultType: DecisionResultType.exactProduct,
      coreConditions: '로고가 정면 중앙에 오는 각진 실루엣을 중요하게 보고 계셨습니다.',
      nextAction: '강남 신세계점 재고를 확인해 안내해 드릴 수 있습니다.',
      reason: '고객님이 언급하신 로고 위치와 실루엣은 지금 보고 계신 제품에서만 확인되는 특징입니다.',
      difference: '오늘 바로 구매하지 않으셔도 괜찮다고 하셔서, 동일 제품을 타 매장에서 확보하는 경로를 우선 제안드립니다.',
      recommendedProduct: null,
      pathDescription: '강남 신세계점 재고 확인',
      actionType: DecisionActionType.otherStoreCheckRequest,
      actionButtonLabel: '타 매장 확인 요청',
    );
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

    return const ExecuteConsultationResponse(
      consultationResultId: 5,
      completionMessage: '요청이 접수되었습니다. CA가 실제 재고를 확인합니다',
    );
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
    return <ConsultationResult>[_consultationResult()];
  }

  @override
  Future<ConsultationResult> updateExecutionStatus({
    required int consultationResultId,
    required ExecutionStatusUpdateRequest request,
  }) async {
    if (request.status != ExecutionStatus.requested &&
        (request.note == null || request.note!.trim().isEmpty)) {
      throw const AppException(
        '실행 불가 또는 후속 확인 필요 상태에는 사유가 필요합니다.',
        code: 'EXECUTION_NOTE_REQUIRED',
      );
    }

    return _consultationResult(
      executionStatus: request.status,
      executionNote: request.note,
    );
  }

  ConsultationResult _consultationResult({
    ExecutionStatus executionStatus = ExecutionStatus.requested,
    String? executionNote,
  }) {
    return ConsultationResult(
      id: 5,
      skuId: 1,
      productName: 'MCM 백팩 미디움',
      imageUrl: 'https://example.com/mcm-backpack.png',
      resultType: DecisionResultType.exactProduct,
      recommendedPath: '강남 신세계점 재고 확인',
      coreConditions: '로고가 정면 중앙에 오는 각진 실루엣을 중요하게 보고 계셨습니다.',
      consultedAt: DateTime(2026, 8, 16, 15, 20),
      executionStatus: executionStatus,
      executionNote: executionNote,
      executionUpdatedAt: _demoNow,
    );
  }
}
