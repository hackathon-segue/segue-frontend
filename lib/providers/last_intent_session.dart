import 'package:flutter/foundation.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/app_config.dart';
import 'async_value.dart';

class LastIntentSessionState {
  const LastIntentSessionState({
    this.storeId = AppConfig.defaultStoreId,
    this.customer,
    this.selectedCartItem,
    this.utterance = '',
    this.structuredIntent,
    this.followUpQuestion,
    this.followUpAnswer = '',
    this.decisionResult,
    this.executionResponse,
    this.executionStatus,
    this.executionNote,
    this.intentState = const AsyncValue<StructureIntentResponse>.idle(),
    this.followUpState = const AsyncValue<FollowUpQuestion>.idle(),
    this.decisionState = const AsyncValue<DecisionResult>.idle(),
    this.executionState = const AsyncValue<ExecuteConsultationResponse>.idle(),
    this.resultSaveState = const AsyncValue<ConsultationResult>.idle(),
    this.executionStatusUpdateState =
        const AsyncValue<ConsultationResult>.idle(),
  });

  final int storeId;
  final Customer? customer;
  final CartItem? selectedCartItem;
  final String utterance;
  final StructuredIntent? structuredIntent;
  final FollowUpQuestion? followUpQuestion;
  final String followUpAnswer;
  final DecisionResult? decisionResult;
  final ExecuteConsultationResponse? executionResponse;
  // Issue #14: ExecuteConsultationResponse itself carries no status field —
  // a successful execute() call means REQUESTED by definition. UNABLE/
  // FOLLOW_UP_NEEDED are only reachable via the PATCH
  // updateExecutionStatus() flow, which is a later issue's scope; these
  // fields exist now so the completion screen's UI can already render all
  // three without rework once that flow lands.
  final ExecutionStatus? executionStatus;
  final String? executionNote;
  final AsyncValue<StructureIntentResponse> intentState;
  final AsyncValue<FollowUpQuestion> followUpState;
  final AsyncValue<DecisionResult> decisionState;
  final AsyncValue<ExecuteConsultationResponse> executionState;
  // Issue #15: separate from executionState on purpose — execute() itself
  // can succeed while the (mock/local) ConsultationResult save afterward
  // still fails, and the UI needs to tell those two failure modes apart
  // (and retry only the save, not re-execute) rather than treating "saved"
  // as implied by "executed".
  final AsyncValue<ConsultationResult> resultSaveState;
  final AsyncValue<ConsultationResult> executionStatusUpdateState;

  LastIntentSessionState copyWith({
    int? storeId,
    Customer? customer,
    CartItem? selectedCartItem,
    String? utterance,
    StructuredIntent? structuredIntent,
    FollowUpQuestion? followUpQuestion,
    String? followUpAnswer,
    DecisionResult? decisionResult,
    ExecuteConsultationResponse? executionResponse,
    ExecutionStatus? executionStatus,
    String? executionNote,
    AsyncValue<StructureIntentResponse>? intentState,
    AsyncValue<FollowUpQuestion>? followUpState,
    AsyncValue<DecisionResult>? decisionState,
    AsyncValue<ExecuteConsultationResponse>? executionState,
    AsyncValue<ConsultationResult>? resultSaveState,
    AsyncValue<ConsultationResult>? executionStatusUpdateState,
    bool clearExecutionNote = false,
  }) {
    return LastIntentSessionState(
      storeId: storeId ?? this.storeId,
      customer: customer ?? this.customer,
      selectedCartItem: selectedCartItem ?? this.selectedCartItem,
      utterance: utterance ?? this.utterance,
      structuredIntent: structuredIntent ?? this.structuredIntent,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
      followUpAnswer: followUpAnswer ?? this.followUpAnswer,
      decisionResult: decisionResult ?? this.decisionResult,
      executionResponse: executionResponse ?? this.executionResponse,
      executionStatus: executionStatus ?? this.executionStatus,
      executionNote: clearExecutionNote
          ? null
          : executionNote ?? this.executionNote,
      intentState: intentState ?? this.intentState,
      followUpState: followUpState ?? this.followUpState,
      decisionState: decisionState ?? this.decisionState,
      executionState: executionState ?? this.executionState,
      resultSaveState: resultSaveState ?? this.resultSaveState,
      executionStatusUpdateState:
          executionStatusUpdateState ?? this.executionStatusUpdateState,
    );
  }
}

class LastIntentSessionController extends ChangeNotifier {
  LastIntentSessionController({required SegueRepository repository})
    : _repository = repository;

  final SegueRepository _repository;

  LastIntentSessionState _state = const LastIntentSessionState();

  LastIntentSessionState get state => _state;

