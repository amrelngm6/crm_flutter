import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/device_settings_service.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSync = true;
  String _selectedLanguage = 'English';
  String _selectedTimeZone = 'UTC+00:00';
  bool _isLoading = false;
  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _batteryInfo = {};
  Map<String, dynamic> _connectivityInfo = {};
  Map<String, dynamic> _appInfo = {};
  Map<String, dynamic> _storageInfo = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDeviceInfo();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _notificationsEnabled = DeviceSettingsService.notificationsEnabled;
      _emailNotifications = DeviceSettingsService.emailNotifications;
      _pushNotifications = DeviceSettingsService.pushNotifications;
      _soundEnabled = DeviceSettingsService.soundEnabled;
      _vibrationEnabled = DeviceSettingsService.vibrationEnabled;
      _autoSync = DeviceSettingsService.autoSync;
      _selectedLanguage = DeviceSettingsService.selectedLanguage;
      _selectedTimeZone = DeviceSettingsService.selectedTimezone;
    });
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = await DeviceSettingsService.getDeviceInfo();
    final batteryInfo = await DeviceSettingsService.getBatteryInfo();
    final connectivityInfo = await DeviceSettingsService.getConnectivityInfo();
    final appInfo = await DeviceSettingsService.getAppInfo();
    final storageInfo = await DeviceSettingsService.getStorageInfo();

    setState(() {
      _deviceInfo = deviceInfo;
      _batteryInfo = batteryInfo;
      _connectivityInfo = connectivityInfo;
      _appInfo = appInfo;
      _storageInfo = storageInfo;
    });
  }

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Arabic'
  ];

  final List<String> _timeZones = [
    'UTC-12:00',
    'UTC-11:00',
    'UTC-10:00',
    'UTC-09:00',
    'UTC-08:00',
    'UTC-07:00',
    'UTC-06:00',
    'UTC-05:00',
    'UTC-04:00',
    'UTC-03:00',
    'UTC-02:00',
    'UTC-01:00',
    'UTC+00:00',
    'UTC+01:00',
    'UTC+02:00',
    'UTC+03:00',
    'UTC+04:00',
    'UTC+05:00',
    'UTC+06:00',
    'UTC+07:00',
    'UTC+08:00',
    'UTC+09:00',
    'UTC+10:00',
    'UTC+11:00',
    'UTC+12:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('General Settings'.tr()),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Settings
            _buildSectionHeader('Appearance'.tr()),
            Card(
              child: Column(
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ListTile(
                        leading: const Icon(Icons.palette),
                        title: Text('Theme Mode'.tr()),
                        subtitle:
                            Text(_getThemeModeText(themeProvider.themeMode)),
                        trailing: DropdownButton<ThemeMode>(
                          value: themeProvider.themeMode,
                          items: [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'.tr()),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'.tr()),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'.tr()),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              themeProvider.setThemeMode(mode);
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const Divider(),

                  // Primary Color Selection
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: Text('Primary Color'.tr()),
                        subtitle: Text('Choose your app\'s primary color'.tr()),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () => _showColorPicker(context, themeProvider),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Settings Section
            _buildSectionHeader('Notification Settings'.tr()),

            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications,
                iconColor: const Color(0xFF2196F3),
                title: 'Enable Notifications'.tr(),
                subtitle: 'Receive app notifications'.tr(),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  await DeviceSettingsService.setNotificationsEnabled(value);
                },
              ),
              const Divider(
                height: 1,
              ),
              _buildSwitchTile(
                icon: Icons.email,
                iconColor: const Color(0xFFFF9800),
                title: 'Email Notifications'.tr(),
                subtitle: 'Receive notifications via email'.tr(),
                value: _emailNotifications,
                onChanged: (value) async {
                  setState(() {
                    _emailNotifications = value;
                  });
                  await DeviceSettingsService.setEmailNotifications(value);
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                icon: Icons.phone_android,
                iconColor: const Color(0xFF00BCD4),
                title: 'Push Notifications'.tr(),
                subtitle: 'Receive push notifications'.tr(),
                value: _pushNotifications,
                onChanged: (value) async {
                  setState(() {
                    _pushNotifications = value;
                  });
                  await DeviceSettingsService.setPushNotifications(value);
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                icon: Icons.volume_up,
                iconColor: const Color(0xFFE91E63),
                title: 'Sound'.tr(),
                subtitle: 'Play notification sounds'.tr(),
                value: _soundEnabled,
                onChanged: (value) async {
                  setState(() {
                    _soundEnabled = value;
                  });
                  await DeviceSettingsService.setSoundEnabled(value);
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                icon: Icons.vibration,
                iconColor: const Color(0xFF795548),
                title: 'Vibration'.tr(),
                subtitle: 'Vibrate for notifications'.tr(),
                value: _vibrationEnabled,
                onChanged: (value) async {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                  await DeviceSettingsService.setVibrationEnabled(value);
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Language & Region Section
            _buildSectionHeader('Language & Region'.tr()),
            _buildSettingsCard([
              _buildDropdownTile(
                icon: Icons.language,
                iconColor: const Color(0xFF3F51B5),
                title: 'Language'.tr(),
                subtitle: _selectedLanguage,
                items: _languages,
                value: _selectedLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                      print(_selectedLanguage);
                    });
                    await DeviceSettingsService.setSelectedLanguage(value);
                  }
                },
              ),
              const Divider(height: 1),
              _buildDropdownTile(
                icon: Icons.access_time,
                iconColor: const Color(0xFF607D8B),
                title: 'Time Zone'.tr(),
                subtitle: _selectedTimeZone,
                items: _timeZones,
                value: _selectedTimeZone,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      _selectedTimeZone = value;
                    });
                    await DeviceSettingsService.setSelectedTimezone(value);
                  }
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Device Features Section
            _buildSectionHeader('Device Features'.tr()),
            _buildSettingsCard([
              // _buildActionTile(
              //   icon: Icons.vibration,
              //   iconColor: const Color(0xFF795548),
              //   title: 'Test Vibration',
              //   subtitle: 'Test device vibration functionality',
              //   onTap: () => _testVibration(),
              // ),
              // const Divider(height: 1),
              _buildActionTile(
                icon: Icons.sync,
                iconColor: const Color(0xFF4CAF50),
                title: 'Manual Sync'.tr(),
                subtitle: DeviceSettingsService.lastSyncTime != null
                    ? "${'Last sync'.tr()}: ${_formatLastSync()}"
                    : 'Never synced'.tr(),
                onTap: () => _performSync(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.storage,
                iconColor: const Color(0xFF607D8B),
                title: 'Storage Info'.tr(),
                subtitle:
                    'Cache: ${_storageInfo['estimatedCacheSizeMB'] ?? '0.0'} MB',
                onTap: () => _showStorageDialog(),
              ),
            ]),

            const SizedBox(height: 24),

            // Device Information Section
            _buildSectionHeader('Device Information'.tr()),
            _buildSettingsCard([
              _buildInfoTile(
                icon: Icons.smartphone,
                iconColor: const Color(0xFF9C27B0),
                title: 'Device Model'.tr(),
                subtitle: _deviceInfo['model'] ?? 'Unknown'.tr(),
              ),
              const Divider(height: 1),
              _buildInfoTile(
                icon: Icons.battery_std,
                iconColor: const Color(0xFF4CAF50),
                title: 'Battery Level'.tr(),
                subtitle: _batteryInfo['level'] != null
                    ? '${_batteryInfo['level']}%'
                    : 'Unknown'.tr(),
              ),
              const Divider(height: 1),
              _buildInfoTile(
                icon: Icons.wifi,
                iconColor: const Color(0xFF2196F3),
                title: 'Connection'.tr(),
                subtitle: _connectivityInfo['type'] ?? 'Unknown'.tr(),
              ),
              const Divider(height: 1),
              _buildInfoTile(
                icon: Icons.info,
                iconColor: const Color(0xFFFF9800),
                title: 'App Version'.tr(),
                subtitle: _appInfo['version'] ?? '1.0.0',
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.refresh,
                iconColor: const Color(0xFF607D8B),
                title: 'Refresh Device Info'.tr(),
                subtitle: 'Update device information'.tr(),
                onTap: () => _loadDeviceInfo(),
              ),
            ]),

            const SizedBox(height: 24),
            // Data & Storage Section
            _buildSectionHeader('Data & Storage'.tr()),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.cached,
                iconColor: const Color(0xFFFF5722),
                title: 'Clear Cache'.tr(),
                subtitle: 'Free up storage space'.tr(),
                onTap: () => _showClearCacheDialog(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.download,
                iconColor: const Color(0xFF4CAF50),
                title: 'Download Data'.tr(),
                subtitle: 'Export your data'.tr(),
                onTap: () => _showDownloadDataDialog(),
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.restore,
                iconColor: const Color(0xFF2196F3),
                title: 'Reset Settings'.tr(),
                subtitle: 'Reset to default settings'.tr(),
                onTap: () => _showResetSettingsDialog(),
              ),
            ]),

            const SizedBox(height: 24),

            // Save Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () => _saveSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Save Settings'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1B4D3E),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> items,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        underline: const SizedBox(),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will clear all cached data and may improve app performance. Continue?'
                  .tr(),
            ),
            const SizedBox(height: 16),
            if (_storageInfo.isNotEmpty) ...[
              Text(
                '${'Cache entries'.tr()}: ${_storageInfo['cacheEntries'] ?? 0}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                '${'Estimated size'.tr()}: ${_storageInfo['estimatedCacheSizeMB'] ?? '0.0'} MB',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download Data'.tr()),
        content: Text(
          'This will prepare your data for download. You will receive an email with the download link.'
              .tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadData();
            },
            child: Text('Download'.tr()),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Settings'.tr()),
        content: Text(
          'This will reset all settings to their default values. This action cannot be undone.'
              .tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Reset'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _performSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DeviceSettingsService.performSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync completed successfully'.tr()),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed'.tr() + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearCache() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await DeviceSettingsService.clearCache();
      final storageInfo = await DeviceSettingsService.getStorageInfo();

      setState(() {
        _storageInfo = storageInfo;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cache cleared successfully'.tr()),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'Failed to clear cache'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadData() {
    try {
      final settings = DeviceSettingsService.exportSettings();
      // In a real app, you would implement file download/sharing here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${'Settings exported'.tr()}: ${settings.length} items'),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed'.tr() + ': $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetSettings() async {
    try {
      await DeviceSettingsService.resetToDefaults();
      await _loadSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings reset to defaults'.tr()),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset failed'.tr() + ': $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveSettings() {
    // Settings are automatically saved when changed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully'.tr()),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Future<void> _testVibration() async {
    try {
      await DeviceSettingsService.testVibration();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vibration test completed'.tr()),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vibration test failed'.tr() + ': $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatLastSync() {
    final lastSync = DeviceSettingsService.lastSyncTime;
    if (lastSync == null) return 'Never'.tr();

    try {
      final syncTime = DateTime.parse(lastSync);
      final now = DateTime.now();
      final difference = now.difference(syncTime);

      if (difference.inMinutes < 1) {
        return 'Just now'.tr();
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Information'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStorageInfoRow(
                'Cache Entries', '${_storageInfo['cacheEntries'] ?? 0}'),
            _buildStorageInfoRow('Estimated Size'.tr(),
                '${_storageInfo['estimatedCacheSizeMB'] ?? '0.0'} MB'),
            const SizedBox(height: 16),
            if (_deviceInfo.isNotEmpty) ...[
              Text(
                'Device Information:'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStorageInfoRow(
                  'Platform'.tr(), _deviceInfo['platform'] ?? 'Unknown'.tr()),
              _buildStorageInfoRow(
                  'Model'.tr(), _deviceInfo['model'] ?? 'Unknown'.tr()),
              if (_deviceInfo['version'] != null)
                _buildStorageInfoRow('OS Version'.tr(), _deviceInfo['version']),
            ],
            const SizedBox(height: 16),
            if (_batteryInfo.isNotEmpty) ...[
              Text(
                'Battery Information:'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStorageInfoRow(
                  'Level'.tr(), '${_batteryInfo['level'] ?? 0}%'),
              _buildStorageInfoRow(
                  'State'.tr(), _batteryInfo['state'] ?? 'Unknown'.tr()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadDeviceInfo();
            },
            child: Text('Refresh'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system setting'.tr();
      case ThemeMode.light:
        return 'Light mode'.tr();
      case ThemeMode.dark:
        return 'Dark mode'.tr();
    }
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Primary Color'.tr()),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            AppTheme.primaryBlue,
            AppTheme.primaryGreen,
            AppTheme.primaryPurple,
            AppTheme.primaryOrange,
            Colors.red,
            Colors.teal,
            Colors.indigo,
            Colors.pink,
          ]
              .map((color) => GestureDetector(
                    onTap: () {
                      themeProvider.setPrimaryColor(color);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: themeProvider.primaryColor == color
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: themeProvider.primaryColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'.tr()),
          ),
        ],
      ),
    );
  }
}
