import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _secureStorage = FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure Storage (for sensitive data like tokens)
  Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // Regular Storage (for non-sensitive data)
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  Future<void> setStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  // JSON Storage
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await setString(key, jsonString);
  }

  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Remove specific key
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  // Clear all data
  Future<void> clear() async {
    await _prefs?.clear();
    await clearSecureStorage();
  }

  // App-specific methods
  Future<void> saveAuthToken(String token) async {
    await setSecureString('auth_token', token);
  }

  Future<String?> getAuthToken() async {
    return await getSecureString('auth_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await setSecureString('refresh_token', token);
  }

  Future<String?> getRefreshToken() async {
    return await getSecureString('refresh_token');
  }

  Future<void> clearAuthToken() async {
    await deleteSecureString('auth_token');
    await deleteSecureString('refresh_token');
  }

  // Save complete authentication response
  Future<void> saveAuthResponse(Map<String, dynamic> authResponse) async {
    final data = authResponse['data'];

    // Save tokens securely
    final tokens = data['tokens'];
    await saveAuthToken(tokens['access_token']);
    await saveRefreshToken(tokens['refresh_token']);
    await setSecureString('token_type', tokens['token_type']);
    await setInt('token_expires_in', tokens['expires_in']);
    await setInt('refresh_expires_in', tokens['refresh_expires_in']);
    await setInt('token_created_at', DateTime.now().millisecondsSinceEpoch);

    // Save user data
    await saveUserData(data['user']);

    // Save business data
    await saveBusinessData(data['business']);

    // Save user permissions for quick access
    final permissions = List<String>.from(data['user']['permissions'] ?? []);
    await setStringList('user_permissions', permissions);

    // Save user role and status
    await setJson('user_role', data['user']['role']);
    await setJson('user_status', data['user']['status']);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await setJson('user_data', userData);

    // Save specific user info for quick access
    await setInt('user_id', userData['id']);
    await setString('user_name', userData['name']);
    await setString('user_email', userData['email']);
    await setString('user_first_name', userData['first_name'] ?? '');
    await setString('user_last_name', userData['last_name'] ?? '');
    await setString('user_position', userData['position'] ?? '');
    await setString('user_avatar', userData['avatar'] ?? '');
    await setInt('user_business_id', userData['business_id'] ?? 0);
  }

  Map<String, dynamic>? getUserData() {
    return getJson('user_data');
  }

  Future<void> saveBusinessData(Map<String, dynamic> businessData) async {
    await setJson('business_data', businessData);
    await setInt('business_id', businessData['id']);
    await setString('business_name', businessData['name']);
  }

  Map<String, dynamic>? getBusinessData() {
    return getJson('business_data');
  }

  // Quick access methods
  int? getUserId() => getInt('user_id');
  String? getUserName() => getString('user_name');
  String? getUserEmail() => getString('user_email');
  String? getUserFirstName() => getString('user_first_name');
  String? getUserLastName() => getString('user_last_name');
  String? getUserPosition() => getString('user_position');
  String? getUserAvatar() => getString('user_avatar');
  int? getUserBusinessId() => getInt('user_business_id');

  int? getBusinessId() => getInt('business_id');
  String? getBusinessName() => getString('business_name');

  List<String>? getUserPermissions() => getStringList('user_permissions');
  Map<String, dynamic>? getUserRole() => getJson('user_role');
  Map<String, dynamic>? getUserStatus() => getJson('user_status');

  // Permission checking
  bool hasPermission(String permission) {
    final permissions = getUserPermissions();
    return permissions?.contains(permission) ?? false;
  }

  // Token management
  bool isTokenExpired() {
    final createdAt = getInt('token_created_at');
    final expiresIn = getInt('token_expires_in');

    if (createdAt == null || expiresIn == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredAt = createdAt + (expiresIn * 1000); // Convert to milliseconds

    return now >= expiredAt;
  }

  bool isRefreshTokenExpired() {
    final createdAt = getInt('token_created_at');
    final refreshExpiresIn = getInt('refresh_expires_in');

    if (createdAt == null || refreshExpiresIn == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredAt =
        createdAt + (refreshExpiresIn * 1000); // Convert to milliseconds

    return now >= expiredAt;
  }

  // Clear all authentication data
  Future<void> clearAuthData() async {
    // Clear secure tokens
    await clearAuthToken();
    await deleteSecureString('token_type');

    // Clear user data
    await remove('user_data');
    await remove('business_data');
    await remove('user_permissions');
    await remove('user_role');
    await remove('user_status');

    // Clear quick access data
    await remove('user_id');
    await remove('user_name');
    await remove('user_email');
    await remove('user_first_name');
    await remove('user_last_name');
    await remove('user_position');
    await remove('user_avatar');
    await remove('user_business_id');
    await remove('business_id');
    await remove('business_name');

    // Clear token timing
    await remove('token_expires_in');
    await remove('refresh_expires_in');
    await remove('token_created_at');
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await setJson('app_settings', settings);
  }

  Map<String, dynamic>? getAppSettings() {
    return getJson('app_settings');
  }

  Future<void> saveThemeSettings(Map<String, dynamic> themeSettings) async {
    await setJson('theme_settings', themeSettings);
  }

  Map<String, dynamic>? getThemeSettings() {
    return getJson('theme_settings');
  }
}
