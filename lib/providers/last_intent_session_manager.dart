import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/local_storage.dart';
import 'last_intent_session.dart';

/// Issue #9: the cart can have several out-of-stock SKUs at once, and each
/// needs its own independent Last Intent session — starting SKU B's session
/// must not overwrite or bleed into SKU A's in-progress state.
///
/// Sessions are keyed by (customerId, skuId), not skuId alone — the catalog
/// is shared across customers, so two different customers can each have a
/// cart item with the same skuId; keying by skuId alone would make the
/// second customer's `sessionFor` silently return the FIRST customer's
/// session. This also means looking up a different customer no longer needs
/// to wipe every other customer's in-progress sessions to stay safe — they
/// coexist, and only the specific customer whose consent just changed gets
/// cleared ([resetForCustomer]).
///
/// Every started-but-not-yet-completed session is also mirrored into
/// `localStorage` (see [_persistActiveConsultations]/
/// [_restoreActiveConsultations]) so "진행 중 상담" survives a browser
/// refresh or navigating to Home/Consultation History/etc. — it's only ever
/// dropped once that SKU's session actually completes (`executionResponse`
/// set) or [resetForCustomer] is called for that session's own customer.
class LastIntentSessionManager extends ChangeNotifier {
  LastIntentSessionManager({required SegueRepository repository})
    : _repository = repository {
    _restoreActiveConsultations();
  }

  final SegueRepository _repository;
  final Map<String, LastIntentSessionController> _sessionsByKey =
      <String, LastIntentSessionController>{};

  static const String _storageKey = 'segue.activeConsultations';

  static String _key(int customerId, int skuId) => '$customerId:$skuId';

  /// Returns the session for [customer]'s [cartItem], creating and starting
  /// one on first access. Re-visiting the same (customer, SKU) pair returns
  /// the SAME controller instance with whatever progress was already made;
  /// a different customer or a different SKU never touches this one.
  LastIntentSessionController sessionFor({
    required Customer customer,
    required CartItem cartItem,
  }) {
    final String key = _key(customer.id, cartItem.skuId);
    final LastIntentSessionController? existing = _sessionsByKey[key];
    if (existing != null) {
      return existing;
    }
    final LastIntentSessionController created = LastIntentSessionController(
      repository: _repository,
    );
    _attach(created, key);
    created.start(customer: customer, cartItem: cartItem);
    notifyListeners();
    return created;
  }

  /// Wires up the persistence + manager-notify listeners a session needs
  /// regardless of whether it was just started fresh ([sessionFor]) or
  /// rehydrated from localStorage ([_restoreActiveConsultations]).
  void _attach(LastIntentSessionController controller, String key) {
    // Widgets outside the session's own scope (e.g. the cart row's
    // request-accepted badge, driven by isCompleted() below) listen to this
    // manager, not to each individual session — without forwarding,
    // execute() flipping executionResponse never reaches them.
    controller.addListener(notifyListeners);
    controller.addListener(_persistActiveConsultations);
    _sessionsByKey[key] = controller;
  }

  bool isStarted(int customerId, int skuId) =>
      _sessionsByKey.containsKey(_key(customerId, skuId));

  /// Number of sessions (across every customer) started but not yet
  /// completed — drives the "CURRENT SESSION" sidebar badge (Figma
  /// 89:1196/159:2173 etc.).
  int get activeCount =>
      _sessionsByKey.values.where((LastIntentSessionController c) {
        return c.state.executionResponse == null;
      }).length;

  /// Every started-but-not-completed session's state (across every
  /// customer) — Home renders one "진행 중인 상담" card per entry (Figma
  /// 80:776 only ever shows a single example card, but there's no reason
  /// to hide a second customer's still-in-progress consultation just
  /// because Figma's mock only shows one). Empty when [activeCount] is 0,
  /// matching Home's empty-state variant (89:1196).
  List<LastIntentSessionState> get activeSessions => _sessionsByKey.values
      .where(
        (LastIntentSessionController c) => c.state.executionResponse == null,
      )
      .map((LastIntentSessionController c) => c.state)
      .toList();

