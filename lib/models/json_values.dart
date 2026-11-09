int readInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String readString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

bool readBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return fallback;
}

List<int> readIntList(Object? value) {
  if (value is! List) return <int>[];
  final result = <int>[];
  for (final item in value) {
    final id = readInt(item, -1);
    if (id > 0) result.add(id);
  }
  return result;
}

DateTime? readDate(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}

Map<String, dynamic>? readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<T> readModels<T>(Object? raw, T Function(Map<String, dynamic> json) decode) {
  if (raw is! List) return <T>[];
  final result = <T>[];
  for (final item in raw) {
    final map = readMap(item);
    if (map == null) continue;
    final decoded = decode(map);
    result.add(decoded);
  }
  return result;
}
