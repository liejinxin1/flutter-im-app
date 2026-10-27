import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/errors/app_failure.dart';
import '../../domain/services/api_client.dart';

/// Thin, testable HTTP adapter for application REST APIs.
///
/// The Agora Chat SDK owns chat transport; this class owns only HTTP concerns:
/// base URL, JSON, auth header, timeout, status mapping, and teardown.
class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    this.accessToken,
  }) : _client = client ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final Future<String?> Function()? accessToken;
  final http.Client _client;

  @override
  Future<ApiResponse> send(ApiRequest request) async {
    final uri = _uri(request.path, request.query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (request.body != null) 'Content-Type': 'application/json',
      ...request.headers,
    };

    final token = await accessToken?.call();
    if (token != null && token.isNotEmpty) {
      headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }

    final httpRequest = http.Request(request.method.name.toUpperCase(), uri)
      ..headers.addAll(headers);
    if (request.body != null) {
      httpRequest.body = jsonEncode(request.body);
    }

    try {
      final streamed = await _client.send(httpRequest).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiFailure(
          response.statusCode,
          'HTTP ${response.statusCode}',
          body: response.body,
        );
      }
      return ApiResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
      );
    } on TimeoutException {
      throw const NetworkFailure('Request timed out.');
    } on http.ClientException catch (error) {
      throw NetworkFailure(error.message);
    }
  }

  Uri _uri(String path, Map<String, String> query) {
    final base = baseUrl.toString().endsWith('/')
        ? baseUrl
        : Uri.parse('${baseUrl.toString()}/');
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return base
        .resolve(relative)
        .replace(queryParameters: query.isEmpty ? null : query);
  }

  @override
  Future<void> close() async => _client.close();
}
