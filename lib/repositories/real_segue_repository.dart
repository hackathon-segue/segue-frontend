import '../exceptions/app_exception.dart';
import '../models/models.dart';
import 'mobile_product_catalog.dart';
import 'segue_api_client.dart';
import 'segue_repository.dart';

class RealSegueRepository implements SegueRepository {
  const RealSegueRepository({required SegueApiClient apiClient})
    : _apiClient = apiClient;

  final SegueApiClient _apiClient;

  @override
  Future<Customer> lookupCustomerByPhone(String phoneNumber) async {
    final Object? response = await _apiClient.getJson(
      '/api/customers/lookup',
      queryParameters: <String, Object?>{'phoneNumber': phoneNumber},
    );
    return Customer.fromJson(asJsonMap(response));
  }

  @override
  Future<CustomerConsent> submitCustomerConsent({
    required int customerId,
    required bool agreed,
  }) async {
    final Object? response = await _apiClient.postJson(
      '/api/customers/$customerId/consent',
      body: <String, Object?>{'agreed': agreed},
    );
    return CustomerConsent.fromJson(asJsonMap(response));
  }

  @override
  Future<CustomerConsent> fetchCustomerConsent(int customerId) async {
    final Object? response = await _apiClient.getJson(
      '/api/customers/$customerId/consent',
    );
    return CustomerConsent.fromJson(asJsonMap(response));
  }

  @override
  Future<List<MobileProduct>> fetchMobileProducts() async {
    final Object? response = await _apiClient.getJson('/api/products');
    return _mobileProductsFromResponse(response);
  }

  @override
  Future<CartItem> saveCartItem(CartSaveRequest request) async {
    final Object? response = await _apiClient.postJson(
      '/api/cart',
      body: request.toJson(),
    );
    return CartItem.fromJson(asJsonMap(response));
  }

  @override
  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  }) async {
    final Object? response = await _apiClient.getJson(
      '/api/cart',
      queryParameters: <String, Object?>{
        'customerId': customerId,
        'storeId': storeId,
      },
    );
    return asJsonList(
      response,
    ).map((Object? item) => CartItem.fromJson(asJsonMap(item))).toList();
  }

  @override
  Future<StructureIntentResponse> structureIntent(
    StructureIntentRequest request,
  ) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/intent',
      body: request.toJson(),
    );
    // No _validateStructureIntentResponse gate here (deliberately, see that
    // function's own doc comment) — _requireObject alone is enough: it
    // catches a genuinely broken response (not even a JSON object), while
    // StructureIntentResponse.fromJson/StructuredIntent.fromJson below
    // already tolerate every other kind of mismatch (missing/extra/wrongly
    // typed/out-of-vocabulary fields) by falling back to safe defaults
    // instead of throwing.
    final JsonMap json = _requireObject(response, 'structureIntent');
    return StructureIntentResponse.fromJson(json);
  }

  @override
  Future<FollowUpQuestion> requestFollowUpQuestion(
    FollowUpQuestionRequest request,
  ) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/followup-question',
      body: request.toJson(),
    );
    final JsonMap json = _requireObject(response, 'followUpQuestion');
    _requireNonEmptyString(json, 'question', 'followUpQuestion');
    return FollowUpQuestion.fromJson(json);
  }

  @override
  Future<StructureIntentResponse> submitFollowUpAnswer(
    FollowUpAnswerRequest request,
  ) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/followup-answer',
      body: request.toJson(),
    );
    // Same relaxed handling as structureIntent() above — same response shape.
    final JsonMap json = _requireObject(response, 'followUpAnswer');
    return StructureIntentResponse.fromJson(json);
  }

  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/decide',
      body: request.toJson(),
    );
    final JsonMap json = _requireObject(response, 'decide');
    _validateDecisionResult(json, 'decide');
    return DecisionResult.fromJson(json);
  }

  @override
  Future<ExecuteConsultationResponse> executeConsultation(
    ExecuteConsultationRequest request,
  ) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/execute',
      body: request.toJson(),
    );
    final JsonMap json = _requireObject(response, 'execute');
    _validateExecuteConsultationResponse(json, 'execute');
    return ExecuteConsultationResponse.fromJson(json);
  }

  @override
  Future<void> recordConsultationResult({
    required int customerId,
    required ConsultationResult result,
  }) async {
    // Issue #15: no real endpoint for this — the backend persists the
    // ConsultationResult itself as a side effect of `/execute` succeeding,
    // so there's nothing for a real client to explicitly save here. This
    // only does work in MockSegueRepository, which has no backend to do
    // that for it.
  }

  @override
  Future<List<ConsultationResult>> fetchConsultationResults(
    int customerId,
  ) async {
    final Object? response = await _apiClient.getJson(
      '/api/consultations/customers/$customerId',
    );
    final List<Object?> results = _requireResponseList(
      response,
      'fetchConsultationResults',
    );
    return results.map((Object? item) {
      final JsonMap json = _requireObject(item, 'consultationResult');
      _validateConsultationResult(json, 'consultationResult');
      return ConsultationResult.fromJson(json);
    }).toList();
  }

  @override
  Future<ConsultationResult> updateExecutionStatus({
    required int consultationResultId,
    required ExecutionStatusUpdateRequest request,
  }) async {
    final Object? response = await _apiClient.patchJson(
      '/api/consultations/$consultationResultId/execution-status',
      body: request.toJson(),
    );
    final JsonMap json = _requireObject(response, 'updateExecutionStatus');
    _validateConsultationResult(json, 'updateExecutionStatus');
    return ConsultationResult.fromJson(json);
  }
}

