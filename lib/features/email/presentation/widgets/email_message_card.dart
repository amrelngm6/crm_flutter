import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/models/email_message.dart';

class EmailMessageCard extends StatelessWidget {
  final EmailMessage message;
  final VoidCallback? onTap;

  const EmailMessageCard({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isRead ? Colors.white : Colors.blue.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isRead ? Colors.grey[200]! : Colors.blue.withValues(alpha: 0.2),
          width: message.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Sender info and time
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSenderColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      message.senderInfo.initials.isNotEmpty 
                          ? message.senderInfo.initials 
                          : message.fromName.isNotEmpty 
                              ? message.fromName.substring(0, 1).toUpperCase()
                              : message.fromEmail.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: _getSenderColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.senderInfo.displayName.isNotEmpty 
                                  ? message.senderInfo.displayName 
                                  : message.fromName.isNotEmpty 
                                      ? message.fromName 
                                      : message.fromEmail,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: message.isRead ? FontWeight.w500 : FontWeight.w700,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message.relativeTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.fromEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subject
            Text(
              message.subject.isNotEmpty ? message.subject : 'No Subject'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: message.isRead ? FontWeight.w500 : FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Snippet/Preview
            if (message.snippet.isNotEmpty) ...[
              Text(
                message.snippet,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],

            // Bottom row: Recipients, attachments, labels
            Row(
              children: [
                // To recipients
                if (message.toEmail != null && message.toEmail!.isNotEmpty) ...[
                  Icon(
                    Icons.send,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'To: ${message.toName?.isNotEmpty == true ? message.toName : message.toEmail}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Status indicators
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Attachment indicator
                    if (message.hasAttachments) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      if (message.attachmentsCount > 1)
                        Text(
                          message.attachmentsCount.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],

                    // Star indicator
                    if (message.isStarred) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],

                    // Priority indicator
                    if (message.priority != null && message.priority!.toLowerCase() == 'high') ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.priority_high,
                        size: 16,
                        color: Colors.red,
                      ),
                    ],

                    // Unread indicator
                    if (!message.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Labels
            if (message.labels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: message.labels.take(3).map((label) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getLabelColor(label).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getLabelColor(label),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSenderColor() {
    // Generate a color based on sender email
    final hash = message.fromEmail.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getLabelColor(String label) {
    switch (label.toLowerCase()) {
      case 'important':
        return Colors.red;
      case 'work':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'urgent':
        return Colors.orange;
      case 'inbox':
        return Colors.grey;
      case 'sent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}