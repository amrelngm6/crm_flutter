import 'package:flutter/foundation.dart';
import 'package:medians_ai_crm/core/constants/app_constants.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  Business? _currentBusiness;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  Business? get currentBusiness => _currentBusiness;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _apiService.isLoggedIn();

  // User info getters
  String get userName => _currentUser?.name ?? '';
  String get firstName => _currentUser?.firstName ?? '';
  String get userEmail => _currentUser?.email ?? '';
  String get userPosition => _currentUser?.position ?? '';
  String get userAvatar => _currentUser?.avatar ?? '';
  String get userFullName => _currentUser?.fullName ?? '';
  String get businessName => _currentBusiness?.name ?? '';

  // Permission checking
  bool hasPermission(String permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  bool hasRole(String roleName) {
    return _currentUser?.role.name == roleName;
  }

  bool get isUserActive {
    return _currentUser?.status.name == 'Active';
  }

  // Load user data from storage
  Future<void> loadUserFromStorage() async {
    try {
      _setLoading(true);
      _setError(null);

      final userData = _storage.getUserData();
      final businessData = _storage.getBusinessData();

      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }

      if (businessData != null) {
        _currentBusiness = Business.fromJson(businessData);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Refresh user data from API
  Future<void> refreshUserData() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.getUserProfile();

      if (response['success'] == true) {
        final userData = response['data']['user'];
        final businessData = response['data']['business'];

        // Update storage
        await _storage.saveUserData(userData);
        if (businessData != null) {
          await _storage.saveBusinessData(businessData);
        }

        // Update current user
        _currentUser = User.fromJson(userData);
        if (businessData != null) {
          _currentBusiness = Business.fromJson(businessData);
        }

        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to get user profile');
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to refresh user data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Login with credentials
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.login(email, password);

      if (response['success'] == true) {
        // Data is already saved by ApiService
        await loadUserFromStorage();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      debugPrint('Logout API call failed: $e');
    } finally {
      // Clear local data
      _currentUser = null;
      _currentBusiness = null;
      await _storage.clearAuthData();
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _setLoading(true);
      _setError(null);

      // TODO: Implement update profile API call
      // final response = await _apiService.updateProfile(profileData);

      // For now, just update local data
      if (_currentUser != null) {
        final updatedUserData = _currentUser!.toJson();
        updatedUserData.addAll(profileData);

        await _storage.saveUserData(updatedUserData);
        _currentUser = User.fromJson(updatedUserData);

        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Check and refresh token if needed
  Future<bool> checkAuthStatus() async {
    try {
      if (_storage.isTokenExpired()) {
        if (!_storage.isRefreshTokenExpired()) {
          // Try to refresh token
          final response = await _apiService.refreshToken();
          if (response['success'] == true) {
            await loadUserFromStorage();
            return true;
          }
        }
        // Token refresh failed or refresh token expired
        await logout();
        return false;
      }

      // Token is still valid
      if (_currentUser == null) {
        await loadUserFromStorage();
      }
      return isLoggedIn;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Get user's avatar URL
  String getUserAvatarUrl() {
    print(_currentUser?.avatar);
    if (_currentUser?.avatar == null || _currentUser!.avatar!.isEmpty) {
      return '';
    }

    // If it's already a full URL, return as is
    if (_currentUser!.avatar!.startsWith('http')) {
      return _currentUser!.avatar!;
    }

    // Otherwise, construct the URL (update with your domain)
    return '${AppConstants.publicUrl}${_currentUser!.avatar}';
  }

  // Get user initials for avatar placeholder
  String getUserInitials() {
    if (_currentUser == null) return '?';

    final firstName = _currentUser!.firstName;
    final lastName = _currentUser!.lastName;

    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];

    return initials.isEmpty
        ? _currentUser!.name.isNotEmpty
            ? _currentUser!.name[0]
            : '?'
        : initials;
  }
}
