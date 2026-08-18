import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/app_config.dart';
import 'async_value.dart';

class StaffWebSessionState {
  const StaffWebSessionState({
    this.storeId = AppConfig.defaultStoreId,
    this.customer,
    this.cartItems = const <CartItem>[],
    this.lookupState = const AsyncValue<Customer>.idle(),
    this.consentState = const AsyncValue<CustomerConsent>.idle(),
    this.cartState = const AsyncValue<List<CartItem>>.idle(),
  });

  final int storeId;
  final Customer? customer;
  final List<CartItem> cartItems;
  final AsyncValue<Customer> lookupState;
  final AsyncValue<CustomerConsent> consentState;
  final AsyncValue<List<CartItem>> cartState;

  StaffWebSessionState copyWith({
    int? storeId,
    Customer? customer,
    List<CartItem>? cartItems,
    AsyncValue<Customer>? lookupState,
    AsyncValue<CustomerConsent>? consentState,
    AsyncValue<List<CartItem>>? cartState,
  }) {
    return StaffWebSessionState(
      storeId: storeId ?? this.storeId,
      customer: customer ?? this.customer,
      cartItems: cartItems ?? this.cartItems,
      lookupState: lookupState ?? this.lookupState,
      consentState: consentState ?? this.consentState,
      cartState: cartState ?? this.cartState,
    );
  }
}

class StaffWebSessionController extends ChangeNotifier {
  StaffWebSessionController({required SegueRepository repository})
    : _repository = repository;

  final SegueRepository _repository;

  StaffWebSessionState _state = const StaffWebSessionState();

  StaffWebSessionState get state => _state;

  /// Fired right before a new customer lookup begins. Issue #9 wires this to
  /// LastIntentSessionManager.reset so a different customer's cart never
  /// inherits a previous customer's in-progress Last Intent sessions.
  VoidCallback? onNewLookup;

  void setStoreId(int storeId) {
    _state = _state.copyWith(storeId: storeId);
    notifyListeners();
  }

  /// Clears any looked-up customer/cart/consent state, keeping only the
  /// current store context. Used when the CA starts a fresh customer lookup.
  void reset() {
    _state = StaffWebSessionState(storeId: _state.storeId);
    notifyListeners();
  }

  Future<void> lookupCustomer(String phoneNumber) async {
    onNewLookup?.call();
    // Reset to a fresh state (keeping only storeId) so a new customer lookup
    // never carries over a previous customer's cart/consent state.
    _state = StaffWebSessionState(
      storeId: _state.storeId,
      lookupState: const AsyncValue<Customer>.loading(),
    );
    notifyListeners();

    try {
      final Customer customer = await _repository.lookupCustomerByPhone(
        phoneNumber,
      );
      _state = _state.copyWith(
        customer: customer,
        lookupState: AsyncValue<Customer>.data(customer),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        lookupState: AsyncValue<Customer>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> submitConsent(bool agreed) async {
    final Customer? customer = _state.customer;
    if (customer == null) {
      return;
    }

    _state = _state.copyWith(
      consentState: const AsyncValue<CustomerConsent>.loading(),
    );
    notifyListeners();

    try {
      final CustomerConsent consent = await _repository.submitCustomerConsent(
        customerId: customer.id,
        agreed: agreed,
      );
      _state = _state.copyWith(
        customer: customer.copyWith(hasConsented: consent.hasAgreed),
        consentState: AsyncValue<CustomerConsent>.data(consent),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        consentState: AsyncValue<CustomerConsent>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> loadCart() async {
    final Customer? customer = _state.customer;
    if (customer == null) {
      return;
    }

    _state = _state.copyWith(
      cartState: const AsyncValue<List<CartItem>>.loading(),
    );
    notifyListeners();

    try {
      final List<CartItem> cartItems = await _repository.fetchCart(
        customerId: customer.id,
        storeId: _state.storeId,
      );
      _state = _state.copyWith(
        cartItems: cartItems,
        cartState: AsyncValue<List<CartItem>>.data(cartItems),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        cartState: AsyncValue<List<CartItem>>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }
}
