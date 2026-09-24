/// Strict readers for values received from the API.
///
/// The backend contract deliberately uses integer paise and UTC timestamps.
/// Keeping the validation here prevents loosely typed JSON from leaking into
/// domain models.
String readRequiredString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  throw FormatException('Expected a non-empty string for "$key".');
}

String? readNullableString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }

  throw FormatException('Expected a string or null for "$key".');
}

int readRequiredInt(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is int) {
    return value;
  }

  throw FormatException('Expected an integer for "$key".');
}

Map<String, Object?> readRequiredMap(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is Map<String, Object?>) {
    return value;
  }

  throw FormatException('Expected an object for "$key".');
}

List<Object?> readRequiredList(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is List<Object?>) {
    return value;
  }

  throw FormatException('Expected an array for "$key".');
}

/// Parses the API's ISO-8601 UTC timestamp and converts it exactly once for
/// display by the app.
DateTime readUtcDateTimeAsLocal(Map<String, Object?> json, String key) {
  final String value = readRequiredString(json, key);
  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('Expected an ISO-8601 UTC timestamp for "$key".');
  }

  return parsed.toLocal();
}
