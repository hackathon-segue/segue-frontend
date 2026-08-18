import '../models/models.dart';

enum MockDemoScenarioId {
  a('A'),
  b('B'),
  c('C'),
  d('D');

  const MockDemoScenarioId(this.label);

  final String label;
}

class MockDemoScenario {
  const MockDemoScenario({
    required this.id,
    required this.title,
    required this.utterance,
    this.followUpAnswer,
    required this.initialIntent,
    required this.finalIntent,
    required this.decisionResult,
  });

  final MockDemoScenarioId id;
  final String title;
  final String utterance;
  final String? followUpAnswer;
  final StructuredIntent initialIntent;
  final StructuredIntent finalIntent;
  final DecisionResult decisionResult;

  bool get needsFollowUp => initialIntent.needsFollowUp;
}

abstract final class MockDemoFixtures {
  static const int consentedCustomerId = 1;
  static const int unconsentedCustomerId = 2;
  static const int storeId = 1;
  static const int originalSkuId = 1;
  static const int originalProductId = 1;
  static const String consentedCustomerPhone = '010-1234-5678';
  static const String unconsentedCustomerPhone = '010-9876-5432';
  static const String originalProductName = 'MCM 백팩 미디움';
  static const String consentScope = '장바구니 조회, 구매 의도·상담 결과 저장, 고객 모바일 재확인';

  static final DateTime demoNow = DateTime(2026, 8, 16, 17, 30);

  static const Customer consentedCustomer = Customer(
    id: consentedCustomerId,
    name: '김세계',
    phoneNumber: consentedCustomerPhone,
    hasConsented: true,
  );

  static const Customer unconsentedCustomer = Customer(
    id: unconsentedCustomerId,
    name: '이수현',
    phoneNumber: unconsentedCustomerPhone,
    hasConsented: false,
  );

  static const StructuredIntent scenarioAIntent = StructuredIntent(
    purpose: '',
    essentialConditions: <String, String>{
      'logoPosition': '정면중앙',
      'silhouette': '각진',
    },
    preferredConditions: <String, String>{},
    negotiableConditions: <String, String>{},
    purchaseUrgency: PurchaseUrgency.flexible,
    physicalCheckAttributes: <String>[],
    canWait: true,
    canVisitOtherStore: true,
    needsFollowUp: false,
    followUpReason: '',
  );

  static const StructuredIntent scenarioBIntent = StructuredIntent(
    purpose: '',
    essentialConditions: <String, String>{},
    preferredConditions: <String, String>{},
    negotiableConditions: <String, String>{},
    purchaseUrgency: PurchaseUrgency.flexible,
    physicalCheckAttributes: <String>['material', 'glossLevel'],
    canWait: true,
    canVisitOtherStore: true,
    needsFollowUp: false,
    followUpReason: '',
  );

  static const StructuredIntent scenarioCIntent = StructuredIntent(
    purpose: '출장 전 당일 사용',
    essentialConditions: <String, String>{'laptopCompatible': 'true'},
    preferredConditions: <String, String>{},
    negotiableConditions: <String, String>{},
    purchaseUrgency: PurchaseUrgency.today,
    physicalCheckAttributes: <String>[],
    canWait: false,
    canVisitOtherStore: false,
    needsFollowUp: false,
    followUpReason: '',
  );

  static const StructuredIntent scenarioDInitialIntent = StructuredIntent(
    purpose: '',
    essentialConditions: <String, String>{},
    preferredConditions: <String, String>{},
    negotiableConditions: <String, String>{},
    purchaseUrgency: PurchaseUrgency.flexible,
    physicalCheckAttributes: <String>[],
    canWait: null,
    canVisitOtherStore: null,
    needsFollowUp: true,
    followUpReason: '목적, 시급성, 이동·대기 가능 여부 확인 필요',
  );

  static const StructuredIntent scenarioDFinalIntent = StructuredIntent(
    purpose: '',
    essentialConditions: <String, String>{},
    preferredConditions: <String, String>{},
    negotiableConditions: <String, String>{},
    purchaseUrgency: PurchaseUrgency.flexible,
    physicalCheckAttributes: <String>[],
    canWait: null,
    canVisitOtherStore: null,
    needsFollowUp: false,
    followUpReason: '',
  );

  static const FollowUpQuestion defaultFollowUpQuestion = FollowUpQuestion(
    question: '혹시 오늘 바로 구매를 원하시나요, 아니면 여유를 두고 보셔도 괜찮으실까요?',
  );

