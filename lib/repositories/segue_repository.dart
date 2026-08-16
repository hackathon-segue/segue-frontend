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

  Future<ConsultationResult> updateExecutionStatus({
    required int consultationResultId,
    required ExecutionStatusUpdateRequest request,
  });
}