  /// The first started-but-not-completed session's state (across every
  /// customer). Null when [activeCount] is 0.
  LastIntentSessionState? get firstActiveSession {
    for (final LastIntentSessionController controller
        in _sessionsByKey.values) {
      if (controller.state.executionResponse == null) {
        return controller.state;
      }
    }
    return null;
  }

  /// A session counts as complete once its execute step has a response —
  /// reusing the signal [LastIntentSessionController] already exposes
  /// rather than keeping a second "completed" flag that could drift out of
  /// sync with it.
  bool isCompleted(int customerId, int skuId) =>
      _sessionsByKey[_key(customerId, skuId)]?.state.executionResponse != null;

  /// Issue #64: whether this (customer, SKU) session ended via "추가 상담
  /// 미진행" (169:3821) rather than a normal completion — [isCompleted] is
  /// already true either way (both call `execute()`), this only picks the
  /// cart row's badge text/color (Figma 98:1740's "상담 중단" vs "상담 완료").
  bool isDeclined(int customerId, int skuId) =>
      _sessionsByKey[_key(customerId, skuId)]
          ?.state
          .additionalConsultationDeclined ??
      false;

  /// Clears every session belonging to [customerId] — used when that
  /// specific customer's consent changes (agree or disagree), since a
  /// revoked consent makes their cart/sessions unreachable anyway. Never
  /// touches other customers' sessions (see the class doc for why sessions
  /// no longer get wiped just because the CA looks up someone new).
  void resetForCustomer(int customerId) {
    final List<String> keysToRemove = _sessionsByKey.entries
        .where(
          (MapEntry<String, LastIntentSessionController> entry) =>
              entry.value.state.customer?.id == customerId,
        )
        .map((MapEntry<String, LastIntentSessionController> entry) => entry.key)
        .toList();
    if (keysToRemove.isEmpty) {
      return;
    }
    for (final String key in keysToRemove) {
      _sessionsByKey.remove(key)?.dispose();
    }
    _persistActiveConsultations();
    notifyListeners();
  }

  /// Rebuilds every still-in-progress session's controller from whatever
  /// was saved by [_persistActiveConsultations] on a previous visit —
  /// called once, synchronously, from the constructor, so
  /// [firstActiveSession]/[activeCount] are already correct the moment Home
  /// first builds after a refresh (no loading flicker).
  void _restoreActiveConsultations() {
    final String? raw = LocalStorage.getItem(_storageKey);
    if (raw == null) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      for (final Object? entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final LastIntentSessionState? restoredState =
            LastIntentSessionState.fromPersistedJson(asJsonMap(entry));
        final CartItem? cartItem = restoredState?.selectedCartItem;
        final Customer? customer = restoredState?.customer;
        if (restoredState == null || cartItem == null || customer == null) {
          continue;
        }
        final LastIntentSessionController controller =
            LastIntentSessionController(repository: _repository);
        _attach(controller, _key(customer.id, cartItem.skuId));
        // restore (not start) — takes the reconstructed state as-is
        // instead of resetting progress.
        controller.restore(restoredState);
      }
    } catch (_) {
      // A malformed/outdated persisted payload shouldn't ever crash the
      // app on startup — treat it the same as "nothing to restore".
      LocalStorage.removeItem(_storageKey);
    }
  }

  /// Mirrors every still-in-progress session into localStorage — called
  /// after every session state change (via each controller's own listener,
  /// wired in [_attach]) so it always reflects the latest utterance/
  /// structuredIntent/decisionResult/currentStep, and a completed session
  /// (executionResponse set) drops out on its very next notification.
  void _persistActiveConsultations() {
    final List<JsonMap> entries = _sessionsByKey.values
        .where(
          (LastIntentSessionController c) =>
              c.state.executionResponse == null && c.state.isPersistable,
        )
        .map((LastIntentSessionController c) => c.state.toPersistedJson())
        .toList();
    if (entries.isEmpty) {
      LocalStorage.removeItem(_storageKey);
    } else {
      LocalStorage.setItem(_storageKey, jsonEncode(entries));
    }
  }

  @override
  void dispose() {
    for (final LastIntentSessionController controller
        in _sessionsByKey.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
