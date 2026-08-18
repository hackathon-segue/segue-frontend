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
    this.checkedInStockSkuIds = const <int>{},
  });

  final int storeId;
  final Customer? customer;
  final List<CartItem> cartItems;
  final AsyncValue<Customer> lookupState;
  final AsyncValue<CustomerConsent> consentState;
  final AsyncValue<List<CartItem>> cartState;

  /// SKU ids of in-stock cart items the CA has confirmed via
  /// [GeneralProductCheckScreen]'s "해당 제품 상담 완료" button. In-stock
  /// items have no Last Intent session (no structureIntent/decide/execute),
  /// so this is the only signal for their per-row "상담 완료" state.
  final Set<int> checkedInStockSkuIds;

  StaffWebSessionState copyWith({
    int? storeId,
    Customer? customer,
    List<CartItem>? cartItems,
    AsyncValue<Customer>? lookupState,
    AsyncValue<CustomerConsent>? consentState,
    AsyncValue<List<CartItem>>? cartState,
    Set<int>? checkedInStockSkuIds,
  }) {
    return StaffWebSessionState(
      storeId: storeId ?? this.storeId,
      customer: customer ?? this.customer,
      cartItems: cartItems ?? this.cartItems,
      lookupState: lookupState ?? this.lookupState,
      consentState: consentState ?? this.consentState,
      cartState: cartState ?? this.cartState,
      checkedInStockSkuIds: checkedInStockSkuIds ?? this.checkedInStockSkuIds,
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

  /// Fired after a consent record is changed. Consent controls access to the
  /// customer cart and saved consultation results, so dependent Last Intent
  /// session state must be discarded when the CA records agree/disagree.
  VoidCallback? onConsentChanged;

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
      final Customer updatedCustomer = customer.copyWith(
        hasConsented: consent.hasAgreed,
      );
      _state = _state.copyWith(
        customer: updatedCustomer,
        lookupState: AsyncValue<Customer>.data(updatedCustomer),
        consentState: AsyncValue<CustomerConsent>.data(consent),
        cartItems: const <CartItem>[],
        cartState: const AsyncValue<List<CartItem>>.idle(),
      );
      onConsentChanged?.call();
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        consentState: AsyncValue<CustomerConsent>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> loadCart() async {
    final Customer? customer = _state.customer;
    if (customer == null || _state.cartState.isLoading) {
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
      final List<CartItem> sortedItems = cartItems.toList()
        ..sort((CartItem a, CartItem b) => b.savedAt.compareTo(a.savedAt));
      _state = _state.copyWith(
        cartItems: sortedItems,
        cartState: AsyncValue<List<CartItem>>.data(sortedItems),
      );
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        cartState: AsyncValue<List<CartItem>>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  /// Marks an in-stock cart item's SKU as confirmed by the CA (98:1933's
  /// "해당 제품 상담 완료" button) — the row on [CartInventoryScreen] reflects
  /// this immediately since both screens share this controller.
  void markProductChecked(int skuId) {
    _state = _state.copyWith(
      checkedInStockSkuIds: <int>{..._state.checkedInStockSkuIds, skuId},
    );
    notifyListeners();
  }
}
