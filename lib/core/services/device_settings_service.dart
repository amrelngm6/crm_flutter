import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class DeviceSettingsService {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _autoSyncKey = 'auto_sync';
  static const String _languageKey = 'selected_language';
  static const String _timezoneKey = 'selected_timezone';
  static const String _lastSyncKey = 'last_sync_time';

  static SharedPreferences? _prefs;
  static DeviceInfoPlugin? _deviceInfo;
  static Battery? _battery;
  static Connectivity? _connectivity;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceInfo = DeviceInfoPlugin();
    _battery = Battery();
    _connectivity = Connectivity();
  }

  // Settings Getters
  static bool get notificationsEnabled =>
      _prefs?.getBool(_notificationsKey) ?? true;
  static bool get emailNotifications =>
      _prefs?.getBool(_emailNotificationsKey) ?? true;
  static bool get pushNotifications =>
      _prefs?.getBool(_pushNotificationsKey) ?? true;
  static bool get soundEnabled => _prefs?.getBool(_soundKey) ?? true;
  static bool get vibrationEnabled => _prefs?.getBool(_vibrationKey) ?? true;
  static bool get autoSync => _prefs?.getBool(_autoSyncKey) ?? true;
  static String get selectedLanguage =>
      _prefs?.getString(_languageKey) ?? 'Arabic';
  static String get selectedTimezone =>
      _prefs?.getString(_timezoneKey) ?? 'UTC+00:00';
  static String? get lastSyncTime => _prefs?.getString(_lastSyncKey);

  // Settings Setters
  static Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_notificationsKey, value);
  }

  static Future<void> setEmailNotifications(bool value) async {
    await _prefs?.setBool(_emailNotificationsKey, value);
  }

  static Future<void> setPushNotifications(bool value) async {
    await _prefs?.setBool(_pushNotificationsKey, value);
  }

  static Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool(_soundKey, value);
  }

  static Future<void> setVibrationEnabled(bool value) async {
    await _prefs?.setBool(_vibrationKey, value);

    // Test vibration when enabled
    if (value) {
      try {
        await HapticFeedback.lightImpact();
      } catch (e) {
        print('Error testing haptic feedback: $e');
      }
    }
  }

  static Future<void> setAutoSync(bool value) async {
    await _prefs?.setBool(_autoSyncKey, value);
  }

  static Future<void> setSelectedLanguage(String value) async {
    await _prefs?.setString(_languageKey, value);
  }

  static Future<void> setSelectedTimezone(String value) async {
    await _prefs?.setString(_timezoneKey, value);
  }

  static Future<void> setLastSyncTime(String value) async {
    await _prefs?.setString(_lastSyncKey, value);
  }

  // Device Information
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_deviceInfo == null) return {};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo!.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'device': androidInfo.device,
          'manufacturer': androidInfo.manufacturer,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo!.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return {};
  }

  // Battery Information
  static Future<Map<String, dynamic>> getBatteryInfo() async {
    if (_battery == null) return {};

    try {
      final batteryLevel = await _battery!.batteryLevel;
      final batteryState = await _battery!.batteryState;

      return {
        'level': batteryLevel,
        'state': batteryState.toString().split('.').last,
        'isInBatterySaveMode': await _battery!.isInBatterySaveMode,
      };
    } catch (e) {
      print('Error getting battery info: $e');
      return {};
    }
  }

  // Connectivity Information
  static Future<Map<String, dynamic>> getConnectivityInfo() async {
    if (_connectivity == null) return {};

    try {
      final connectivityResult = await _connectivity!.checkConnectivity();
      return {
        'type': connectivityResult.toString().split('.').last,
        'isConnected': connectivityResult != ConnectivityResult.none,
      };
    } catch (e) {
      print('Error getting connectivity info: $e');
      return {};
    }
  }

  // App Information
  static Future<Map<String, dynamic>> getAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };
    } catch (e) {
      print('Error getting app info: $e');
      return {};
    }
  }

  // Cache Management
  static Future<void> clearCache() async {
    // Clear SharedPreferences cache (keep user settings)
    final keys = _prefs
            ?.getKeys()
            .where((key) =>
                !key.startsWith('user_') &&
                !key.contains('notifications') &&
                !key.contains('settings'))
            .toList() ??
        [];

    for (String key in keys) {
      await _prefs?.remove(key);
    }
  }

  // Storage Information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      // This is a simplified version - in a real app you'd use path_provider
      // and check actual storage usage
      final cacheSize = _prefs?.getKeys().length ?? 0;

      return {
        'cacheEntries': cacheSize,
        'estimatedCacheSizeMB': (cacheSize * 0.1).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {};
    }
  }

  // Test Device Features
  static Future<bool> canVibrate() async {
    try {
      // HapticFeedback is available on most modern devices
      // We'll assume it's available and handle errors gracefully
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> testVibration() async {
    if (vibrationEnabled) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (e) {
        print('Error testing vibration: $e');
      }
    }
  }

  // Sync functionality
  static Future<void> performSync() async {
    try {
      // Simulate sync operation
      await Future.delayed(const Duration(seconds: 2));

      // Update last sync time
      await setLastSyncTime(DateTime.now().toIso8601String());
    } catch (e) {
      print('Error performing sync: $e');
      rethrow;
    }
  }

  // Reset all settings
  static Future<void> resetToDefaults() async {
    await setNotificationsEnabled(true);
    await setEmailNotifications(true);
    await setPushNotifications(true);
    await setSoundEnabled(true);
    await setVibrationEnabled(true);
    await setAutoSync(true);
    await setSelectedLanguage('English');
    await setSelectedTimezone('UTC+00:00');
  }

  // Export settings
  static Map<String, dynamic> exportSettings() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'autoSync': autoSync,
      'selectedLanguage': selectedLanguage,
      'selectedTimezone': selectedTimezone,
      'lastSyncTime': lastSyncTime,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
