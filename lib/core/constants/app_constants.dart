class AppConstants {
  // API Configuration - Update this to match your Laravel installation

  // For physical device (make sure your Laravel server is accessible on network)
  static const String baseUrl = 'https://trianglesmedians.info/api';
  static const String publicUrl = 'https://trianglesmedians.info/';

  // Alternative for emulator (uncomment if using Android emulator)
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String publicUrl = 'http://10.0.2.2:8000';

  // Alternative for localhost testing (requires ADB port forwarding)
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  // static const String publicUrl = 'http://127.0.0.1:8000';

  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String settingsKey = 'app_settings';
  static const String languageKey = 'app_language';

  // App Info
  static const String appName = 'Medians AI CRM';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheExpiry = Duration(hours: 24);

  // API Endpoints (based on MobileAPI module structure)
  static const String authEndpoint = '/auth';
  static const String dashboardEndpoint = '/dashboard';
  static const String clientsEndpoint = '/clients';
  static const String leadsEndpoint = '/leads';
  static const String tasksEndpoint = '/tasks';
  static const String meetingsEndpoint = '/meetings';
  static const String notificationsEndpoint = '/notifications';
}
