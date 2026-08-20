import 'json_utils.dart';
import 'product_models.dart';

enum PurchaseUrgency {
  today('TODAY'),
  thisWeek('THIS_WEEK'),
  flexible('FLEXIBLE');

  const PurchaseUrgency(this.wireName);

  final String wireName;

  static PurchaseUrgency fromWire(String value) {
    return PurchaseUrgency.values.firstWhere(
      (PurchaseUrgency urgency) => urgency.wireName == value,
      orElse: () => PurchaseUrgency.flexible,
    );
  }
}

enum DecisionResultType {
  exactProduct('EXACT_PRODUCT'),
  comparisonExperience('COMPARISON_EXPERIENCE'),
  todayPurchase('TODAY_PURCHASE'),
  additionalConsultation('ADDITIONAL_CONSULTATION');

  const DecisionResultType(this.wireName);

  final String wireName;

  static DecisionResultType fromWire(String value) {
    return DecisionResultType.values.firstWhere(
      (DecisionResultType type) => type.wireName == value,
      orElse: () => DecisionResultType.additionalConsultation,
    );
  }
}

enum DecisionActionType {
  otherStoreCheckRequest('OTHER_STORE_CHECK_REQUEST'),
  restockCheckRequest('RESTOCK_CHECK_REQUEST'),
  productCheckRequest('PRODUCT_CHECK_REQUEST'),
  reconsult('RECONSULT');

  const DecisionActionType(this.wireName);

  final String wireName;

  static DecisionActionType fromWire(String value) {
    return DecisionActionType.values.firstWhere(
      (DecisionActionType type) => type.wireName == value,
      orElse: () => DecisionActionType.reconsult,
    );
  }
}

enum ExecutionStatus {
  requested('REQUESTED'),
  unable('UNABLE'),
  followUpNeeded('FOLLOW_UP_NEEDED');

  const ExecutionStatus(this.wireName);

  final String wireName;

  static ExecutionStatus fromWire(String value) {
    return ExecutionStatus.values.firstWhere(
      (ExecutionStatus status) => status.wireName == value,
      orElse: () => ExecutionStatus.requested,
    );
  }
}

class StructuredIntent {
  const StructuredIntent({
    required this.purpose,
    required this.essentialConditions,
    required this.preferredConditions,
    required this.negotiableConditions,
    required this.purchaseUrgency,
    required this.physicalCheckAttributes,
    required this.canWait,
    required this.canVisitOtherStore,
    required this.needsFollowUp,
    required this.followUpReason,
  });

  factory StructuredIntent.empty() {
    return const StructuredIntent(
      purpose: '',
      essentialConditions: <String, String>{},
      preferredConditions: <String, String>{},
      negotiableConditions: <String, String>{},
      purchaseUrgency: PurchaseUrgency.flexible,
      physicalCheckAttributes: <String>[],
      canWait: null,
      canVisitOtherStore: null,
      needsFollowUp: true,
      followUpReason: '',
    );
  }

  factory StructuredIntent.fromJson(JsonMap json) {
    return StructuredIntent(
      purpose: stringValue(json, 'purpose'),
      essentialConditions: stringMapValue(json, 'essentialConditions'),
      preferredConditions: stringMapValue(json, 'preferredConditions'),
      negotiableConditions: stringMapValue(json, 'negotiableConditions'),
      purchaseUrgency: PurchaseUrgency.fromWire(
        stringValue(json, 'purchaseUrgency'),
      ),
      physicalCheckAttributes: stringListValue(json, 'physicalCheckAttributes'),
      canWait: json['canWait'] is bool ? json['canWait']! as bool : null,
      canVisitOtherStore: json['canVisitOtherStore'] is bool
          ? json['canVisitOtherStore']! as bool
          : null,
      needsFollowUp: boolValue(json, 'needsFollowUp'),
      followUpReason: stringValue(json, 'followUpReason'),
    );
  }

  final String purpose;
  final Map<String, String> essentialConditions;
  final Map<String, String> preferredConditions;
  final Map<String, String> negotiableConditions;
  final PurchaseUrgency purchaseUrgency;
  final List<String> physicalCheckAttributes;
  final bool? canWait;
  final bool? canVisitOtherStore;
  final bool needsFollowUp;
  final String followUpReason;