List<MobileProduct> _mobileProductsFromResponse(Object? response) {
  final List<Object?> productItems = _extractProductList(response);
  if (productItems.isEmpty) {
    return <MobileProduct>[];
  }

  return productItems
      .map(_mobileProductFromJson)
      .where((MobileProduct product) => product.name.trim().isNotEmpty)
      .toList();
}

List<Object?> _extractProductList(Object? response) {
  if (response is List) {
    return response.cast<Object?>();
  }

  final JsonMap json = asJsonMap(response);
  for (final String key in <String>[
    'products',
    'productList',
    'items',
    'data',
    'content',
  ]) {
    final List<Object?> items = asJsonList(json[key]);
    if (items.isNotEmpty) {
      return items;
    }
  }

  if (json.containsKey('productId') || json.containsKey('id')) {
    return <Object?>[json];
  }

  return <Object?>[];
}

MobileProduct _mobileProductFromJson(Object? value) {
  final JsonMap json = asJsonMap(value);
  final int id = intValue(
    json,
    'productId',
    defaultValue: intValue(json, 'id'),
  );
  final MobileProduct? fallback = MobileProductCatalog.tryProductById(id);
  final String productName = stringValue(
    json,
    'productName',
    defaultValue: _stringValueAny(json, <String>['name', 'product_name']),
  );
  final String category = _stringValueAny(json, <String>[
    'category',
    'categoryName',
    'category_name',
  ], defaultValue: '가방');
  final List<MobileSkuOption> options = _mobileSkuOptionsFromJson(
    json,
    fallback: fallback,
  );

  return MobileProduct(
    id: id,
    name: productName,
    collection: stringValue(
      json,
      'collection',
      defaultValue: _stringValueAny(json, <String>[
        'collectionName',
        'collection_name',
      ], defaultValue: category),
    ),
    category: category,
    price: intValue(
      json,
      'price',
      defaultValue: intValue(
        json,
        'priceWon',
        defaultValue: intValue(
          json,
          'unitPrice',
          defaultValue: intValue(json, 'unit_price', defaultValue: 0),
        ),
      ),
    ),
    material: stringValue(
      json,
      'material',
      defaultValue: options.isEmpty ? '' : options.first.material ?? '',
    ),
    dimensions: _stringValueAny(json, <String>[
      'dimensions',
      'dimension',
      'sizeDescription',
      'size_description',
    ]),
    origin: _stringValueAny(json, <String>['origin', 'madeIn', 'made_in']),
    season: _stringValueAny(json, <String>[
      'season',
      'seasonName',
      'season_name',
    ]),
    visualValue: fallback?.visualValue ?? 0xFF111827,
    accentValue: fallback?.accentValue ?? 0xFFB87945,
    options: options,
    imageUrl: _stringValueAny(json, <String>[
      'imageUrl',
      'image_url',
      'productImageUrl',
      'product_image_url',
    ]),
  );
}

