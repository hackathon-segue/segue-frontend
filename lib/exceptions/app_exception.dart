class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() {
    final String prefix = code == null ? 'AppException' : 'AppException($code)';
    return '$prefix: $message';
  }
}

class ApiException extends AppException {
  const ApiException(
    super.message, {
    required this.statusCode,
    super.code,
    this.details,
  });

  final int statusCode;
  final Object? details;

  bool get isConsentRequired => statusCode == 403 || code == 'CONSENT_REQUIRED';
}

class ApiError {
  const ApiError({required this.message, this.code});

  factory ApiError.fromJson(Map<String, Object?> json) {
    return ApiError(
      message: json['message']?.toString() ?? '요청을 처리하지 못했습니다.',
      code: json['code']?.toString(),
    );
  }

  final String message;
  final String? code;
}
