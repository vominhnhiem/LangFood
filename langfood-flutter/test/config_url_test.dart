import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/config/config_url.dart';
import 'package:langfood_flutter/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => dotenv.clean());

  test(
    'delivery fee is configured explicitly and invalid values are rejected',
    () {
      dotenv.loadFromString(envString: 'SHIPPING_FEE=15000');
      expect(ConfigUrl.shippingFee, 15000);
      dotenv.loadFromString(envString: 'SHIPPING_FEE=-1');
      expect(() => ConfigUrl.shippingFee, throwsStateError);
      dotenv.loadFromString(envString: 'BASE_URL=http://localhost:5289/api/');
      expect(() => ConfigUrl.shippingFee, throwsStateError);
    },
  );

  test('loads the declared .env asset', () async {
    await dotenv.load(fileName: '.env');
    expect(dotenv.env['BASE_URL'], isNotEmpty);
    expect(Uri.parse(ConfigUrl.baseUrl).hasAuthority, isTrue);
  });

  test('uses environment URL and normalizes its trailing slash', () {
    dotenv.loadFromString(envString: 'BASE_URL=https://example.com/api');
    expect(ConfigUrl.baseUrl, 'https://example.com/api/');
  });

  test('does not duplicate api prefix and preserves query parameters', () {
    dotenv.loadFromString(envString: 'BASE_URL=https://example.com/api/');
    expect(
      ConfigUrl.apiUri('api/Users/login').toString(),
      'https://example.com/api/Users/login',
    );
    expect(
      ConfigUrl.apiUri(
        '/Products',
        queryParams: {'search': 'cơm gà'},
      ).queryParameters['search'],
      'cơm gà',
    );
  });

  test('image URLs use server root, including deployment prefixes', () {
    dotenv.loadFromString(
      envString: 'BASE_URL=https://example.com/langfood/api/',
    );
    expect(
      ApiClient.resolveImageUrl('/images/food.jpg'),
      'https://example.com/langfood/images/food.jpg',
    );
  });

  test('empty BASE_URL falls back and invalid schemes are rejected', () {
    dotenv.loadFromString(envString: 'BASE_URL=');
    expect(ConfigUrl.baseUrl, 'http://10.0.2.2:5289/api/');
    dotenv.loadFromString(envString: 'BASE_URL=ftp://example.com/api/');
    expect(() => ConfigUrl.baseUrl, throwsStateError);
  });
}
