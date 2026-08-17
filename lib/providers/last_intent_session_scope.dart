import 'package:flutter/widgets.dart';

import 'last_intent_session.dart';

/// Shares a single [LastIntentSessionController] instance across the
/// staff/tablet route stack, mirroring [StaffSessionScope]. Issue #8 wires
/// "Last Intent 시작" to call `.start(customer, cartItem)` here so the
/// selected cart item/SKU context is available to whichever future screen
/// continues the Last Intent flow (F3 intent input — out of Issue #8's
/// scope).
class LastIntentSessionScope extends InheritedNotifier<LastIntentSessionController> {
  const LastIntentSessionScope({
    required LastIntentSessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static LastIntentSessionController of(BuildContext context) {
    final LastIntentSessionScope? scope = context
        .dependOnInheritedWidgetOfExactType<LastIntentSessionScope>();
    assert(scope != null, 'LastIntentSessionScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
