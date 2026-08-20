import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/app_config.dart';
import '../utils/local_storage.dart';
import 'async_value.dart';

class StaffWebSessionState {
  const StaffWebSessionState({
    this.storeId = AppConfig.defaultStoreId,
    this.currentCustomer,
    this.cartItems = const <CartItem>[],
    this.lookupState = const AsyncValue<Customer>.idle(),
    this.consentState = const AsyncValue<CustomerConsent>.idle(),
    this.cartState = const AsyncValue<List<CartItem>>.idle(),
    this.checkedInStockSkuIds = const <int>{},
  });

  final int storeId;

  /// The customer whose cart/consent is currently in view (Cart/Consent
  /// screens read this) — persists across refresh and navigation, only
  /// replaced once a *different* customer is successfully looked up.
  /// Deliberately separate from [lookupState]'s result (Issue: "Customer
  /// Lookup의 이전 고객 잔상 제거") — re-entering the Customer Lookup screen
  /// resets [lookupState] back to idle so it shows a blank search state,
  /// without touching this field or the customer's cart/consent context.
  final Customer? currentCustomer;
  final List<CartItem> cartItems;

  /// The Customer Lookup screen's own "방금 검색한 결과" — reset to `.idle()`
  /// every time that screen is (re-)entered
  /// ([StaffWebSessionController.clearLookupResult]), independent of
  /// [currentCustomer].
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
    Customer? currentCustomer,
    List<CartItem>? cartItems,
    AsyncValue<Customer>? lookupState,
    AsyncValue<CustomerConsent>? consentState,
    AsyncValue<List<CartItem>>? cartState,
    Set<int>? checkedInStockSkuIds,
  }) {
    return StaffWebSessionState(
      storeId: storeId ?? this.storeId,
      currentCustomer: currentCustomer ?? this.currentCustomer,
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
    : _repository = repository {
    _restoreCurrentCustomer();
  }

  final SegueRepository _repository;

  static const String _currentCustomerStorageKey = 'segue.currentCustomer';

  StaffWebSessionState _state = const StaffWebSessionState();

  StaffWebSessionState get state => _state;

  /// Fired after a consent record is changed, with that customer's id.
  /// Consent controls access to the customer cart and saved consultation
  /// results, so that SPECIFIC customer's Last Intent sessions must be
  /// discarded when the CA records agree/disagree — wired to
  /// [LastIntentSessionManager.resetForCustomer], never a blanket reset,
  /// since other customers' in-progress sessions are unrelated.
  ValueChanged<int>? onConsentChanged;

  void setStoreId(int storeId) {
    _state = _state.copyWith(storeId: storeId);
    notifyListeners();
  }

  /// Clears the looked-up/current customer and cart/consent state entirely,
  /// keeping only the current store context — including the persisted
  /// currentCustomer, since this means the CA is deliberately abandoning
  /// this customer (e.g. "고객 조회로 돌아가기" after a declined consent).
  void reset() {
    LocalStorage.removeItem(_currentCustomerStorageKey);
    _state = StaffWebSessionState(storeId: _state.storeId);
    notifyListeners();
  }

  /// Resets only the Customer Lookup screen's own "방금 검색한 결과" —
  /// called when that screen is (re-)entered so it never shows a stale
  /// customer card left over from a previous visit. Never touches
  /// [StaffWebSessionState.currentCustomer]/cart/consent — Home and other
  /// screens keep whatever customer/consultation was already in progress.
  void clearLookupResult() {
    if (_state.lookupState.isIdle) {
      return;
    }
    _state = _state.copyWith(lookupState: const AsyncValue<Customer>.idle());
    notifyListeners();
  }

  /// Switches [StaffWebSessionState.currentCustomer] to [customer] and
  /// re-fetches THEIR cart — used by Home's "진행 중인 상담" cards' "쇼핑백
  /// 확인" button, which already knows exactly which customer's card was
  /// tapped (unlike a plain navigate-to-cart, which would just show
  /// whichever customer happened to be [currentCustomer] already — e.g. a
  /// different, unrelated one the CA looked up more recently, or one whose
  /// consultation already completed). A no-op if [customer] is already
  /// current, so it never redundantly re-fetches the same cart.
  void switchToCustomer(Customer customer) {
    if (_state.currentCustomer?.id == customer.id) {
      return;
    }
    _state = StaffWebSessionState(
      storeId: _state.storeId,
      currentCustomer: customer,
    );
    _persistCurrentCustomer(customer);
    notifyListeners();
    if (customer.hasConsented) {
      loadCart();
    }
  }

  Future<void> lookupCustomer(String phoneNumber) async {
    _state = _state.copyWith(lookupState: const AsyncValue<Customer>.loading());
    notifyListeners();

    try {
      final Customer customer = await _repository.lookupCustomerByPhone(
        phoneNumber,
      );
      // Only replace the active customer/cart/consent context once a NEW
      // lookup actually succeeds — never while it's merely loading, and
      // never on failure, so the previous customer's context (if any)
      // stays intact until a different one is genuinely found. No
      // LastIntentSessionManager reset here anymore — sessions are keyed
      // per customer now, so looking up someone else never risks
      // corrupting or losing anyone else's in-progress consultation.
      _state = StaffWebSessionState(
        storeId: _state.storeId,
        currentCustomer: customer,
        lookupState: AsyncValue<Customer>.data(customer),
      );
      _persistCurrentCustomer(customer);
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        lookupState: AsyncValue<Customer>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> submitConsent(bool agreed) async {
    final Customer? customer = _state.currentCustomer;
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
        currentCustomer: updatedCustomer,
        lookupState: AsyncValue<Customer>.data(updatedCustomer),
        consentState: AsyncValue<CustomerConsent>.data(consent),
        cartItems: const <CartItem>[],
        cartState: const AsyncValue<List<CartItem>>.idle(),
      );
      _persistCurrentCustomer(updatedCustomer);
      onConsentChanged?.call(updatedCustomer.id);
    } catch (error, stackTrace) {
      _state = _state.copyWith(
        consentState: AsyncValue<CustomerConsent>.error(error, stackTrace),
      );
    }
    notifyListeners();
  }

  Future<void> loadCart() async {
    final Customer? customer = _state.currentCustomer;
    if (customer == null || _state.cartState.isLoading) {
      return;
    }
    if (!customer.hasConsented) {
      _state = _state.copyWith(
        cartItems: const <CartItem>[],
        cartState: const AsyncValue<List<CartItem>>.idle(),
      );
      notifyListeners();
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

  /// Restores [StaffWebSessionState.currentCustomer] from a previous visit
  /// (browser refresh) and kicks off the existing [loadCart] to re-fetch
  /// that same customer's cart from the real API — never replays a copy of
  /// the cart items themselves from localStorage, only the customer id
  /// needed to ask for them again.
  ///
  /// The full [Customer] (not just its id) is persisted because API.md has
  /// no "look up customer by id" endpoint — only by phone number — so an
  /// id-only record could not be turned back into a usable [Customer] here.
  void _restoreCurrentCustomer() {
    final String? raw = LocalStorage.getItem(_currentCustomerStorageKey);
    if (raw == null) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final Customer restored = Customer.fromJson(asJsonMap(decoded));
      _state = _state.copyWith(currentCustomer: restored);
      if (restored.hasConsented) {
        loadCart();
      }
    } catch (_) {
      LocalStorage.removeItem(_currentCustomerStorageKey);
    }
  }

  void _persistCurrentCustomer(Customer customer) {
    LocalStorage.setItem(
      _currentCustomerStorageKey,
      jsonEncode(customer.toJson()),
    );
  }
}