  static const DecisionResult scenarioAResult = DecisionResult(
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

  static const DecisionResult scenarioBResult = DecisionResult(
    resultType: DecisionResultType.comparisonExperience,
    coreConditions: '가죽 소재와 중간 광택감을 실물로 확인하고 싶어 하셨습니다.',
    nextAction: '현재 매장에 있는 같은 소재·광택 기준의 제품을 함께 체험해 보세요.',
    reason: '원제품 고정보다 소재와 광택 확인이 중요해, 청담 본점에서 바로 비교 가능한 제품을 제안합니다.',
    difference: '로고 위치와 실루엣은 다르지만 가죽 소재와 중간 광택 조건을 실물로 비교할 수 있습니다.',
    recommendedProduct: ProductSkuSummary(
      skuId: 2,
      productId: 2,
      productName: 'MCM 크로스바디 백 스몰',
      imageUrl: 'https://example.com/sku2.png',
      color: '다크브라운',
      size: '스몰',
    ),
    pathDescription: '현재 매장 비교 체험 제품 확인',
    actionType: DecisionActionType.productCheckRequest,
    actionButtonLabel: '이 제품 확인하기',
  );

  static const DecisionResult scenarioCResult = DecisionResult(
    resultType: DecisionResultType.todayPurchase,
    coreConditions: '출장 전에 오늘 바로 사용해야 하고 노트북 수납이 필수 조건이었습니다.',
    nextAction: '현재 매장에 재고가 있는 노트북 수납 가능 제품을 확인해 드립니다.',
    reason: '구매 시급성과 노트북 수납 조건을 우선 적용해, 오늘 바로 확인 가능한 제품을 제안합니다.',
    difference: '원제품과 형태는 다르지만 오늘 구매 가능성과 노트북 수납 조건을 충족합니다.',
    recommendedProduct: ProductSkuSummary(
      skuId: 3,
      productId: 3,
      productName: 'MCM 토트백 라지',
      imageUrl: 'https://example.com/sku3.png',
      color: '블랙',
      size: '라지',
    ),
    pathDescription: '현재 매장 재고 확인',
    actionType: DecisionActionType.productCheckRequest,
    actionButtonLabel: '이 제품 확인하기',
  );

  static const DecisionResult scenarioDResult = DecisionResult(
    resultType: DecisionResultType.additionalConsultation,
    coreConditions: '유사 제품을 원하지만 핵심 조건과 이동·대기 가능 여부가 아직 명확하지 않습니다.',
    nextAction: '고객과 함께 핵심 조건을 다시 확인한 뒤 상담을 재개합니다.',
    reason: '필수 조건, 실물 확인 요소, 구매 시급성이 충분히 좁혀지지 않아 하나의 다음 행동으로 확정할 수 없습니다.',
    difference: '',
    recommendedProduct: null,
    pathDescription: '',
    actionType: DecisionActionType.reconsult,
    actionButtonLabel: '조건 다시 확인하기',
  );

  static const List<MockDemoScenario> scenarios = <MockDemoScenario>[
    MockDemoScenario(
      id: MockDemoScenarioId.a,
      title: '정확한 제품 확인',
      utterance: '로고 위치와 각진 형태가 좋아요. 오늘 살 필요는 없어요',
      initialIntent: scenarioAIntent,
      finalIntent: scenarioAIntent,
      decisionResult: scenarioAResult,
    ),
    MockDemoScenario(
      id: MockDemoScenarioId.b,
      title: '비교 체험 제품',
      utterance: '원제품이 아니어도 괜찮고 가죽의 광택을 직접 보고 싶어요',
      initialIntent: scenarioBIntent,
      finalIntent: scenarioBIntent,
      decisionResult: scenarioBResult,
    ),
    MockDemoScenario(
      id: MockDemoScenarioId.c,
      title: '오늘 구매 가능한 제품',
      utterance: '출장 전에 오늘 꼭 필요하고 노트북이 들어가야 해요',
      initialIntent: scenarioCIntent,
      finalIntent: scenarioCIntent,
      decisionResult: scenarioCResult,
    ),
    MockDemoScenario(
      id: MockDemoScenarioId.d,
      title: '추가 상담',
      utterance: '그냥 비슷한 걸 보여주세요',
      followUpAnswer: '잘 모르겠어요',
      initialIntent: scenarioDInitialIntent,
      finalIntent: scenarioDFinalIntent,
      decisionResult: scenarioDResult,
    ),
  ];

  static List<CartItem> seededCartItems() {
    return <CartItem>[
      CartItem.fromJson(<String, Object?>{
        'cartItemId': 1,
        'productId': originalProductId,
        'productName': originalProductName,
        'imageUrl': 'https://example.com/mcm-backpack.png',
        'category': '백팩',
        'skuId': originalSkuId,
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
        'savedAt': DateTime(2026, 8, 16, 15, 40).toIso8601String(),
      }),
    ];
  }

  static CartItem originalCartItem() {
    return seededCartItems().first;
  }

  static ConsultationResult seededConsultationResult({
    ExecutionStatus executionStatus = ExecutionStatus.requested,
    String? executionNote,
  }) {
    return ConsultationResult(
      id: 5,
      skuId: originalSkuId,
      productName: originalProductName,
      imageUrl: 'https://example.com/mcm-backpack.png',
      resultType: DecisionResultType.exactProduct,
      recommendedPath: scenarioAResult.pathDescription,
      coreConditions: scenarioAResult.coreConditions,
      consultedAt: DateTime(2026, 8, 16, 15, 20),
      executionStatus: executionStatus,
      executionNote: executionNote,
      executionUpdatedAt: demoNow,
    );
  }

  static StructureIntentResponse structureIntentFor(String utterance) {
    final MockDemoScenario? scenario = scenarioForUtterance(utterance);
    if (scenario != null) {
      return StructureIntentResponse(
        structuredIntent: scenario.initialIntent,
        needsFollowUp: scenario.initialIntent.needsFollowUp,
      );
    }

    if (_containsAll(utterance, <String>['다이아몬드', '직사각'])) {
      return const StructureIntentResponse(
        structuredIntent: StructuredIntent(
          purpose: '',
          essentialConditions: <String, String>{'silhouette': '사각'},
          preferredConditions: <String, String>{},
          negotiableConditions: <String, String>{},
          purchaseUrgency: PurchaseUrgency.flexible,
          physicalCheckAttributes: <String>[],
          canWait: true,
          canVisitOtherStore: true,
          needsFollowUp: false,
          followUpReason: '',
        ),
        needsFollowUp: false,
      );
    }

    if (_containsAny(utterance, <String>['색이나 소재', '그대로인'])) {
      return const StructureIntentResponse(
        structuredIntent: StructuredIntent(
          purpose: '',
          essentialConditions: <String, String>{'colorFamily': '브라운'},
          preferredConditions: <String, String>{},
          negotiableConditions: <String, String>{},
          purchaseUrgency: PurchaseUrgency.flexible,
          physicalCheckAttributes: <String>[],
          canWait: true,
          canVisitOtherStore: true,
          needsFollowUp: false,
          followUpReason: '',
        ),
        needsFollowUp: false,
      );
    }

    return const StructureIntentResponse(
      structuredIntent: scenarioAIntent,
      needsFollowUp: false,
    );
  }

  static StructureIntentResponse followUpAnswerFor(String answer) {
    final bool stillUnclear = _containsAny(answer, <String>['모르겠', '글쎄']);
    return StructureIntentResponse(
      structuredIntent: stillUnclear
          ? scenarioDFinalIntent
          : scenarioAIntent.copyWith(needsFollowUp: false),
      needsFollowUp: false,
    );
  }

  static DecisionResult decide(StructuredIntent intent) {
    final Map<String, String> essential = intent.essentialConditions;
    final List<String> physicalChecks = intent.physicalCheckAttributes;

    if (essential.isEmpty &&
        physicalChecks.isEmpty &&
        (intent.canWait == null || intent.canVisitOtherStore == null)) {
      return scenarioDResult;
    }

    if (essential['laptopCompatible'] == 'true' &&
        intent.purchaseUrgency == PurchaseUrgency.today) {
      return scenarioCResult;
    }

    if (essential['logoPosition'] == '정면중앙' &&
        essential['silhouette'] == '각진') {
      return scenarioAResult;
    }

    if (essential.isEmpty &&
        physicalChecks.contains('material') &&
        physicalChecks.contains('glossLevel')) {
      return scenarioBResult;
    }

    if (essential['silhouette'] == '사각' || essential['material'] == '가죽') {
      return scenarioBResult;
    }

    if (essential['colorFamily'] == '브라운') {
      return scenarioAResult;
    }

    return scenarioAResult;
  }

  static MockDemoScenario? scenarioForUtterance(String utterance) {
    if (_containsAny(utterance, <String>['비슷'])) {
      return scenarios.byId(MockDemoScenarioId.d);
    }
    if (_containsAny(utterance, <String>['노트북', '출장'])) {
      return scenarios.byId(MockDemoScenarioId.c);
    }
    if (_containsAny(utterance, <String>['광택', '직접 보고'])) {
      return scenarios.byId(MockDemoScenarioId.b);
    }
    if (_containsAll(utterance, <String>['로고', '각진'])) {
      return scenarios.byId(MockDemoScenarioId.a);
    }
    return null;
  }

  static bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  static bool _containsAll(String value, List<String> keywords) {
    return keywords.every(value.contains);
  }
}

extension on List<MockDemoScenario> {
  MockDemoScenario byId(MockDemoScenarioId id) {
    return firstWhere((MockDemoScenario scenario) => scenario.id == id);
  }
}
