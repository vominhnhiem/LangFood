import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/config_url.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static http.Client _client = http.Client();

  @visibleForTesting
  static void useClient(http.Client client) {
    _client.close();
    _client = client;
  }

  static dynamic decodeResponse(http.Response response) {
    dynamic data;
    final bodyString = utf8.decode(response.bodyBytes);
    try {
      data = jsonDecode(bodyString);
    } catch (_) {
      data = bodyString;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? (data['message'] ?? data['title']) : data;
      throw Exception(
        message?.toString().isNotEmpty == true
            ? message.toString()
            : 'Yêu cầu thất bại (${response.statusCode}).',
      );
    }
    return data;
  }

  static Future<http.Response> upload(
    String endpoint, {
    required Map<String, String> fields,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', ConfigUrl.apiUri(endpoint))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: filename),
      );
    return http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 30)),
    );
  }

  static Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    return ConfigUrl.apiUri(endpoint, queryParams: queryParams);
  }

  static Exception _handleException(dynamic error, Uri uri) {
    if (error is TimeoutException) {
      final portStr = uri.hasPort ? ':${uri.port}' : '';
      return Exception(
        'Không thể kết nối tới máy chủ (${uri.host}$portStr).\n'
        'Quá thời gian chờ (40s). Vui lòng kiểm tra kết nối mạng hoặc thử lại sau giây lát.',
      );
    }
    if (error is SocketException) {
      final portStr = uri.hasPort ? ':${uri.port}' : '';
      return Exception(
        'Không thể kết nối tới ${uri.host}$portStr.\n'
        'Vui lòng kiểm tra kết nối mạng hoặc địa chỉ máy chủ.',
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
    var uri = _buildUri(endpoint, queryParams);
    developer.log('GET -> $uri', name: 'ApiClient');
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 40));
      developer.log(
        'RESPONSE [${response.statusCode}] <- $uri',
        name: 'ApiClient',
      );
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
    var uri = _buildUri(endpoint, queryParams);
    developer.log('POST -> ${uri.path}', name: 'ApiClient');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(token),
            body: body is String
                ? body
                : (body != null ? jsonEncode(body) : null),
          )
          .timeout(const Duration(seconds: 40));
      developer.log(
        'RESPONSE [${response.statusCode}] <- $uri',
        name: 'ApiClient',
      );
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
    var uri = _buildUri(endpoint, queryParams);
    developer.log('PUT -> ${uri.path}', name: 'ApiClient');
    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(token),
            body: body is String
                ? body
                : (body != null ? jsonEncode(body) : null),
          )
          .timeout(const Duration(seconds: 40));
      developer.log(
        'RESPONSE [${response.statusCode}] <- $uri',
        name: 'ApiClient',
      );
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
    var uri = _buildUri(endpoint, queryParams);
    developer.log('DELETE -> $uri', name: 'ApiClient');
    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 40));
      developer.log(
        'RESPONSE [${response.statusCode}] <- $uri',
        name: 'ApiClient',
      );
      return response;
    } catch (e) {
      developer.log('ERROR on DELETE $uri: $e', name: 'ApiClient');
      throw _handleException(e, uri);
    }
  }
}