  void start({
    required Customer customer,
    required CartItem cartItem,
    int storeId = AppConfig.defaultStoreId,
  }) {
    _state = LastIntentSessionState(
      customer: customer,
      selectedCartItem: cartItem,
      storeId: storeId,
    );
    notifyListeners();
  }

  Future<void> structureIntent(String utterance) async {
    final CartItem? selectedCartItem = _state.selectedCartItem;
    if (selectedCartItem == null) {
      return;
    }

    _state = _state.copyWith(
      utterance: utterance,
      intentState: const AsyncValue<StructureIntentResponse>.loading(),
    );
    notifyListeners();

    try {
      final StructureIntentResponse response = await _repository
          .structureIntent(
            StructureIntentRequest(
              storeId: _state.storeId,
              skuId: selectedCartItem.skuId,
              utterance: utterance,
            ),
          );
      _state = _state.copyWith(
        structuredIntent: response.structuredIntent,
        intentState: AsyncValue<StructureIntentResponse>.data(response),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        intentState: AsyncValue<StructureIntentResponse>.error(
          error,
          stackTrace,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> requestFollowUpQuestion() async {
    final StructuredIntent? intent = _state.structuredIntent;
    if (intent == null) {
      return;
    }

    _state = _state.copyWith(
      followUpState: const AsyncValue<FollowUpQuestion>.loading(),
    );
    notifyListeners();

    try {
      final FollowUpQuestion question = await _repository
          .requestFollowUpQuestion(
            FollowUpQuestionRequest(
              utterance: _state.utterance,
              currentIntent: intent,
            ),
          );
      _state = _state.copyWith(
        followUpQuestion: question,
        followUpState: AsyncValue<FollowUpQuestion>.data(question),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        followUpState: AsyncValue<FollowUpQuestion>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> submitFollowUpAnswer(String answer) async {
    final FollowUpQuestion? question = _state.followUpQuestion;
    if (question == null) {
      return;
    }

    _state = _state.copyWith(
      followUpAnswer: answer,
      intentState: const AsyncValue<StructureIntentResponse>.loading(),
    );
    notifyListeners();

    try {
      final StructureIntentResponse response = await _repository
          .submitFollowUpAnswer(
            FollowUpAnswerRequest(
              utterance: _state.utterance,
              followUpQuestion: question.question,
              followUpAnswer: answer,
            ),
          );
      _state = _state.copyWith(
        structuredIntent: response.structuredIntent,
        intentState: AsyncValue<StructureIntentResponse>.data(response),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        intentState: AsyncValue<StructureIntentResponse>.error(
          error,
          stackTrace,
        ),
      );
    }
    notifyListeners();
  }

  void updateStructuredIntent(StructuredIntent structuredIntent) {
    _state = _state.copyWith(structuredIntent: structuredIntent);
    notifyListeners();
  }

  Future<void> decide() async {
    final CartItem? selectedCartItem = _state.selectedCartItem;
    final StructuredIntent? intent = _state.structuredIntent;
    if (selectedCartItem == null || intent == null) {
      return;
    }

    _state = _state.copyWith(
      decisionState: const AsyncValue<DecisionResult>.loading(),
    );
    notifyListeners();

    try {
      final DecisionResult result = await _repository.decide(
        DecisionRequest(
          storeId: _state.storeId,
          skuId: selectedCartItem.skuId,
          structuredIntent: intent,
        ),
      );
      _state = _state.copyWith(
        decisionResult: result,
        decisionState: AsyncValue<DecisionResult>.data(result),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        decisionState: AsyncValue<DecisionResult>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> execute() async {
    final Customer? customer = _state.customer;
    final CartItem? selectedCartItem = _state.selectedCartItem;
    final DecisionResult? decisionResult = _state.decisionResult;
    if (customer == null ||
        selectedCartItem == null ||
        decisionResult == null) {
      return;
    }

    _state = _state.copyWith(
      executionState: const AsyncValue<ExecuteConsultationResponse>.loading(),
    );
    notifyListeners();

    try {
      final ExecuteConsultationResponse response = await _repository
          .executeConsultation(
            ExecuteConsultationRequest.fromDecisionResult(
              customerId: customer.id,
              skuId: selectedCartItem.skuId,
              decisionResult: decisionResult,
            ),
          );
      _state = _state.copyWith(
        executionResponse: response,
        // AC: execute 성공 후 executionStatus는 REQUESTED로 시작한다.
        executionStatus: ExecutionStatus.requested,
        executionState: AsyncValue<ExecuteConsultationResponse>.data(response),
      );
      notifyListeners();
      // Issue #15: local/mock save only starts once execute() has actually
      // succeeded (REQUESTED reached) — never on a failed execute().
      await _saveConsultationResult(response);
      return;
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        executionState: AsyncValue<ExecuteConsultationResponse>.error(
          error,
          stackTrace,
        ),
      );
    }
    notifyListeners();
  }

  /// Retries ONLY the local/mock ConsultationResult save — used when
  /// execute() already succeeded but the save itself failed. Never
  /// re-executes (that would risk a duplicate real-world execute request)
  /// and never regenerates the Card/decide() result — it reuses exactly
  /// what's already in session state.
  Future<void> retrySaveConsultationResult() async {
    final ExecuteConsultationResponse? response = _state.executionResponse;
    if (response == null) {
      return;
    }
    await _saveConsultationResult(response);
  }

  Future<void> _saveConsultationResult(
    ExecuteConsultationResponse response,
  ) async {
    final Customer? customer = _state.customer;
    final CartItem? selectedCartItem = _state.selectedCartItem;
    final DecisionResult? decisionResult = _state.decisionResult;
    final ExecutionStatus? executionStatus = _state.executionStatus;
    if (customer == null ||
        selectedCartItem == null ||
        decisionResult == null ||
        executionStatus == null) {
      return;
    }

    _state = _state.copyWith(
      resultSaveState: const AsyncValue<ConsultationResult>.loading(),
    );
    notifyListeners();

    final ProductSkuSummary? recommended = decisionResult.recommendedProduct;
    final ConsultationResult result = ConsultationResult(
      id: response.consultationResultId,
      skuId: selectedCartItem.skuId,
      productName: selectedCartItem.productName,
      imageUrl: selectedCartItem.imageUrl,
      resultType: decisionResult.resultType,
      // AC: Last Intent Card와 저장 결과가 일치 — Card가 보여준 것과 같은 규칙
      // (recommendedProduct 있으면 제품, 없으면 확보 경로)으로 저장한다.
      recommendedPath: recommended != null
          ? '${recommended.productName} (${recommended.color})'
          : decisionResult.pathDescription,
      coreConditions: decisionResult.coreConditions,
      consultedAt: DateTime.now(),
      executionStatus: executionStatus,
      executionNote: _state.executionNote,
      executionUpdatedAt: DateTime.now(),
    );

    try {
      await _repository.recordConsultationResult(
        customerId: customer.id,
        result: result,
      );
      final ConsultationResult savedResult =
          await _fetchSavedConsultationResult(
            customerId: customer.id,
            consultationResultId: response.consultationResultId,
          );
      _state = _state.copyWith(
        executionStatus: savedResult.executionStatus,
        executionNote: savedResult.executionNote,
        clearExecutionNote: savedResult.executionNote == null,
        resultSaveState: AsyncValue<ConsultationResult>.data(savedResult),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        resultSaveState: AsyncValue<ConsultationResult>.error(
          error,
          stackTrace,
        ),
      );
    }
    notifyListeners();
  }

  Future<ConsultationResult> _fetchSavedConsultationResult({
    required int customerId,
    required int consultationResultId,
  }) async {
    final List<ConsultationResult> results = await _repository
        .fetchConsultationResults(customerId);
    for (final ConsultationResult result in results) {
      if (result.id == consultationResultId) {
        return result;
      }
    }
    throw const AppException(
      '상담 결과 저장 확인에 실패했습니다. 모바일 결과 조회를 다시 시도해 주세요.',
      code: 'CONSULTATION_RESULT_NOT_FOUND',
    );
  }

  Future<void> updateExecutionStatus(
    ExecutionStatus status, {
    String? note,
  }) async {
    final ExecuteConsultationResponse? response = _state.executionResponse;
    if (response == null) {
      return;
    }

    final String? trimmedNote = note?.trim();
    _state = _state.copyWith(
      executionStatusUpdateState:
          const AsyncValue<ConsultationResult>.loading(),
    );
    notifyListeners();

    try {
      final ConsultationResult updated = await _repository
          .updateExecutionStatus(
            consultationResultId: response.consultationResultId,
            request: ExecutionStatusUpdateRequest(
              status: status,
              note: trimmedNote == null || trimmedNote.isEmpty
                  ? null
                  : trimmedNote,
            ),
          );
      _state = _state.copyWith(
        executionStatus: updated.executionStatus,
        executionNote: updated.executionNote,
        clearExecutionNote: updated.executionNote == null,
        resultSaveState: AsyncValue<ConsultationResult>.data(updated),
        executionStatusUpdateState: AsyncValue<ConsultationResult>.data(
          updated,
        ),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        executionStatusUpdateState: AsyncValue<ConsultationResult>.error(
          error,
          stackTrace,
        ),
      );
    }
    notifyListeners();
  }
}
