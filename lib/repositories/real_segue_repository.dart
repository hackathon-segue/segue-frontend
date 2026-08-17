import '../models/models.dart';
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
    return StructureIntentResponse.fromJson(asJsonMap(response));
  }

  @override
  Future<FollowUpQuestion> requestFollowUpQuestion(
    FollowUpQuestionRequest request,
  ) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/followup-question',
      body: request.toJson(),
    );
    return FollowUpQuestion.fromJson(asJsonMap(response));
  }

  @override
  Future<StructureIntentResponse> submitFollowUpAnswer(
    FollowUpAnswerRequest request,
  ) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/followup-answer',
      body: request.toJson(),
    );
    return StructureIntentResponse.fromJson(asJsonMap(response));
  }

  @override
  Future<DecisionResult> decide(DecisionRequest request) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/decide',
      body: request.toJson(),
    );
    return DecisionResult.fromJson(asJsonMap(response));
  }

  @override
  Future<ExecuteConsultationResponse> executeConsultation(
    ExecuteConsultationRequest request,
  ) async {
    final Object? response = await _apiClient.postJson(
      '/api/consultations/execute',
      body: request.toJson(),
    );
    return ExecuteConsultationResponse.fromJson(asJsonMap(response));
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
    return asJsonList(response)
        .map((Object? item) => ConsultationResult.fromJson(asJsonMap(item)))
        .toList();
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
    return ConsultationResult.fromJson(asJsonMap(response));
  }
}
