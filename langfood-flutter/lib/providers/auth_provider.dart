import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  String? _accessToken;
  bool _isLoading = false;
  bool _disposed = false;
  int _epoch = 0;
  String? _errorMessage;
  AuthProvider({AuthService? service, bool restoreSession = true})
    : _authService = service ?? AuthService() {
    if (restoreSession) loadUserFromPrefs();
  }
  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _persist(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('USER_PROFILE', jsonEncode(user.toJson()));
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUsername, user.username);
    await prefs.setInt(AppConstants.keyRoleId, user.roleId);
    if (user.fullName != null)
      await prefs.setString(AppConstants.keyFullName, user.fullName!);
    for (final entry in {
      AppConstants.keyShopId: user.shopId,
      AppConstants.keyShipperId: user.shipperId,
    }.entries) {
      if (entry.value == null) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setInt(entry.key, entry.value!);
      }
    }
  }

  Future<void> loadUserFromPrefs() async {
    final epoch = _epoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(AppConstants.keyUserId);
      if (id == null || epoch != _epoch || _disposed) return;
      final saved = prefs.getString('USER_PROFILE');
      _user = saved == null
          ? UserModel(
              id: id,
              username: prefs.getString(AppConstants.keyUsername) ?? '',
              fullName: prefs.getString(AppConstants.keyFullName),
              roleId: prefs.getInt(AppConstants.keyRoleId) ?? 1,
              shopId: prefs.getInt(AppConstants.keyShopId),
              shipperId: prefs.getInt(AppConstants.keyShipperId),
            )
          : UserModel.fromJson(Map<String, dynamic>.from(jsonDecode(saved)));
      _notify();
      try {
        final fresh = await _authService.getUserById(id);
        if (epoch == _epoch && !_disposed) {
          _user = fresh;
          await _persist(fresh);
          _notify();
        }
      } catch (_) {
        /* Keep the saved profile while offline. */
      }
    } catch (e) {
      debugPrint('Load session: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    final epoch = ++_epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final user = await _authService.login(username, password);
      if (epoch != _epoch || _disposed) return false;
      await _persist(user);
      if (epoch != _epoch || _disposed) return false;
      _accessToken = user.token;
      _user = user;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> setProfile(UserModel profile) async {
    if (_user?.id != profile.id) return;
    _user = profile;
    await _persist(profile);
    _notify();
  }

  Future<void> logout() async {
    _epoch++;
    _user = null;
    _accessToken = null;
    _notify();
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'USER_PROFILE',
      AppConstants.keyUserId,
      AppConstants.keyUsername,
      AppConstants.keyFullName,
      AppConstants.keyRoleId,
      AppConstants.keyShopId,
      AppConstants.keyShipperId,
      AppConstants.keyAvatarUrl,
      AppConstants.keyJwtToken,
    ]) {
      await prefs.remove(key);
    }
  }
}