  StructuredIntent copyWith({
    String? purpose,
    Map<String, String>? essentialConditions,
    Map<String, String>? preferredConditions,
    Map<String, String>? negotiableConditions,
    PurchaseUrgency? purchaseUrgency,
    List<String>? physicalCheckAttributes,
    bool? canWait,
    bool? canVisitOtherStore,
    bool? needsFollowUp,
    String? followUpReason,
  }) {
    return StructuredIntent(
      purpose: purpose ?? this.purpose,
      essentialConditions: essentialConditions ?? this.essentialConditions,
      preferredConditions: preferredConditions ?? this.preferredConditions,
      negotiableConditions: negotiableConditions ?? this.negotiableConditions,
      purchaseUrgency: purchaseUrgency ?? this.purchaseUrgency,
      physicalCheckAttributes:
          physicalCheckAttributes ?? this.physicalCheckAttributes,
      canWait: canWait ?? this.canWait,
      canVisitOtherStore: canVisitOtherStore ?? this.canVisitOtherStore,
      needsFollowUp: needsFollowUp ?? this.needsFollowUp,
      followUpReason: followUpReason ?? this.followUpReason,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'purpose': purpose,
      'essentialConditions': essentialConditions,
      'preferredConditions': preferredConditions,
      'negotiableConditions': negotiableConditions,
      'purchaseUrgency': purchaseUrgency.wireName,
      'physicalCheckAttributes': physicalCheckAttributes,
      'canWait': canWait,
      'canVisitOtherStore': canVisitOtherStore,
      'needsFollowUp': needsFollowUp,
      'followUpReason': followUpReason,
    };
  }
}

class StructureIntentRequest {
  const StructureIntentRequest({
    required this.storeId,
    required this.skuId,
    required this.utterance,
  });

  final int storeId;
  final int skuId;
  final String utterance;

  JsonMap toJson() {
    return <String, Object?>{
      'storeId': storeId,
      'skuId': skuId,
      'utterance': utterance,
    };
  }
}

class StructureIntentResponse {
  const StructureIntentResponse({
    required this.structuredIntent,
    required this.needsFollowUp,
  });

  factory StructureIntentResponse.fromJson(JsonMap json) {
    final StructuredIntent intent = StructuredIntent.fromJson(
      asJsonMap(json['structuredIntent']),
    );
    return StructureIntentResponse(
      structuredIntent: intent,
      needsFollowUp: boolValue(
        json,
        'needsFollowUp',
        defaultValue: intent.needsFollowUp,
      ),
    );
  }

  final StructuredIntent structuredIntent;
  final bool needsFollowUp;
}

class FollowUpQuestion {
  const FollowUpQuestion({required this.question});

  factory FollowUpQuestion.fromJson(JsonMap json) {
    return FollowUpQuestion(question: stringValue(json, 'question'));
  }

  final String question;
}

class FollowUpQuestionRequest {
  const FollowUpQuestionRequest({
    required this.utterance,
    required this.currentIntent,
  });

  final String utterance;
  final StructuredIntent currentIntent;

  JsonMap toJson() {
    return <String, Object?>{
      'utterance': utterance,
      'currentIntent': currentIntent.toJson(),
    };
  }
}

class FollowUpAnswerRequest {
  const FollowUpAnswerRequest({
    required this.utterance,
    required this.followUpQuestion,
    required this.followUpAnswer,
  });

  final String utterance;
  final String followUpQuestion;
  final String followUpAnswer;

  JsonMap toJson() {
    return <String, Object?>{
      'utterance': utterance,
      'followUpQuestion': followUpQuestion,
      'followUpAnswer': followUpAnswer,
    };
  }
}

class DecisionRequest {
  const DecisionRequest({
    required this.storeId,
    required this.skuId,
    required this.structuredIntent,
  });

  final int storeId;
  final int skuId;
  final StructuredIntent structuredIntent;

  JsonMap toJson() {
    return <String, Object?>{
      'storeId': storeId,
      'skuId': skuId,
      'structuredIntent': structuredIntent.toJson(),
    };
  }
}

