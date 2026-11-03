import 'dart:convert';

import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  Future<UserModel> login(String username, String password) async {
    final response = await ApiClient.post(
      'api/Users/login',
      body: {
        'username': username,
        'passwordHash': password, // Matches backend UsersController
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return UserModel.fromJson(data);
    } else {
      String errorMessage = 'Đăng nhập thất bại';
      try {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        if (err is Map && err.containsKey('message')) {
          errorMessage = err['message'];
        }
      } catch (_) {
        final bodyStr = utf8.decode(response.bodyBytes);
        errorMessage = bodyStr.isNotEmpty ? bodyStr : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  Future<UserModel> getUserById(String id) async {
    final response = await ApiClient.get('api/Users/$id');
    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Không tìm thấy thông tin người dùng');
  }

  Future<String> sendOtp(String email) async {
    final response = await ApiClient.post(
      'api/Users/send-otp',
      queryParams: {'email': email},
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data['message'] ?? 'Đã gửi mã OTP thành công!';
    }
    throw Exception(data['message'] ?? 'Không thể gửi mã OTP');
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final response = await ApiClient.post(
      'api/Users/verify-otp',
      queryParams: {'email': email, 'otp': otp},
    );
    if (response.statusCode == 200) {
      return true;
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception(data['message'] ?? 'Mã OTP không đúng hoặc đã hết hạn');
  }

  Future<UserModel> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
    int? buildingId,
    String? ktxRoom,
  }) async {
    final response = await ApiClient.post(
      'api/Users/register',
      body: {
        'username': username,
        'passwordHash': password,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phone,
        'buildingId': buildingId,
        'ktxRoom': ktxRoom,
        'roleId': 1, // Student / Customer
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return UserModel.fromJson(data);
    } else {
      String errorMessage = 'Đăng ký thất bại';
      try {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        if (err is Map && err.containsKey('message')) {
          errorMessage = err['message'];
        }
      } catch (_) {
        final bodyStr = utf8.decode(response.bodyBytes);
        errorMessage = bodyStr.isNotEmpty ? bodyStr : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  Future<List<Map<String, dynamic>>> getBuildings() async {
    final response = await ApiClient.get('api/Buildings');
    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách tòa nhà.');
    }
    final List data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
