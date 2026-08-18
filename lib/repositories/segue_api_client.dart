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
  }) : _httpClient = httpClient ?? http.Client(),
       _baseUri = Uri.parse(baseUrl);

  final http.Client _httpClient;
  final Uri _baseUri;

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, Object?> queryParameters = const <String, Object?>{},
  }) async {
    final http.Response response = await _httpClient.get(
      _uri(path, queryParameters),
      headers: _headers,
    );
    return _decode(response);
  }

  @override
  Future<Object?> postJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  }) async {
    final http.Response response = await _httpClient.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  @override
  Future<Object?> patchJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  }) async {
    final http.Response response = await _httpClient.patch(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
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
