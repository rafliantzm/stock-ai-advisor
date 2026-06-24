Map<String, dynamic> asStringMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is List) {
    return value.map(asStringMap).toList();
  }
  return <Map<String, dynamic>>[];
}