class DecisionResult {
  const DecisionResult({
    required this.resultType,
    required this.coreConditions,
    required this.nextAction,
    required this.reason,
    required this.difference,
    required this.recommendedProduct,
    required this.pathDescription,
    required this.actionType,
    required this.actionButtonLabel,
  });

  factory DecisionResult.fromJson(JsonMap json) {
    final JsonMap recommendedProductJson = asJsonMap(
      json['recommendedProduct'],
    );
    return DecisionResult(
      resultType: DecisionResultType.fromWire(stringValue(json, 'resultType')),
      coreConditions: stringValue(json, 'coreConditions'),
      nextAction: stringValue(json, 'nextAction'),
      reason: stringValue(json, 'reason'),
      difference: stringValue(json, 'difference'),
      recommendedProduct: recommendedProductJson.isEmpty
          ? null
          : ProductSkuSummary.fromJson(recommendedProductJson),
      pathDescription: stringValue(json, 'pathDescription'),
      actionType: DecisionActionType.fromWire(stringValue(json, 'actionType')),
      actionButtonLabel: stringValue(json, 'actionButtonLabel'),
    );
  }

  final DecisionResultType resultType;
  final String coreConditions;
  final String nextAction;
  final String reason;
  final String difference;
  final ProductSkuSummary? recommendedProduct;
  final String pathDescription;
  final DecisionActionType actionType;
  final String actionButtonLabel;

  JsonMap toJson() {
    return <String, Object?>{
      'resultType': resultType.wireName,
      'coreConditions': coreConditions,
      'nextAction': nextAction,
      'reason': reason,
      'difference': difference,
      'recommendedProduct': recommendedProduct?.toJson(),
      'pathDescription': pathDescription,
      'actionType': actionType.wireName,
      'actionButtonLabel': actionButtonLabel,
    };
  }
}

class LastIntentCardContent {
  const LastIntentCardContent({
    required this.coreConditions,
    required this.nextAction,
    required this.reason,
    required this.difference,
    required this.pathDescription,
    required this.actionButtonLabel,
    this.recommendedProduct,
  });

  factory LastIntentCardContent.fromDecisionResult(DecisionResult result) {
    return LastIntentCardContent(
      coreConditions: result.coreConditions,
      nextAction: result.nextAction,
      reason: result.reason,
      difference: result.difference,
      pathDescription: result.pathDescription,
      actionButtonLabel: result.actionButtonLabel,
      recommendedProduct: result.recommendedProduct,
    );
  }

  final String coreConditions;
  final String nextAction;
  final String reason;
  final String difference;
  final String pathDescription;
  final String actionButtonLabel;
  final ProductSkuSummary? recommendedProduct;
}

class ExecuteConsultationRequest {
  const ExecuteConsultationRequest({
    required this.customerId,
    required this.skuId,
    required this.resultType,
    required this.actionType,
    required this.recommendedSkuId,
    required this.pathDescription,
    required this.coreConditionsSummary,
  });

  factory ExecuteConsultationRequest.fromDecisionResult({
    required int customerId,
    required int skuId,
    required DecisionResult decisionResult,
  }) {
    return ExecuteConsultationRequest(
      customerId: customerId,
      skuId: skuId,
      resultType: decisionResult.resultType,
      actionType: decisionResult.actionType,
      recommendedSkuId: decisionResult.recommendedProduct?.skuId,
      pathDescription: decisionResult.pathDescription,
      coreConditionsSummary: decisionResult.coreConditions,
    );
  }

  final int customerId;
  final int skuId;
  final DecisionResultType resultType;
  final DecisionActionType actionType;
  final int? recommendedSkuId;
  final String pathDescription;
  final String coreConditionsSummary;

  JsonMap toJson() {
    return <String, Object?>{
      'customerId': customerId,
      'skuId': skuId,
      'resultType': resultType.wireName,
      'actionType': actionType.wireName,
      'recommendedSkuId': recommendedSkuId,
      'pathDescription': pathDescription,
      'coreConditionsSummary': coreConditionsSummary,
    };
  }
}

class ExecuteConsultationResponse {
  const ExecuteConsultationResponse({
    required this.consultationResultId,
    required this.completionMessage,
  });