List<MobileSkuOption> _mobileSkuOptionsFromJson(
  JsonMap json, {
  required MobileProduct? fallback,
}) {
  final List<Object?> skuItems = <Object?>[
    ...asJsonList(json['options']),
    ...asJsonList(json['skus']),
    ...asJsonList(json['skuList']),
    ...asJsonList(json['skuOptions']),
    ...asJsonList(json['skuOptionResponses']),
    ...asJsonList(json['variants']),
  ];
  if (skuItems.isEmpty) {
    if (!_containsAnyKey(json, <String>[
      'skuId',
      'id',
      'color',
      'colorName',
      'color_name',
      'size',
      'sizeName',
      'size_name',
    ])) {
      return <MobileSkuOption>[];
    }
    final JsonMap attributeJson = _attributeJson(json);
    final String color = _stringValueAny(json, <String>[
      'color',
      'colorName',
      'color_name',
    ]);
    final String size = _stringValueAny(json, <String>[
      'size',
      'sizeName',
      'size_name',
    ]);
    if (color.trim().isEmpty || size.trim().isEmpty) {
      return <MobileSkuOption>[];
    }
    return <MobileSkuOption>[
      MobileSkuOption(
        skuId: intValue(json, 'skuId', defaultValue: intValue(json, 'id')),
        color: color,
        size: size,
        swatchValue: fallback?.optionForColor(color).swatchValue ?? 0xFF111827,
        material:
            _nullableStringAny(json, <String>['material']) ??
            _nullableStringAny(attributeJson, <String>['material']),
        weightGrams: _nullableIntAny(json, <String>[
          'weightGrams',
          'weight_grams',
        ]),
        storageStructure: _nullableStringAny(json, <String>[
          'storageStructure',
          'storage_structure',
        ]),
        wearStyle: _nullableStringAny(json, <String>[
          'wearStyle',
          'wear_style',
        ]),
        laptopCompatible: _nullableBoolAny(json, <String>[
          'laptopCompatible',
          'laptop_compatible',
        ]),
        colorFamily:
            _nullableStringAny(json, <String>['colorFamily', 'color_family']) ??
            _nullableStringAny(attributeJson, <String>[
              'colorFamily',
              'color_family',
            ]),
        colorTone:
            _nullableStringAny(json, <String>['colorTone', 'color_tone']) ??
            _nullableStringAny(attributeJson, <String>[
              'colorTone',
              'color_tone',
            ]),
        sizeGrade:
            _nullableStringAny(json, <String>['sizeGrade', 'size_grade']) ??
            _nullableStringAny(attributeJson, <String>[
              'sizeGrade',
              'size_grade',
            ]),
      ),
    ];
  }

  return skuItems
      .map((Object? item) {
        final JsonMap skuJson = asJsonMap(item);
        final JsonMap attributeJson = _attributeJson(skuJson);
        final String color = _stringValueAny(skuJson, <String>[
          'color',
          'colorName',
          'color_name',
        ]);
        final String size = _stringValueAny(skuJson, <String>[
          'size',
          'sizeName',
          'size_name',
        ]);
        if (color.trim().isEmpty || size.trim().isEmpty) {
          return null;
        }
        return MobileSkuOption(
          skuId: intValue(
            skuJson,
            'skuId',
            defaultValue: intValue(skuJson, 'id'),
          ),
          color: color,
          size: size,
          swatchValue: _swatchValueFor(color, fallback: fallback),
          material:
              _nullableStringAny(skuJson, <String>['material']) ??
              _nullableStringAny(attributeJson, <String>['material']),
          weightGrams: _nullableIntAny(skuJson, <String>[
            'weightGrams',
            'weight_grams',
          ]),
          storageStructure: _nullableStringAny(skuJson, <String>[
            'storageStructure',
            'storage_structure',
          ]),
          wearStyle: _nullableStringAny(skuJson, <String>[
            'wearStyle',
            'wear_style',
          ]),
          laptopCompatible: _nullableBoolAny(skuJson, <String>[
            'laptopCompatible',
            'laptop_compatible',
          ]),
          colorFamily:
              _nullableStringAny(skuJson, <String>[
                'colorFamily',
                'color_family',
              ]) ??
              _nullableStringAny(attributeJson, <String>[
                'colorFamily',
                'color_family',
              ]),
          colorTone:
              _nullableStringAny(skuJson, <String>[
                'colorTone',
                'color_tone',
              ]) ??
              _nullableStringAny(attributeJson, <String>[
                'colorTone',
                'color_tone',
              ]),
          sizeGrade:
              _nullableStringAny(skuJson, <String>[
                'sizeGrade',
                'size_grade',
              ]) ??
              _nullableStringAny(attributeJson, <String>[
                'sizeGrade',
                'size_grade',
              ]),
        );
      })
      .whereType<MobileSkuOption>()
      .toList();
}

