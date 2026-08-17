import '../models/models.dart';

abstract interface class SegueRepository {
  Future<Customer> lookupCustomerByPhone(String phoneNumber);

  Future<CustomerConsent> submitCustomerConsent({
    required int customerId,
    required bool agreed,
  });

  Future<CustomerConsent> fetchCustomerConsent(int customerId);

  Future<CartItem> saveCartItem(CartSaveRequest request);

  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  });

  Future<StructureIntentResponse> structureIntent(
    StructureIntentRequest request,
  );

  Future<FollowUpQuestion> requestFollowUpQuestion(
    FollowUpQuestionRequest request,
  );

  Future<StructureIntentResponse> submitFollowUpAnswer(
    FollowUpAnswerRequest request,
  );

  Future<DecisionResult> decide(DecisionRequest request);

  Future<ExecuteConsultationResponse> executeConsultation(
    ExecuteConsultationRequest request,
  );

  Future<List<ConsultationResult>> fetchConsultationResults(int customerId);

  /// Issue #15: NOT a real backend endpoint — the real API creates a
  /// ConsultationResult server-side as a side effect of a successful
  /// `POST /api/consultations/execute` call, so a real implementation has
  /// nothing to do here (see [RealSegueRepository]). This exists purely so
  /// the mock/local flow (tablet execute() -> customer mobile results) can
  /// be exercised end to end before Final Integration wires the real API,
  /// without adding fields to [ExecuteConsultationRequest] that the real
  /// `/execute` contract doesn't have.
  Future<void> recordConsultationResult({
    required int customerId,
    required ConsultationResult result,
  });

  Future<ConsultationResult> updateExecutionStatus({
    required int consultationResultId,
    required ExecutionStatusUpdateRequest request,
  });
}
