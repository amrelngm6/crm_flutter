import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/email_account.dart';

class EmailAccountCard extends StatelessWidget {
  final EmailAccount account;
  final VoidCallback onTap;

  const EmailAccountCard({
    super.key,
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStats(),
              const SizedBox(height: 16),
              _buildStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name.isNotEmpty ? account.name : account.email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                account.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (account.type != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    account.type!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildConnectionStatus(),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 25,
      backgroundColor: _getAvatarColor(),
      child: Text(
        account.name.isNotEmpty
            ? account.name[0].toUpperCase()
            : account.email[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    final colors = [
      const Color(0xFF1B4D3E),
      const Color(0xFF2D6A4F),
      const Color(0xFF40916C),
      const Color(0xFF9C27B0),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFF44336),
    ];
    
    final index = account.email.hashCode % colors.length;
    return colors[index.abs()];
  }

  Widget _buildConnectionStatus() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (account.connectionStatus.toLowerCase()) {
      case 'connected':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = tr('Connected');
        break;
      case 'connecting':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = tr('Connecting');
        break;
      case 'disconnected':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = tr('Disconnected');
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = tr('Unknown');
    }

    return Column(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.email,
            label: tr('Total'),
            value: '${account.stats.totalMessages}',
            color: const Color(0xFF1B4D3E),
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.mark_email_unread,
            label: tr('Unread'),
            value: '${account.stats.unreadMessages}',
            color: const Color(0xFFFF9800),
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.access_time,
            label: tr('Recent'),
            value: '${account.stats.recentMessages}',
            color: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (account.isDefault)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.3)),
            ),
            child: Text(
              tr('Default Account'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1B4D3E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.sync,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              tr('Last sync: '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              account.lastSync != null
                  ? _formatLastSync(account.lastSync!)
                  : tr('Never'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (account.syncError != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: Colors.red[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.syncError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatLastSync(String lastSync) {
    try {
      final dateTime = DateTime.parse(lastSync);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return tr('Just now');
          }
          return tr('${difference.inMinutes}m ago');
        }
        return tr('${difference.inHours}h ago');
      } else if (difference.inDays == 1) {
        return tr('Yesterday');
      } else if (difference.inDays < 7) {
        return tr('${difference.inDays}d ago');
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return lastSync;
    }
  }
}