  factory ExecuteConsultationResponse.fromJson(JsonMap json) {
    return ExecuteConsultationResponse(
      consultationResultId: intValue(json, 'consultationResultId'),
      completionMessage: stringValue(json, 'completionMessage'),
    );
  }

  final int consultationResultId;
  final String completionMessage;
}

class ConsultationResult {
  const ConsultationResult({
    required this.id,
    required this.skuId,
    required this.productName,
    required this.imageUrl,
    required this.resultType,
    required this.recommendedPath,
    required this.coreConditions,
    required this.consultedAt,
    required this.executionStatus,
    required this.executionNote,
    required this.executionUpdatedAt,
    this.recommendedProduct,
  });

  factory ConsultationResult.fromJson(JsonMap json) {
    final JsonMap recommendedProductJson = asJsonMap(
      json['recommendedProduct'],
    );

    return ConsultationResult(
      id: intValue(json, 'id'),
      skuId: intValue(json, 'skuId'),
      productName: stringValue(json, 'productName'),
      imageUrl: stringValue(json, 'imageUrl'),
      resultType: DecisionResultType.fromWire(stringValue(json, 'resultType')),
      recommendedPath: stringValue(json, 'recommendedPath'),
      coreConditions: stringValue(json, 'coreConditions'),
      consultedAt: dateTimeValue(json, 'consultedAt') ?? DateTime(1970),
      executionStatus: ExecutionStatus.fromWire(
        stringValue(json, 'executionStatus'),
      ),
      executionNote: json['executionNote']?.toString(),
      executionUpdatedAt:
          dateTimeValue(json, 'executionUpdatedAt') ?? DateTime(1970),
      recommendedProduct: recommendedProductJson.isEmpty
          ? null
          : ProductSkuSummary.fromJson(recommendedProductJson),
    );
  }

  final int id;
  final int skuId;
  final String productName;
  final String imageUrl;
  final DecisionResultType resultType;
  final String recommendedPath;
  final String coreConditions;
  final DateTime consultedAt;
  final ExecutionStatus executionStatus;
  final String? executionNote;
  final DateTime executionUpdatedAt;
  final ProductSkuSummary? recommendedProduct;

  ConsultationResult copyWith({
    int? id,
    int? skuId,
    String? productName,
    String? imageUrl,
    DecisionResultType? resultType,
    String? recommendedPath,
    String? coreConditions,
    DateTime? consultedAt,
    ExecutionStatus? executionStatus,
    String? executionNote,
    bool clearExecutionNote = false,
    DateTime? executionUpdatedAt,
    ProductSkuSummary? recommendedProduct,
    bool clearRecommendedProduct = false,
  }) {
    return ConsultationResult(
      id: id ?? this.id,
      skuId: skuId ?? this.skuId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      resultType: resultType ?? this.resultType,
      recommendedPath: recommendedPath ?? this.recommendedPath,
      coreConditions: coreConditions ?? this.coreConditions,
      consultedAt: consultedAt ?? this.consultedAt,
      executionStatus: executionStatus ?? this.executionStatus,
      executionNote: clearExecutionNote
          ? null
          : executionNote ?? this.executionNote,
      executionUpdatedAt: executionUpdatedAt ?? this.executionUpdatedAt,
      recommendedProduct: clearRecommendedProduct
          ? null
          : recommendedProduct ?? this.recommendedProduct,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'skuId': skuId,
      'productName': productName,
      'imageUrl': imageUrl,
      'resultType': resultType.wireName,
      'recommendedPath': recommendedPath,
      'coreConditions': coreConditions,
      'consultedAt': consultedAt.toIso8601String(),
      'executionStatus': executionStatus.wireName,
      'executionNote': executionNote,
      'executionUpdatedAt': executionUpdatedAt.toIso8601String(),
      'recommendedProduct': recommendedProduct?.toJson(),
    };
  }
}

class ExecutionStatusUpdateRequest {
  const ExecutionStatusUpdateRequest({required this.status, this.note});

  final ExecutionStatus status;
  final String? note;

  JsonMap toJson() {
    return <String, Object?>{'status': status.wireName, 'note': note};
  }
}
