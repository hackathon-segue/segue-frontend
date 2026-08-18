import 'package:flutter/widgets.dart';

import 'staff_web_session.dart';

/// Shares a single [StaffWebSessionController] instance across the staff/
/// tablet route stack (login → home → customer lookup → consent), mirroring
/// the [RepositoryScope] pattern already used for [SegueRepository].
class StaffSessionScope extends InheritedNotifier<StaffWebSessionController> {
  const StaffSessionScope({
    required StaffWebSessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static StaffWebSessionController of(BuildContext context) {
    final StaffSessionScope? scope = context
        .dependOnInheritedWidgetOfExactType<StaffSessionScope>();
    assert(scope != null, 'StaffSessionScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
