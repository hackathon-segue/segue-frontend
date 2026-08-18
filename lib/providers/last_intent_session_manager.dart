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
  LastIntentSessionManager({required SegueRepository repository})
    : _repository = repository;

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
    final LastIntentSessionController? existing =
        _sessionsBySkuId[cartItem.skuId];
    if (existing != null) {
      return existing;
    }
    final LastIntentSessionController created = LastIntentSessionController(
      repository: _repository,
    );
    created.start(customer: customer, cartItem: cartItem);
    // Widgets outside the session's own scope (e.g. the cart row's
    // request-accepted badge, driven by isCompleted() below) listen to this
    // manager, not to each individual session — without forwarding,
    // execute() flipping executionResponse never reaches them.
    created.addListener(notifyListeners);
    _sessionsBySkuId[cartItem.skuId] = created;
    notifyListeners();
    return created;
  }

  bool isStarted(int skuId) => _sessionsBySkuId.containsKey(skuId);

  /// Number of sessions started but not yet completed — drives the
  /// "CURRENT SESSION" sidebar badge (Figma 89:1196/159:2173 etc.).
  int get activeCount => _sessionsBySkuId.values.where((LastIntentSessionController c) {
    return c.state.executionResponse == null;
  }).length;

  /// The first started-but-not-completed session's state — drives the
  /// "진행 중인 상담" card on the Home screen (Figma 80:776). Null when
  /// [activeCount] is 0, matching that screen's empty-state variant
  /// (89:1196).
  LastIntentSessionState? get firstActiveSession {
    for (final LastIntentSessionController controller in _sessionsBySkuId.values) {
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
  bool isCompleted(int skuId) =>
      _sessionsBySkuId[skuId]?.state.executionResponse != null;

  /// Issue #64: whether [skuId]'s session ended via "추가 상담 미진행"
  /// (169:3821) rather than a normal completion — [isCompleted] is already
  /// true either way (both call `execute()`), this only picks the cart
  /// row's badge text/color (Figma 98:1740's "상담 중단" vs "상담 완료").
  bool isDeclined(int skuId) =>
      _sessionsBySkuId[skuId]?.state.additionalConsultationDeclined ?? false;

  /// Clears every SKU's session for the current customer. Wired to
  /// [StaffWebSessionController]'s new-lookup hook so a different
  /// customer's cart never inherits a previous customer's in-progress
  /// Last Intent sessions (Issue #7's per-customer reset rule).
  void reset() {
    if (_sessionsBySkuId.isEmpty) {
      return;
    }
    for (final LastIntentSessionController controller
        in _sessionsBySkuId.values) {
      controller.dispose();
    }
    _sessionsBySkuId.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final LastIntentSessionController controller
        in _sessionsBySkuId.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
