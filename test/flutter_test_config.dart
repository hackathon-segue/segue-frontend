import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/utils/local_storage.dart';

/// Flutter's special per-directory test config — wraps every test/testWidgets
/// in this package automatically.
///
/// `LocalStorage`'s non-web fallback is a plain in-memory map (module-level
/// state), so without this it would leak a session persisted by one test
/// into the next `SegueApp` constructed later in the SAME test file/isolate
/// — e.g. an active consultation from an earlier test showing up
/// unexpectedly on a fresh Home screen in a later one.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(LocalStorage.clear);
  await testMain();
}
