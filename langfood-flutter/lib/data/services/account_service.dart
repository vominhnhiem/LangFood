import '../../core/network/api_client.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AccountService {
  Future<UserModel> update(
    UserModel current, {
    required String fullName,
    required String phone,
    int? buildingId,
    required String room,
  }) async {
    ApiClient.decodeResponse(
      await ApiClient.put(
        'api/Users/${current.id}',
        body: {
          'fullName': fullName,
          'phoneNumber': phone,
          'buildingId': buildingId,
          'ktxRoom': room,
        },
      ),
    );
    final saved = current.copyWith(
      fullName: fullName,
      phoneNumber: phone,
      buildingId: buildingId,
      ktxRoom: room,
      replaceBuilding: true,
    );
    try {
      return await AuthService().getUserById(current.id);
    } catch (_) {
      return saved;
    }
  }

  Future<String> uploadAvatar(
    String userId,
    List<int> bytes,
    String filename,
  ) async {
    if (bytes.length > 5 * 1024 * 1024)
      throw Exception('Ảnh không được vượt quá 5 MB.');
    final data = ApiClient.decodeResponse(
      await ApiClient.upload(
        'api/Users/upload-avatar/$userId',
        fields: {},
        bytes: bytes,
        filename: filename,
      ),
    ) as Map;
    final url = data['url']?.toString();
    if (url == null || url.isEmpty)
      throw Exception('Máy chủ không trả về đường dẫn ảnh.');
    return url;
  }
}
