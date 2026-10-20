import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    loadUserFromPrefs();
  }

  Future<void> loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.keyUserId);
      if (userId != null && userId.isNotEmpty) {
        final username = prefs.getString(AppConstants.keyUsername) ?? '';
        final fullName = prefs.getString(AppConstants.keyFullName);
        final roleId = prefs.getInt(AppConstants.keyRoleId) ?? 1;
        final shopId = prefs.getInt(AppConstants.keyShopId);
        final shipperId = prefs.getInt(AppConstants.keyShipperId);

        _user = UserModel(
          id: userId,
          username: username,
          fullName: fullName,
          roleId: roleId,
          shopId: shopId,
          shipperId: shipperId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider.loadUserFromPrefs error: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(username, password);
      _user = user;

      // Persist session into SharedPreferences (compatible with LangFoodPrefs in Java)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, user.id);
      await prefs.setString(AppConstants.keyUsername, user.username);
      if (user.fullName != null) {
        await prefs.setString(AppConstants.keyFullName, user.fullName!);
      }
      await prefs.setInt(AppConstants.keyRoleId, user.roleId);
      if (user.shopId != null) {
        await prefs.setInt(AppConstants.keyShopId, user.shopId!);
      }
      if (user.shipperId != null) {
        await prefs.setInt(AppConstants.keyShipperId, user.shipperId!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUsername);
    await prefs.remove(AppConstants.keyFullName);
    await prefs.remove(AppConstants.keyRoleId);
    await prefs.remove(AppConstants.keyShopId);
    await prefs.remove(AppConstants.keyShipperId);
    notifyListeners();
  }
}
