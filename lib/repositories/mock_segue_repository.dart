import '../exceptions/app_exception.dart';
import '../models/models.dart';
import 'segue_repository.dart';

class MockSegueRepository implements SegueRepository {
  MockSegueRepository();

  final Map<int, bool> _consents = <int, bool>{1: true, 2: false};

  // Issue #15: mock/local ConsultationResult store — customerId -> (result
  // id -> result). Keyed by id (not a plain list) so recordConsultationResult
  // is idempotent: retrying a save after a failure overwrites the same
  // entry instead of creating a duplicate.
  final Map<int, Map<int, ConsultationResult>> _consultationResultsByCustomer =
      <int, Map<int, ConsultationResult>>{};
  int _nextConsultationResultId = 100;

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
      // Second simultaneously out-of-stock item (S5 per SCHEMA.md's demo
      // scenario table: 청담 본점 없음, 입고 예정만) so Issue #8's AC
      // "미보유 제품마다 독립적인 Last Intent 시작 버튼이 있다" is actually
      // exercised by two non-stock rows at once, not just one.
      CartItem.fromJson(<String, Object?>{
        'cartItemId': 6,
        'productId': 5,
        'productName': 'MCM 벨트백',
        'imageUrl': 'https://example.com/mcm-beltbag.png',
        'category': '벨트백',
        'skuId': 5,
        'color': '브라운',
        'size': '스몰',
        'currentStoreInStock': false,
        'otherStoreInStock': false,
        'restockPlanned': true,
        'actionButtonLabel': 'Last Intent 시작',
        'savedAt': DateTime(2026, 8, 16, 15, 40, 0).toIso8601String(),
      }),
    ];
  }

  @override
  Future<StructureIntentResponse> structureIntent(
    StructureIntentRequest request,
  ) async {
    final bool needsFollowUp = request.utterance.contains('비슷');
    final Map<String, String> essentialConditions;
    if (needsFollowUp) {
      essentialConditions = <String, String>{};
    } else if (request.utterance.contains('다이아몬드') && request.utterance.contains('직사각')) {
      // SCHEMA.md 페르소나 1 (디자인 유지형) → decide()가 COMPARISON_EXPERIENCE/SKU2로 매핑.
      essentialConditions = <String, String>{'silhouette': '사각'};
    } else if (request.utterance.contains('가죽') || request.utterance.contains('비세토스')) {
      // 페르소나 2 (시그니처·소재 유지형) → COMPARISON_EXPERIENCE/SKU3.
      essentialConditions = <String, String>{'material': '가죽'};
    } else if (request.utterance.contains('노트북')) {
      // 페르소나 3 (즉시 사용·기능형) → TODAY_PURCHASE/SKU4.
      essentialConditions = <String, String>{'laptopCompatible': 'true'};
    } else if (request.utterance.contains('색이나 소재') || request.utterance.contains('그대로인')) {
      // 페르소나 4 (오리지널 고수형) → EXACT_PRODUCT(원제품 타매장 확보).
      essentialConditions = <String, String>{'colorFamily': '브라운'};
    } else {
      essentialConditions = <String, String>{'logoPosition': '정면중앙', 'silhouette': '각진'};
    }

    final StructuredIntent intent = StructuredIntent(
      purpose: '',
      essentialConditions: essentialConditions,
      preferredConditions: const <String, String>{},
      negotiableConditions: const <String, String>{},
      purchaseUrgency: essentialConditions.containsKey('laptopCompatible')
          ? PurchaseUrgency.today
          : PurchaseUrgency.flexible,
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
    // SCHEMA.md 페르소나 5: 보충 답변 이후에도 canWait/canVisitOtherStore가
    // 여전히 null이면(=조건 불명확 지속) 추가 상담(ADDITIONAL_CONSULTATION)으로
    // 이어진다 — "모르겠다"류 답변을 그 신호로 사용한다.
    final bool stillUnclear =
        request.followUpAnswer.contains('모르겠') || request.followUpAnswer.contains('글쎄');
    final StructuredIntent intent = StructuredIntent.empty().copyWith(
      purchaseUrgency: PurchaseUrgency.flexible,
      canWait: stillUnclear ? null : true,
      canVisitOtherStore: stillUnclear ? null : true,
      needsFollowUp: false,
    );
    return StructureIntentResponse(
      structuredIntent: intent,
      needsFollowUp: false,
    );
  }

  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    final StructuredIntent intent = request.structuredIntent;
    final Map<String, String> ec = intent.essentialConditions;

    if (ec.isEmpty && (intent.canWait == null || intent.canVisitOtherStore == null)) {
      // 페르소나 5: 조건 불명확형 → ADDITIONAL_CONSULTATION.
      return const DecisionResult(
        resultType: DecisionResultType.additionalConsultation,
        coreConditions: '복수의 조건이 명확하지 않아 우선순위를 확인하지 못했습니다.',
        nextAction: '고객과 함께 핵심 조건을 다시 확인한 뒤 상담을 재개합니다.',
        reason: '필수 조건과 선호 조건이 상충되어 하나의 제품으로 좁혀지지 않습니다.',
        difference: '',
        recommendedProduct: null,
        pathDescription: '',
        actionType: DecisionActionType.reconsult,
        actionButtonLabel: '조건 다시 확인하기',
      );
    }

    if (ec['silhouette'] == '사각') {
      // 페르소나 1 → 결과2 비교 체험 (SKU 2, "M Diamond 엠보스드 레더 · 블랙").
      return const DecisionResult(
        resultType: DecisionResultType.comparisonExperience,
        coreConditions: '직사각형 실루엣과 다이아몬드 핸들 디자인을 중요하게 보셨습니다.',
        nextAction: '매장에 있는 동일 실루엣 제품을 함께 체험해 보세요.',
        reason: '색상·소재보다 형태와 핸들 디자인을 우선하셔서, 현재 매장에서 바로 확인 가능한 이 제품을 제안합니다.',
        difference: '컬러만 다르고 실루엣과 핸들 디자인 조건은 동일하게 충족합니다.',
        recommendedProduct: ProductSkuSummary(
          skuId: 2,
          productId: 2,
          productName: 'M Diamond 엠보스드 레더',
          imageUrl: 'https://example.com/sku2.png',
          color: '블랙',
          size: '미디움',
        ),
        pathDescription: '매장 내 비교 체험',
        actionType: DecisionActionType.productCheckRequest,
        actionButtonLabel: '이 제품 확인하기',
      );
    }

    if (ec['material'] == '가죽') {
      // 페르소나 2 → 결과2 비교 체험 (SKU 3, "M New Liz 비세토스 쇼퍼 · 꼬냑").
      return const DecisionResult(
        resultType: DecisionResultType.comparisonExperience,
        coreConditions: '꼬냑 비세토스 소재와 패턴의 실제 인상을 중요하게 보셨습니다.',
        nextAction: '매장에 있는 동일 소재·컬러 제품을 함께 체험해 보세요.',
        reason: '형태보다 시그니처 소재와 컬러를 더 중요하게 보셨기 때문에, 현재 매장에서 바로 비교 체험할 수 있는 이 제품을 제안합니다.',
        difference: '형태는 다르지만 소재와 컬러 조건은 동일하게 충족합니다.',
        recommendedProduct: ProductSkuSummary(
          skuId: 3,
          productId: 3,
          productName: 'M New Liz 비세토스 쇼퍼',
          imageUrl: 'https://example.com/sku3.png',
          color: '꼬냑',
          size: '미디움',
        ),
        pathDescription: '매장 내 비교 체험',
        actionType: DecisionActionType.productCheckRequest,
        actionButtonLabel: '이 제품 확인하기',
      );
    }

    if (ec['laptopCompatible'] == 'true') {
      // 페르소나 3 → 결과3 오늘 구매 가능 (SKU 4, "L Aren 비세토스 N/S 토트 · 블랙").
      return const DecisionResult(
        resultType: DecisionResultType.todayPurchase,
        coreConditions: '오늘 바로 사용 가능해야 하고 16인치 노트북 수납이 필수 조건이었습니다.',
        nextAction: '현재 매장에 재고가 있어 오늘 바로 구매하실 수 있습니다.',
        reason: '구매 시급성과 노트북 수납을 필수 조건으로 우선 적용해, 두 조건을 모두 충족하는 제품을 제안합니다.',
        difference: '실루엣과 컬러는 다르지만 16인치 노트북 수납 조건은 충족합니다.',
        recommendedProduct: ProductSkuSummary(
          skuId: 4,
          productId: 4,
          productName: 'L Aren 비세토스 N/S 토트',
          imageUrl: 'https://example.com/sku4.png',
          color: '블랙',
          size: '라지',
        ),
        pathDescription: '현재 매장 재고 확인',
        actionType: DecisionActionType.productCheckRequest,
        actionButtonLabel: '이 제품 확인하기',
      );
    }

    if (ec['colorFamily'] == '브라운') {
      // 페르소나 4 → 결과1 정확한 제품 확인 (원제품, 타 매장 확보).
      return const DecisionResult(
        resultType: DecisionResultType.exactProduct,
        coreConditions: '꼬냑 컬러와 다이아몬드 핸들이 그대로인 제품을 원하셨습니다.',
        nextAction: '강남 신세계점 재고를 확인해 안내해 드릴 수 있습니다.',
        reason: '컬러와 핸들 디자인을 모두 고정 조건으로 두셔서, 다른 대안 없이 동일 제품 확보 경로를 우선합니다.',
        difference: '오늘 바로 구매하지 않으셔도 괜찮다고 하셔서, 동일 제품을 타 매장에서 확보하는 경로를 우선 제안드립니다.',
        recommendedProduct: null,
        pathDescription: '강남 신세계점 재고 확인',
        actionType: DecisionActionType.otherStoreCheckRequest,
        actionButtonLabel: '타 매장 확인 요청',
      );
    }

    // 기본값 (기존 동작 유지) — 위 페르소나 키워드에 매칭되지 않는 모든 발화.
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

    return ExecuteConsultationResponse(
      // Issue #15: unique per call (not a fixed "5") so multiple executed
      // consultations for the same customer get distinct ConsultationResult
      // ids instead of colliding when recorded into the local store.
      consultationResultId: _nextConsultationResultId++,
      // Issue #14: completionMessage varies by actionType per the real API
      // contract, not one canned string regardless of what was requested.
      completionMessage: switch (request.actionType) {
        DecisionActionType.otherStoreCheckRequest => '요청이 접수되었습니다. CA가 실제 재고를 확인합니다',
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
    final Map<int, ConsultationResult> forCustomer = _consultationResultsByCustomer
        .putIfAbsent(customerId, () => <int, ConsultationResult>{});
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
        _consultationResultsByCustomer[customerId]?.values.toList() ?? <ConsultationResult>[];
    // AC: 최신 상담 결과가 먼저 표시된다.
    results.sort((ConsultationResult a, ConsultationResult b) => b.consultedAt.compareTo(a.consultedAt));
    return results;
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
