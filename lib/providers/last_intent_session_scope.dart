import 'package:flutter/widgets.dart';

import 'last_intent_session_manager.dart';

/// Shares a single [LastIntentSessionManager] instance across the
/// staff/tablet route stack, mirroring [StaffSessionScope]. Issue #9
/// upgrades this from wrapping one global [LastIntentSessionController] to
/// wrapping the manager, so each SKU the CA starts Last Intent for gets its
/// own independent, non-overwriting session.
class LastIntentSessionScope extends InheritedNotifier<LastIntentSessionManager> {
  const LastIntentSessionScope({
    required LastIntentSessionManager manager,
    required super.child,
    super.key,
  }) : super(notifier: manager);

  static LastIntentSessionManager of(BuildContext context) {
    final LastIntentSessionScope? scope = context
        .dependOnInheritedWidgetOfExactType<LastIntentSessionScope>();
    assert(scope != null, 'LastIntentSessionScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
