import '../models/models.dart';

abstract interface class SegueRepository {
  Future<Customer> loginCustomer({
    required String email,
    required String password,
  });

  Future<Customer> lookupCustomerByPhone(String phoneNumber);

  Future<CustomerConsent> submitCustomerConsent({
    required int customerId,
    required bool agreed,
  });

  Future<CustomerConsent> fetchCustomerConsent(int customerId);

  Future<List<MobileProduct>> fetchMobileProducts();

  Future<CartItem> saveCartItem(CartSaveRequest request);

  /// CA 태블릿용 — CA 가 고객의 장바구니를 조회한다 (`GET /api/cart`).
  ///
  /// 남의 데이터를 열람하는 경로라 백엔드에 동의 게이트가 걸려 있고, 동의 기록이 없는
  /// 고객이면 403 이 온다. 그 403 은 버그가 아니라 동의 화면으로 유도하라는 신호다.
  Future<List<CartItem>> fetchCart({
    required int customerId,
    required int storeId,
  });

  /// 고객 모바일용 — 고객이 자기 쇼핑백을 조회한다 (`GET /api/cart/mine`).
  ///
  /// 본인이 본인 데이터를 보는 것이라 동의 게이트가 없다. 동의는 CA 가 고객 데이터를
  /// 열람할 때 확인하는 절차이기 때문이다. 백엔드가 파라미터 분기 대신 엔드포인트를
  /// 나눠 둔 것도 같은 이유이므로, 고객 화면에서 [fetchCart] 를 쓰면 동의 전 고객과
  /// 신규 가입 고객이 자기 쇼핑백에서 403 을 받는다.
  Future<List<CartItem>> fetchOwnCart({
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
