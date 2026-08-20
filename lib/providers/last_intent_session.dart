import 'package:flutter/foundation.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/app_config.dart';
import 'async_value.dart';

/// Which Last Intent screen this SKU's session should resume into — set by
/// each screen right before it navigates to the next one, so "상담 이어서
/// 진행" (Home) can jump straight back to the last screen the CA was on
/// instead of always restarting from the utterance step.
enum LastIntentStep {
  utterance,
  followUp,
  confirm,
  card,
  resultProduct,
  additionalConsultation;

  static LastIntentStep fromWire(String value) {
    return LastIntentStep.values.firstWhere(
      (LastIntentStep step) => step.name == value,
      orElse: () => LastIntentStep.utterance,
    );
  }
}

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
    this.additionalConsultationDeclined = false,
    this.currentStep = LastIntentStep.utterance,
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

  /// Issue #64: local, frontend-only display flag — true once the CA picks
  /// "추가 상담 미진행" (169:3821) and confirms. Deliberately NOT a new
  /// `ExecutionStatus` value (backend only defines REQUESTED/UNABLE/
  /// FOLLOW_UP_NEEDED) and NOT sent to any API — execute() still runs for
  /// this branch exactly as before, so [executionResponse] alone already
  /// keeps this SKU out of [LastIntentSessionManager.activeCount]/
  /// [LastIntentSessionManager.firstActiveSession]; this field only decides
  /// which badge text/color the cart row shows ("상담 중단" vs "상담 완료",
  /// Figma 98:1740). Lost on page refresh, same as every other field here —
  /// persisting across reload would need a real backend field, not a
  /// frontend workaround.
  final bool additionalConsultationDeclined;

  /// Which screen "상담 이어서 진행" (Home) should resume into. Set by each
  /// screen right before it navigates to the next one — not inferred from
  /// which data fields happen to be filled in, since e.g. a re-visited
  /// utterance screen (via "수정할게요") still has a non-null
  /// [structuredIntent] while genuinely being back on the utterance step.
  final LastIntentStep currentStep;

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
    bool? additionalConsultationDeclined,
    LastIntentStep? currentStep,
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
      additionalConsultationDeclined:
          additionalConsultationDeclined ?? this.additionalConsultationDeclined,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  /// True once this SKU's session has real customer/product/step data worth
  /// persisting — a controller that was only ever constructed but never
  /// [LastIntentSessionController.start]ed has nothing to save.
  bool get isPersistable => customer != null && selectedCartItem != null;

  /// Serializes exactly what "상담 이어서 진행" needs to resume this session
  /// without re-calling any AI/decide endpoint — reuses every field's own
  /// existing model [toJson]/[fromJson] rather than inventing a parallel DTO.
  ///
  /// Includes the full [Customer]/[CartItem] (not just their ids) because
  /// there is no "look up customer/cart-item by id" endpoint in API.md — an
  /// id-only record could not be turned back into a usable [Customer]/
  /// [CartItem] on restore without one.
  JsonMap toPersistedJson() {
    return <String, Object?>{
      'customer': customer?.toJson(),
      'cartItem': selectedCartItem?.toJson(),
      'currentStep': currentStep.name,
      'utterance': utterance,
      'structuredIntent': structuredIntent?.toJson(),
      'followUpQuestion': followUpQuestion == null
          ? null
          : <String, Object?>{'question': followUpQuestion!.question},
      'followUpAnswer': followUpAnswer,
      'decisionResult': decisionResult?.toJson(),
    };
  }

  /// Reconstructs a session from [toPersistedJson]'s output. Returns null
  /// for an entry missing its customer/cartItem (nothing usable to resume).
  static LastIntentSessionState? fromPersistedJson(JsonMap json) {
    final Object? customerJson = json['customer'];
    final Object? cartItemJson = json['cartItem'];
    if (customerJson is! Map || cartItemJson is! Map) {
      return null;
    }
    final Object? structuredIntentJson = json['structuredIntent'];
    final Object? followUpQuestionJson = json['followUpQuestion'];
    final Object? decisionResultJson = json['decisionResult'];
    return LastIntentSessionState(
      customer: Customer.fromJson(asJsonMap(customerJson)),
      selectedCartItem: CartItem.fromJson(asJsonMap(cartItemJson)),
      currentStep: LastIntentStep.fromWire(
        stringValue(json, 'currentStep', defaultValue: LastIntentStep.utterance.name),
      ),
      utterance: stringValue(json, 'utterance'),
      structuredIntent: structuredIntentJson is Map
          ? StructuredIntent.fromJson(asJsonMap(structuredIntentJson))
          : null,
      followUpQuestion: followUpQuestionJson is Map
          ? FollowUpQuestion.fromJson(asJsonMap(followUpQuestionJson))
          : null,
      followUpAnswer: stringValue(json, 'followUpAnswer'),
      decisionResult: decisionResultJson is Map
          ? DecisionResult.fromJson(asJsonMap(decisionResultJson))
          : null,
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

  /// Rehydrates a session from a previously-persisted [state]
  /// ([LastIntentSessionState.toPersistedJson]) — used only at app startup
  /// by [LastIntentSessionManager] to restore active consultations after a
  /// refresh. Unlike [start], this does NOT reset progress: it takes the
  /// already-reconstructed state as-is.
  void restore(LastIntentSessionState state) {
    _state = state;
    notifyListeners();
  }

  /// Records which screen this SKU's session is currently on — see
  /// [LastIntentSessionState.currentStep]'s doc comment for why this is
  /// tracked explicitly instead of inferred from filled-in fields.
  void setCurrentStep(LastIntentStep step) {
    _state = _state.copyWith(currentStep: step);
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
      // A real backend can return HTTP 200 with a JSON body that doesn't
      // match the strict schema this app validates responses against
      // (RealSegueRepository._validateStructuredIntent) — e.g. a missing
      // required key or a purchaseUrgency value outside the known enum.
      // That failure mode is otherwise invisible: the UI only ever shows
      // the generic "다시 시도" card, never which field actually broke.
      // ApiException(code: 'JSON_SCHEMA_MISMATCH').details carries the
      // exact reason + raw response, so log it for debugging.
      _logSessionError('structureIntent', error);
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
      // Same JSON_SCHEMA_MISMATCH risk as structureIntent() — this endpoint
      // returns the same StructureIntentResponse shape.
      _logSessionError('submitFollowUpAnswer', error);
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
      // recordConsultationResult is the ONE step that can genuinely fail to
      // save anything — RealSegueRepository's own version is a documented
      // no-op (the backend already persisted the record as a side effect of
      // /execute), so only MockSegueRepository's local write can actually
      // throw here. Left outside the fallback below on purpose: if this
      // throws, nothing was saved, so a real error is correct.
      await _repository.recordConsultationResult(
        customerId: customer.id,
        result: result,
      );

      ConsultationResult savedResult;
      try {
        savedResult = await _fetchSavedConsultationResultWithRetry(
          customerId: customer.id,
          consultationResultId: response.consultationResultId,
        );
      } on AppException catch (error) {
        // This fetch is only a best-effort double-check that the record
        // execute()/recordConsultationResult already created is visible
        // server-side — it never does the saving itself. A persistent
        // failure here (backend read-after-write lag longer than the
        // retries above cover, or a bug in the list endpoint) must not
        // turn an action that already succeeded into a visible "저장
        // 실패" error for the CA. Fall back to the locally-built result
        // instead — it carries the same id/status the server is supposed
        // to have, just not server-confirmed yet.
        _logSessionError(
          'saveConsultationResult (confirm fetch failed, using local '
          'result instead of failing)',
          error,
        );
        savedResult = result;
      }
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

  // A real backend can persist the record inside /execute and still have a
  // brief read-after-write lag before that same record shows up in this
  // immediately-following GET — the CA sees this as "상담완료 눌렀는데
  // 에러뜸" even though execute() itself already succeeded. A couple of
  // short retries absorbs that lag instead of surfacing an error for
  // something that's about to resolve on its own a moment later.
  static const List<Duration> _resultConfirmRetryDelays = <Duration>[
    Duration(milliseconds: 300),
    Duration(milliseconds: 600),
  ];

  Future<ConsultationResult> _fetchSavedConsultationResultWithRetry({
    required int customerId,
    required int consultationResultId,
  }) async {
    for (int attempt = 0; ; attempt++) {
      try {
        return await _fetchSavedConsultationResult(
          customerId: customerId,
          consultationResultId: consultationResultId,
        );
      } on AppException catch (error) {
        final bool notFound = error.code == 'CONSULTATION_RESULT_NOT_FOUND';
        if (!notFound || attempt >= _resultConfirmRetryDelays.length) {
          rethrow;
        }
        await Future<void>.delayed(_resultConfirmRetryDelays[attempt]);
      }
    }
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

  /// Issue #64: marks this SKU's "추가 상담 미진행" (169:3821) outcome —
  /// call only after [execute] has already succeeded (so
  /// [LastIntentSessionState.executionResponse] is set and this SKU already
  /// counts as complete for activeCount/firstActiveSession); this just
  /// flags which badge the cart row should show.
  void declineAdditionalConsultation() {
    _state = _state.copyWith(additionalConsultationDeclined: true);
    notifyListeners();
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

/// Prints the real reason behind a caught session error to the debug
/// console — the UI only ever shows a generic "다시 시도" card, so without
/// this there's no way to tell a network/timeout failure apart from a real
/// backend response that came back HTTP 200 but didn't match the schema
/// [RealSegueRepository] validates against ([ApiException.code] ==
/// 'JSON_SCHEMA_MISMATCH', [ApiException.details] carries the exact missing/
/// invalid field plus the raw response body).
void _logSessionError(String context, Object error) {
  if (error is ApiException) {
    debugPrint(
      '[LastIntentSession] $context failed — ${error.code ?? 'unknown'} '
      '(status ${error.statusCode}): ${error.message}\n'
      'details: ${error.details}',
    );
  } else {
    debugPrint('[LastIntentSession] $context failed — $error');
  }
}
