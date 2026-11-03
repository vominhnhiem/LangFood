import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String get mapTileUrl =>
      _configuredTileUrl('MAP_TILE_URL') ??
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String? get mapTileFallbackUrl =>
      _configuredTileUrl('MAP_TILE_FALLBACK_URL');

  static String? _configuredTileUrl(String name) {
    final value = dotenv.isInitialized ? dotenv.env[name]?.trim() : null;
    return value == null || value.isEmpty ? null : value;
  }

  static double get shippingFee {
    final raw = dotenv.isInitialized ? dotenv.env['SHIPPING_FEE'] : null;
    final fee = double.tryParse(raw?.trim() ?? '');
    if (fee == null || !fee.isFinite || fee < 0) {
      throw StateError(
        'SHIPPING_FEE trong .env phải là số tiền không âm (VND).',
      );
    }
    return fee;
  }

  static String get baseUrl {
    final configured = dotenv.isInitialized
        ? dotenv.env['BASE_URL']?.trim()
        : null;
    final url = configured == null || configured.isEmpty
        ? (kIsWeb ? 'http://localhost:5289/api/' : 'http://10.0.2.2:5289/api/')
        : configured;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('BASE_URL trong .env phải là URL HTTP/HTTPS hợp lệ.');
    }
    return url.endsWith('/') ? url : '$url/';
  }

  // Uploaded images are served from /images, outside the /api prefix.
  static String get serverUrl {
    final uri = Uri.parse(baseUrl);
    return uri.path.endsWith('/api/') ? uri.resolve('../').toString() : baseUrl;
  }

  static Uri apiUri(String endpoint, {Map<String, dynamic>? queryParams}) {
    var path = endpoint.replaceFirst(RegExp(r'^/+'), '');
    if (Uri.parse(baseUrl).path.endsWith('/api/') && path.startsWith('api/')) {
      path = path.substring(4);
    }
    final uri = Uri.parse('$baseUrl$path');
    return queryParams == null || queryParams.isEmpty
        ? uri
        : uri.replace(
            queryParameters: queryParams.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
          );
  }
}
