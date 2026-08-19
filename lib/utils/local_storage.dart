import 'local_storage_stub.dart' if (dart.library.html) 'local_storage_web.dart' as impl;

/// Thin synchronous key-value wrapper over the browser's `localStorage` on
/// Flutter Web (conditional-imported `dart:html`), falling back to an
/// in-memory map on any other platform (VM/`flutter test`) so the same
/// calling code works in both without checking `kIsWeb` everywhere.
///
/// Synchronous on purpose (unlike e.g. the `shared_preferences` package) —
/// callers need to hydrate provider state before the first frame builds,
/// which an async API would force into a loading-screen dance this app
/// doesn't otherwise need.
abstract final class LocalStorage {
  static String? getItem(String key) => impl.getItem(key);

  static void setItem(String key, String value) => impl.setItem(key, value);

  static void removeItem(String key) => impl.removeItem(key);

  static void clear() => impl.clear();
}
