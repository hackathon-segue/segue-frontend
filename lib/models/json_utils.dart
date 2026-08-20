typedef JsonMap = Map<String, Object?>;

JsonMap asJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (Object? key, Object? item) => MapEntry(key.toString(), item),
    );
  }
  return <String, Object?>{};
}

List<Object?> asJsonList(Object? value) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return value.cast<Object?>();
  }
  return <Object?>[];
}

String stringValue(JsonMap json, String key, {String defaultValue = ''}) {
  final Object? value = json[key];
  if (value == null) {
    return defaultValue;
  }
  return value.toString();
}

int intValue(JsonMap json, String key, {int defaultValue = 0}) {
  final Object? value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? defaultValue;
}

bool boolValue(JsonMap json, String key, {bool defaultValue = false}) {
  final Object? value = json[key];
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return defaultValue;
}

DateTime? dateTimeValue(JsonMap json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

Map<String, String> stringMapValue(JsonMap json, String key) {
  final Object? value = json[key];
  if (value is! Map) {
    return <String, String>{};
  }
  return value.map(
    (Object? mapKey, Object? mapValue) =>
        MapEntry(mapKey.toString(), mapValue?.toString() ?? ''),
  );
}

List<String> stringListValue(JsonMap json, String key) {
  return asJsonList(
    json[key],
  ).map((Object? value) => value.toString()).toList();
}
