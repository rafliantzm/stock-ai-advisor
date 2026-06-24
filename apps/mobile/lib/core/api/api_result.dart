class ApiException implements Exception {
  ApiException(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => '$code: $message';
}

class ApiResult {
  ApiResult({required this.data, required this.meta});

  final Map<String, dynamic> data;
  final Map<String, dynamic> meta;
}
