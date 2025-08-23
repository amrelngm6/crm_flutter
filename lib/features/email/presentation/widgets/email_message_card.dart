import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/email_message.dart';

class EmailMessageCard extends StatelessWidget {
  final EmailMessage message;
  final VoidCallback onTap;
  final VoidCallback onStar;
  final VoidCallback onRead;

  const EmailMessageCard({
    super.key,
    required this.message,
    required this.onTap,
    required this.onStar,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: message.isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: message.isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildSubject(),
                    const SizedBox(height: 4),
                    _buildSnippet(),
                    const SizedBox(height: 8),
                    _buildFooter(),
                  ],
                ),
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getAvatarColor(),
      child: Text(
        message.senderInfo.initials.isNotEmpty
            ? message.senderInfo.initials
            : message.senderInfo.name.isNotEmpty
                ? message.senderInfo.name[0].toUpperCase()
                : '?',
        style: const TextStyle(
          color: Colors.white,
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
    
    final index = message.senderInfo.email.hashCode % colors.length;
    return colors[index.abs()];
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            message.senderInfo.displayName.isNotEmpty
                ? message.senderInfo.displayName
                : message.senderInfo.name.isNotEmpty
                    ? message.senderInfo.name
                    : message.senderInfo.email,
            style: TextStyle(
              fontSize: 14,
              fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
              color: message.isRead ? Colors.grey[700] : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          message.relativeTime.isNotEmpty
              ? message.relativeTime
              : _formatDate(message.date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSubject() {
    return Text(
      message.subject.isNotEmpty ? message.subject : tr('(No Subject)'),
      style: TextStyle(
        fontSize: 16,
        fontWeight: message.isRead ? FontWeight.w500 : FontWeight.bold,
        color: message.isRead ? Colors.grey[800] : Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSnippet() {
    if (message.snippet.isEmpty) return const SizedBox.shrink();
    
    return Text(
      message.snippet,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (message.hasAttachments) ...[
          Icon(
            Icons.attach_file,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '${message.attachmentsCount}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (message.priority != null && message.priority!.toLowerCase() == 'high')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              tr('High'),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const Spacer(),
        if (message.isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              tr('Today'),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        IconButton(
          onPressed: onStar,
          icon: Icon(
            message.isStarred ? Icons.star : Icons.star_border,
            color: message.isStarred ? Colors.amber : Colors.grey[400],
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        if (message.isRecent && !message.isRead)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    
    try {
      final dateTime = DateTime.parse(date);
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
      return date;
    }
  }
}