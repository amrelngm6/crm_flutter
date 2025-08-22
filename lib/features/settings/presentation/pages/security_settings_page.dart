import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _autoLockEnabled = true;
  String _autoLockDuration = '5 minutes';
  bool _loginAlertsEnabled = true;
  bool _deviceTrustEnabled = false;

  final List<String> _autoLockOptions = [
    'Immediately',
    '1 minute',
    '5 minutes',
    '15 minutes',
    '30 minutes',
    'Never'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Settings'.tr()),
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
            // Authentication Section
            _buildSectionHeader('Authentication'.tr()),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.lock,
                iconColor: const Color(0xFFE53E3E),
                title: 'Change Password'.tr(),
                subtitle: 'Update your password'.tr(),
                onTap: () => _showChangePasswordDialog(),
              ),
              // const Divider(height: 1),
              // _buildSwitchTile(
              //   icon: Icons.fingerprint,
              //   iconColor: const Color(0xFF2196F3),
              //   title: 'Biometric Authentication',
              //   subtitle: 'Use fingerprint or face ID',
              //   value: _biometricEnabled,
              //   onChanged: (value) {
              //     setState(() {
              //       _biometricEnabled = value;
              //     });
              //   },
              // ),
              const Divider(height: 1),
              _buildSwitchTile(
                icon: Icons.security,
                iconColor: const Color(0xFF4CAF50),
                title: 'Two-Factor Authentication'.tr(),
                subtitle: 'Extra security layer'.tr(),
                value: _twoFactorEnabled,
                onChanged: (value) {
                  if (value) {
                    _showTwoFactorSetupDialog();
                  } else {
                    setState(() {
                      _twoFactorEnabled = value;
                    });
                  }
                },
              ),
            ]),

            // const SizedBox(height: 24),

            // // App Security Section
            // _buildSectionHeader('App Security'),
            // _buildSettingsCard([
            //   _buildSwitchTile(
            //     icon: Icons.lock_clock,
            //     iconColor: const Color(0xFFFF9800),
            //     title: 'Auto Lock',
            //     subtitle: 'Lock app after inactivity',
            //     value: _autoLockEnabled,
            //     onChanged: (value) {
            //       setState(() {
            //         _autoLockEnabled = value;
            //       });
            //     },
            //   ),
            //   const Divider(height: 1),
            //   _buildDropdownTile(
            //     icon: Icons.timer,
            //     iconColor: const Color(0xFF9C27B0),
            //     title: 'Auto Lock Duration',
            //     subtitle: _autoLockDuration,
            //     items: _autoLockOptions,
            //     value: _autoLockDuration,
            //     enabled: _autoLockEnabled,
            //     onChanged: (value) {
            //       if (value != null) {
            //         setState(() {
            //           _autoLockDuration = value;
            //         });
            //       }
            //     },
            //   ),
            // ]),

            const SizedBox(height: 24),

            // Privacy & Alerts Section
            _buildSectionHeader('Privacy & Alerts'.tr()),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications_active,
                iconColor: const Color(0xFFE91E63),
                title: 'Login Alerts'.tr(),
                subtitle: 'Get notified of new logins'.tr(),
                value: _loginAlertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _loginAlertsEnabled = value;
                  });
                },
              ),
              // const Divider(height: 1),
              // _buildSwitchTile(
              //   icon: Icons.verified_user,
              //   iconColor: const Color(0xFF00BCD4),
              //   title: 'Device Trust',
              //   subtitle: 'Remember trusted devices',
              //   value: _deviceTrustEnabled,
              //   onChanged: (value) {
              //     setState(() {
              //       _deviceTrustEnabled = value;
              //     });
              //   },
              // ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.history,
                iconColor: const Color(0xFF607D8B),
                title: 'Login History'.tr(),
                subtitle: 'View recent login activity'.tr(),
                onTap: () => _showLoginHistory(),
              ),
            ]),

            // const SizedBox(height: 24),

            // // Data Protection Section
            // _buildSectionHeader('Data Protection'),
            // _buildSettingsCard([
            //   _buildActionTile(
            //     icon: Icons.download,
            //     iconColor: const Color(0xFF4CAF50),
            //     title: 'Export Data',
            //     subtitle: 'Download your personal data',
            //     onTap: () => _showExportDataDialog(),
            //   ),
            //   const Divider(height: 1),
            //   _buildActionTile(
            //     icon: Icons.delete_forever,
            //     iconColor: const Color(0xFFE53E3E),
            //     title: 'Delete Account',
            //     subtitle: 'Permanently delete your account',
            //     onTap: () => _showDeleteAccountDialog(),
            //   ),
            // ]),

            const SizedBox(height: 24),

            // Emergency Actions Section
            // _buildSectionHeader('Emergency Actions'),
            // _buildSettingsCard([
            //   _buildActionTile(
            //     icon: Icons.block,
            //     iconColor: const Color(0xFFFF5722),
            //     title: 'Logout All Devices',
            //     subtitle: 'Sign out from all devices',
            //     onTap: () => _showLogoutAllDialog(),
            //   ),
            //   const Divider(height: 1),
            //   _buildActionTile(
            //     icon: Icons.refresh,
            //     iconColor: const Color(0xFF3F51B5),
            //     title: 'Reset Security Settings',
            //     subtitle: 'Reset all security preferences',
            //     onTap: () => _showResetSecurityDialog(),
            //   ),
            // ]),

            // const SizedBox(height: 24),

            // Save Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () => _saveSecuritySettings(),
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
                  'Save Security Settings'.tr(),
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
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: enabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? iconColor : iconColor.withValues(alpha: 0.5),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.grey[600] : Colors.grey[400],
          fontSize: 14,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: enabled ? onChanged : null,
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

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
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
              _changePassword();
            },
            child: Text('Change Password'.tr()),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Setup Two-Factor Authentication'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Two-factor authentication adds an extra layer of security to your account.'
                  .tr(),
            ),
            const SizedBox(height: 16),
            Text(
              'Setup methods'.tr(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• SMS verification'.tr()),
            Text('• Authenticator app'.tr()),
            Text('• Email verification'.tr()),
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
              setState(() {
                _twoFactorEnabled = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Two-factor authentication enabled'.tr()),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
            },
            child: Text('Setup'),
          ),
        ],
      ),
    );
  }

  void _showLoginHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login History'.tr()),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr()),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password changed successfully'.tr()),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _saveSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Security settings saved successfully'.tr()),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}
