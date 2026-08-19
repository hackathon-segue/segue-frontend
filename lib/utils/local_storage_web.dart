import 'dart:html' as html;

String? getItem(String key) => html.window.localStorage[key];

void setItem(String key, String value) {
  html.window.localStorage[key] = value;
}

void removeItem(String key) {
  html.window.localStorage.remove(key);
}

void clear() {
  html.window.localStorage.clear();
}
