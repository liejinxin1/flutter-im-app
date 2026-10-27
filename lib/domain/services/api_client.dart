import 'dart:convert';

enum ApiMethod { get, post, put, delete, patch }

class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.headers = const {},
    this.body,
  });

  final ApiMethod method;
  final String path;
  final Map<String, String> query;
  final Map<String, String> headers;
  final Object? body;
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;

  Object? get json {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}

/// HTTP boundary for future REST endpoints.
///
/// Agora Chat traffic deliberately stays inside the SDK adapter; this client is
/// for application APIs (auth, profile, RTC tokens, uploads, ...). ViewModels
/// must depend on this interface, never on `package:http` directly.
abstract interface class ApiClient {
  Future<ApiResponse> send(ApiRequest request);

  Future<void> close();
}
