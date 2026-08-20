import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../utils/app_config.dart';

abstract interface class SegueApiClient {
  Future<Object?> getJson(
    String path, {
    Map<String, Object?> queryParameters = const <String, Object?>{},
  });

  Future<Object?> postJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  });

  Future<Object?> patchJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  });
}

class HttpSegueApiClient implements SegueApiClient {
  HttpSegueApiClient({
    http.Client? httpClient,
    String baseUrl = AppConfig.apiBaseUrl,
    Duration timeout = const Duration(seconds: AppConfig.apiTimeoutSeconds),
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUri = Uri.parse(baseUrl),
       _timeout = timeout;

  final http.Client _httpClient;
  final Uri _baseUri;
  final Duration _timeout;

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, Object?> queryParameters = const <String, Object?>{},
  }) async {
    return _send(
      _httpClient.get(_uri(path, queryParameters), headers: _headers),
    );
  }

  @override
  Future<Object?> postJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  }) async {
    return _send(
      _httpClient.post(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  @override
  Future<Object?> patchJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  }) async {
    return _send(
      _httpClient.patch(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    ...AppConfig.ngrokSkipWarningHeader,
  };

  Uri _uri(
    String path, [
    Map<String, Object?> queryParameters = const <String, Object?>{},
  ]) {
    final String basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    final String normalizedPath = path.startsWith('/')
        ? path.substring(1)
        : path;
    final Map<String, String> query = queryParameters.map(
      (String key, Object? value) => MapEntry(key, value?.toString() ?? ''),
    )..removeWhere((String _, String value) => value.isEmpty);

    return _baseUri.replace(
      path: '$basePath$normalizedPath',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<Object?> _send(Future<http.Response> request) async {
    try {
      final http.Response response = await request.timeout(_timeout);
      return _decode(response);
    } on TimeoutException catch (error) {
      throw ApiException(
        '서버 응답 시간이 초과되었습니다. 네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
        statusCode: 0,
        code: 'REQUEST_TIMEOUT',
        details: error.message,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        '서버에 연결할 수 없습니다. API_BASE_URL과 네트워크 상태를 확인해 주세요.',
        statusCode: 0,
        code: 'NETWORK_ERROR',
        details: error.message,
      );
    }
  }

  Object? _decode(http.Response response) {
    final Object? body = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final JsonMap errorBody = asJsonMap(body);
    final ApiError error = ApiError.fromJson(errorBody);
    throw ApiException(
      error.message,
      statusCode: response.statusCode,
      code: error.code,
      details: body,
    );
  }
}
