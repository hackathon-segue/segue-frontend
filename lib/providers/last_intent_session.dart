import 'package:flutter/foundation.dart';

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
      executionNote: executionNote ?? this.executionNote,
      intentState: intentState ?? this.intentState,
      followUpState: followUpState ?? this.followUpState,
      decisionState: decisionState ?? this.decisionState,
      executionState: executionState ?? this.executionState,
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
}
