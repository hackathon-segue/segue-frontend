// Non-web fallback (VM/flutter test) — in-memory only, so it never persists
// across process restarts, but that's fine: this app only ships to web, and
// tests exercising persistence logic just need consistent read/write
// behavior within a single test run, not real durability.
//
// This map is top-level (module) state, so it survives across every
// testWidgets() in the same test file/isolate unless explicitly cleared —
// test/flutter_test_config.dart calls clear() before every test for exactly
// this reason (otherwise one test's persisted session would leak into the
// next test's fresh SegueApp).
final Map<String, String> _memoryStore = <String, String>{};

String? getItem(String key) => _memoryStore[key];

void setItem(String key, String value) {
  _memoryStore[key] = value;
}

void removeItem(String key) {
  _memoryStore.remove(key);
}

void clear() {
  _memoryStore.clear();
}
