import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'last_intent_session.dart';

/// Issue #9: the cart can have several out-of-stock SKUs at once, and each
/// needs its own independent Last Intent session — starting SKU B's session
/// must not overwrite or bleed into SKU A's in-progress state.
///
/// Deliberately does not change [LastIntentSessionController] /
/// [LastIntentSessionState] at all (Issue #7/#8 already built and rely on
/// them) — this just keeps one controller instance per skuId instead of
/// the single global instance Issue #8 wired up.
class LastIntentSessionManager extends ChangeNotifier {
  LastIntentSessionManager({required SegueRepository repository}) : _repository = repository;

  final SegueRepository _repository;
  final Map<int, LastIntentSessionController> _sessionsBySkuId =
      <int, LastIntentSessionController>{};

  /// Returns the session for [cartItem]'s SKU, creating and starting one on
  /// first access. Re-visiting the same SKU returns the SAME controller
  /// instance with whatever progress was already made; visiting a
  /// different SKU never touches this one.
  LastIntentSessionController sessionFor({
    required Customer customer,
    required CartItem cartItem,
  }) {
    final LastIntentSessionController? existing = _sessionsBySkuId[cartItem.skuId];
    if (existing != null) {
      return existing;
    }
    final LastIntentSessionController created =
        LastIntentSessionController(repository: _repository)
          ..start(customer: customer, cartItem: cartItem);
    _sessionsBySkuId[cartItem.skuId] = created;
    notifyListeners();
    return created;
  }

  bool isStarted(int skuId) => _sessionsBySkuId.containsKey(skuId);

  /// A session counts as complete once its execute step has a response —
  /// reusing the signal [LastIntentSessionController] already exposes
  /// rather than keeping a second "completed" flag that could drift out of
  /// sync with it.
  bool isCompleted(int skuId) => _sessionsBySkuId[skuId]?.state.executionResponse != null;

  /// Clears every SKU's session for the current customer. Wired to
  /// [StaffWebSessionController]'s new-lookup hook so a different
  /// customer's cart never inherits a previous customer's in-progress
  /// Last Intent sessions (Issue #7's per-customer reset rule).
  void reset() {
    if (_sessionsBySkuId.isEmpty) {
      return;
    }
    for (final LastIntentSessionController controller in _sessionsBySkuId.values) {
      controller.dispose();
    }
    _sessionsBySkuId.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final LastIntentSessionController controller in _sessionsBySkuId.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
