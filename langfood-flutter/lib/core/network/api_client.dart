import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiClient {
  static final http.Client _client = http.Client();

  static Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    String base = AppConstants.baseUrl.replaceAll(' ', '').trim();
    if (!base.endsWith('/')) base = '$base/';
    String path = endpoint.trim();
    if (path.startsWith('/')) path = path.substring(1);

    Uri baseUri = Uri.parse('$base$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return baseUri.replace(queryParameters: stringParams);
    }
    return baseUri;
  }

  static Exception _handleException(dynamic error, Uri uri) {
    if (error is TimeoutException) {
      return Exception(
        'Không thể kết nối tới máy chủ (${uri.host}:${uri.port}).\n'
        'Quá thời gian chờ (15s). Vui lòng kiểm tra Backend đã bật chưa hoặc điện thoại và PC có cùng lớp mạng Wi-Fi không.',
      );
    }
    if (error is SocketException) {
      return Exception(
        'Không thể kết nối tới ${uri.host}:${uri.port}.\n'
        'Vui lòng kiểm tra địa chỉ IP trong AppConstants hoặc Wi-Fi.',
      );
    }
    if (error is Exception) {
      return error;
    }
    return Exception('Lỗi kết nối: $error');
  }

  static Map<String, String> _buildHeaders([String? token]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Resolve Image URL: Prepend base URL if relative path
  static String resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return AppConstants.defaultFoodImage;
    }
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    String base = AppConstants.baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    String path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  static Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    String? token,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    developer.log('GET -> $uri', name: 'ApiClient');
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 15));
      developer.log('RESPONSE [${response.statusCode}] <- $uri', name: 'ApiClient');
      return response;
    } catch (e) {
      developer.log('ERROR on GET $uri: $e', name: 'ApiClient');
      throw _handleException(e, uri);
    }
  }

  static Future<http.Response> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    String? token,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    developer.log('POST -> $uri, Body: $body', name: 'ApiClient');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(token),
            body: body is String ? body : (body != null ? jsonEncode(body) : null),
          )
          .timeout(const Duration(seconds: 15));
      developer.log('RESPONSE [${response.statusCode}] <- $uri', name: 'ApiClient');
      return response;
    } catch (e) {
      developer.log('ERROR on POST $uri: $e', name: 'ApiClient');
      throw _handleException(e, uri);
    }
  }

  static Future<http.Response> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    String? token,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    developer.log('PUT -> $uri, Body: $body', name: 'ApiClient');
    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(token),
            body: body is String ? body : (body != null ? jsonEncode(body) : null),
          )
          .timeout(const Duration(seconds: 15));
      developer.log('RESPONSE [${response.statusCode}] <- $uri', name: 'ApiClient');
      return response;
    } catch (e) {
      developer.log('ERROR on PUT $uri: $e', name: 'ApiClient');
      throw _handleException(e, uri);
    }
  }

  static Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    String? token,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    developer.log('DELETE -> $uri', name: 'ApiClient');
    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 15));
      developer.log('RESPONSE [${response.statusCode}] <- $uri', name: 'ApiClient');
      return response;
    } catch (e) {
      developer.log('ERROR on DELETE $uri: $e', name: 'ApiClient');
      throw _handleException(e, uri);
    }
  }
}
