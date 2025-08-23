import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/email_account.dart';

class EmailAccountCard extends StatelessWidget {
  final EmailAccount account;
  final VoidCallback? onTap;

  const EmailAccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with email and status
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAccountIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name.isNotEmpty ? account.name : account.email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status and default indicators
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (account.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Default'.tr(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Email statistics
            Row(
              children: [
                _buildStatistic(
                  icon: Icons.email,
                  label: 'Total'.tr(),
                  value: account.stats.totalMessages.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatistic(
                  icon: Icons.mark_email_unread,
                  label: 'Unread'.tr(),
                  value: account.stats.unreadMessages.toString(),
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatistic(
                  icon: Icons.schedule,
                  label: 'Recent'.tr(),
                  value: account.stats.recentMessages.toString(),
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Connection info
            Row(
              children: [
                Icon(
                  Icons.sync,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _getSyncStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (account.lastSync != null) ...[
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${'Synced'.tr()} ${_formatTimeAgo(DateTime.tryParse(account.lastSync!) ?? DateTime.now())}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!account.isActive) return Colors.grey;
    switch (account.connectionStatus.toLowerCase()) {
      case 'connected':
      case 'active':
        return Colors.green;
      case 'error':
      case 'failed':
        return Colors.red;
      case 'testing':
      case 'connecting':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountIcon() {
    switch (account.type?.toLowerCase()) {
      case 'gmail':
        return Icons.mail;
      case 'outlook':
      case 'exchange':
        return Icons.corporate_fare;
      case 'imap':
        return Icons.cloud_sync;
      default:
        return Icons.email;
    }
  }

  String _getStatusText() {
    if (!account.isActive) return 'Inactive'.tr();
    switch (account.connectionStatus.toLowerCase()) {
      case 'connected':
      case 'active':
        return 'Connected'.tr();
      case 'error':
      case 'failed':
        return 'Error'.tr();
      case 'testing':
        return 'Testing'.tr();
      case 'connecting':
        return 'Connecting'.tr();
      default:
        return 'Unknown'.tr();
    }
  }

  String _getSyncStatusText() {
    switch (account.syncStatus.toLowerCase()) {
      case 'syncing':
        return 'Syncing...'.tr();
      case 'completed':
        return 'Sync completed'.tr();
      case 'failed':
        return 'Sync failed'.tr();
      case 'never_synced':
        return 'Never synced'.tr();
      default:
        return account.syncStatus.tr();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now'.tr();
    }
  }
}