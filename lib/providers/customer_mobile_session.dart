import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'async_value.dart';

class CustomerMobileSessionState {
  const CustomerMobileSessionState({
    this.customerId,
    this.lastSavedCartItem,
    this.consultationResults = const <ConsultationResult>[],
    this.saveCartState = const AsyncValue<CartItem>.idle(),
    this.resultsState = const AsyncValue<List<ConsultationResult>>.idle(),
  });

  final int? customerId;
  final CartItem? lastSavedCartItem;
  final List<ConsultationResult> consultationResults;
  final AsyncValue<CartItem> saveCartState;
  final AsyncValue<List<ConsultationResult>> resultsState;

  CustomerMobileSessionState copyWith({
    int? customerId,
    CartItem? lastSavedCartItem,
    List<ConsultationResult>? consultationResults,
    AsyncValue<CartItem>? saveCartState,
    AsyncValue<List<ConsultationResult>>? resultsState,
  }) {
    return CustomerMobileSessionState(
      customerId: customerId ?? this.customerId,
      lastSavedCartItem: lastSavedCartItem ?? this.lastSavedCartItem,
      consultationResults: consultationResults ?? this.consultationResults,
      saveCartState: saveCartState ?? this.saveCartState,
      resultsState: resultsState ?? this.resultsState,
    );
  }
}

class CustomerMobileSessionController extends ChangeNotifier {
  CustomerMobileSessionController({required SegueRepository repository})
    : _repository = repository;

  final SegueRepository _repository;

  CustomerMobileSessionState _state = const CustomerMobileSessionState();

  CustomerMobileSessionState get state => _state;

  Future<void> saveCartItem(CartSaveRequest request) async {
    _state = _state.copyWith(
      customerId: request.customerId,
      saveCartState: const AsyncValue<CartItem>.loading(),
    );
    notifyListeners();

    try {
      final CartItem item = await _repository.saveCartItem(request);
      _state = _state.copyWith(
        lastSavedCartItem: item,
        saveCartState: AsyncValue<CartItem>.data(item),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        saveCartState: AsyncValue<CartItem>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> loadConsultationResults(int customerId) async {
    _state = _state.copyWith(
      customerId: customerId,
      resultsState: const AsyncValue<List<ConsultationResult>>.loading(),
    );
    notifyListeners();

    try {
      final List<ConsultationResult> results = await _repository
          .fetchConsultationResults(customerId);
      _state = _state.copyWith(
        consultationResults: results,
        resultsState: AsyncValue<List<ConsultationResult>>.data(results),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        resultsState: AsyncValue<List<ConsultationResult>>.error(
          error,
          stackTrace,
        ),
      );
    }
    notifyListeners();
  }
}