bool _containsAnyKey(JsonMap json, Iterable<String> keys) {
  for (final String key in keys) {
    if (json.containsKey(key)) {
      return true;
    }
  }
  return false;
}

String _stringValueAny(
  JsonMap json,
  Iterable<String> keys, {
  String defaultValue = '',
}) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value != null) {
      return value.toString();
    }
  }
  return defaultValue;
}

JsonMap _attributeJson(JsonMap json) {
  for (final String key in <String>[
    'attribute',
    'attributes',
    'productAttribute',
    'product_attribute',
  ]) {
    final Object? value = json[key];
    if (value is Map) {
      return asJsonMap(value);
    }
  }
  return <String, Object?>{};
}

String? _nullableStringAny(JsonMap json, Iterable<String> keys) {
  Object? value;
  for (final String key in keys) {
    value = json[key];
    if (value != null) {
      break;
    }
  }
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _nullableIntAny(JsonMap json, Iterable<String> keys) {
  Object? value;
  for (final String key in keys) {
    value = json[key];
    if (value != null) {
      break;
    }
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

bool? _nullableBoolAny(JsonMap json, Iterable<String> keys) {
  Object? value;
  for (final String key in keys) {
    value = json[key];
    if (value != null) {
      break;
    }
  }
  if (value is bool) {
    return value;
  }
  if (value is String) {
    final String normalized = value.toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  return null;
}

int _swatchValueFor(String color, {required MobileProduct? fallback}) {
  if (fallback != null) {
    for (final MobileSkuOption option in fallback.options) {
      if (option.color == color) {
        return option.swatchValue;
      }
    }
  }

  return switch (color.toLowerCase()) {
    'black' || '블랙' => 0xFF111827,
    'navy' || '네이비' => 0xFF1E3A5F,
    'beige' || '베이지' => 0xFFE8D9C5,
    'orange' || '오렌지' => 0xFFE85F35,
    'khaki' || '카키' => 0xFF66735F,
    _ => 0xFFB87945,
  };
}

const String _schemaMismatchMessage =
    '서버 응답 형식이 예상과 다릅니다. 백엔드 API 명세를 확인해 주세요.';

Never _throwSchemaMismatch(String context, String reason, {Object? details}) {
  throw ApiException(
    _schemaMismatchMessage,
    statusCode: 0,
    code: 'JSON_SCHEMA_MISMATCH',
    details: <String, Object?>{
      'context': context,
      'reason': reason,
      if (details != null) 'response': details,
    },
  );
}

JsonMap _requireObject(Object? value, String context) {
  if (value is! Map) {
    _throwSchemaMismatch(
      context,
      'response must be a JSON object',
      details: value,
    );
  }
  return asJsonMap(value);
}

List<Object?> _requireResponseList(Object? value, String context) {
  if (value is! List) {
    _throwSchemaMismatch(
      context,
      'response must be a JSON array',
      details: value,
    );
  }
  return value.cast<Object?>();
}

void _requireKeys(JsonMap json, Iterable<String> keys, String context) {
  for (final String key in keys) {
    if (!json.containsKey(key)) {
      _throwSchemaMismatch(
        context,
        'missing required field: $key',
        details: json,
      );
    }
  }
}

String _requireString(
  JsonMap json,
  String key,
  String context, {
  bool allowEmpty = true,
}) {
  final Object? value = json[key];
  if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
    _throwSchemaMismatch(
      context,
      'field "$key" must be a ${allowEmpty ? 'string' : 'non-empty string'}',
      details: json,
    );
  }
  return value;
}

String _requireNonEmptyString(JsonMap json, String key, String context) {
  return _requireString(json, key, context, allowEmpty: false);
}

void _requireNullableString(JsonMap json, String key, String context) {
  final Object? value = json[key];
  if (value != null && value is! String) {
    _throwSchemaMismatch(
      context,
      'field "$key" must be a string or null',
      details: json,
    );
  }
}

int _requireInt(JsonMap json, String key, String context) {
  final Object? value = json[key];
  if (value is! int) {
    _throwSchemaMismatch(
      context,
      'field "$key" must be an integer',
      details: json,
    );
  }
  return value;
}

JsonMap _requireMap(JsonMap json, String key, String context) {
  final Object? value = json[key];
  if (value is! Map) {
    _throwSchemaMismatch(
      context,
      'field "$key" must be an object',
      details: json,
    );
  }
  return asJsonMap(value);
}

void _requireOneOf(
  JsonMap json,
  String key,
  Iterable<String> values,
  String context,
) {
  final String value = _requireNonEmptyString(json, key, context);
  if (!values.contains(value)) {
    _throwSchemaMismatch(
      context,
      'field "$key" has unsupported value: $value',
      details: json,
    );
  }
}

void _validateDecisionResult(JsonMap json, String context) {
  _requireKeys(json, <String>[
    'resultType',
    'coreConditions',
    'nextAction',
    'reason',
    'difference',
    'recommendedProduct',
    'pathDescription',
    'actionType',
    'actionButtonLabel',
  ], context);
  _requireOneOf(
    json,
    'resultType',
    DecisionResultType.values.map((DecisionResultType value) => value.wireName),
    context,
  );
  _requireNonEmptyString(json, 'coreConditions', context);
  _requireNonEmptyString(json, 'nextAction', context);
  _requireNonEmptyString(json, 'reason', context);
  _requireString(json, 'difference', context);
  _requireString(json, 'pathDescription', context);
  _requireOneOf(
    json,
    'actionType',
    DecisionActionType.values.map((DecisionActionType value) => value.wireName),
    context,
  );
  _requireNonEmptyString(json, 'actionButtonLabel', context);

  final Object? recommended = json['recommendedProduct'];
  if (recommended == null) {
    return;
  }
  final JsonMap recommendedJson = _requireMap(
    json,
    'recommendedProduct',
    context,
  );
  _requireProductSkuSummary(recommendedJson, '$context.recommendedProduct');
}

void _validateExecuteConsultationResponse(JsonMap json, String context) {
  _requireKeys(json, <String>[
    'consultationResultId',
    'completionMessage',
  ], context);
  _requireInt(json, 'consultationResultId', context);
  _requireNonEmptyString(json, 'completionMessage', context);
}

void _validateConsultationResult(JsonMap json, String context) {
  _requireKeys(json, <String>[
    'id',
    'skuId',
    'productName',
    'imageUrl',
    'resultType',
    'recommendedPath',
    'coreConditions',
    'consultedAt',
    'executionStatus',
    'executionNote',
    'executionUpdatedAt',
  ], context);
  _requireInt(json, 'id', context);
  _requireInt(json, 'skuId', context);
  _requireNonEmptyString(json, 'productName', context);
  _requireString(json, 'imageUrl', context);
  _requireOneOf(
    json,
    'resultType',
    DecisionResultType.values.map((DecisionResultType value) => value.wireName),
    context,
  );
  _requireString(json, 'recommendedPath', context);
  _requireNonEmptyString(json, 'coreConditions', context);
  _requireDateTimeString(json, 'consultedAt', context);
  _requireOneOf(
    json,
    'executionStatus',
    ExecutionStatus.values.map((ExecutionStatus value) => value.wireName),
    context,
  );
  _requireNullableString(json, 'executionNote', context);
  _requireDateTimeString(json, 'executionUpdatedAt', context);
}

void _requireDateTimeString(JsonMap json, String key, String context) {
  final String value = _requireNonEmptyString(json, key, context);
  if (DateTime.tryParse(value) == null) {
    _throwSchemaMismatch(
      context,
      'field "$key" must be an ISO-8601 date-time string',
      details: json,
    );
  }
}

void _requireProductSkuSummary(JsonMap json, String context) {
  _requireKeys(json, <String>[
    'skuId',
    'productId',
    'productName',
    'imageUrl',
    'color',
    'size',
  ], context);
  if (json['skuId'] is! int || json['productId'] is! int) {
    _throwSchemaMismatch(
      context,
      'skuId/productId must be integers',
      details: json,
    );
  }
  _requireNonEmptyString(json, 'productName', context);
  _requireString(json, 'imageUrl', context);
  _requireNonEmptyString(json, 'color', context);
  _requireNonEmptyString(json, 'size', context);
}
