import 'package:flutter/material.dart';
import '../../../core/models/chat.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isLastMessage;
  final bool showSender;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
    this.showSender = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOwnMessage = _isOwnMessage();

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastMessage ? 8 : 4,
        top: showSender ? 8 : 2,
      ),
      child: Column(
        crossAxisAlignment:
            isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSender && !isOwnMessage) _buildSenderInfo(),
          Row(
            mainAxisAlignment:
                isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOwnMessage) _buildAvatar(),
              _buildMessageContent(isOwnMessage),
              if (isOwnMessage) _buildMessageStatus(),
            ],
          ),
        ],
      ),
    );
  }

  bool _isOwnMessage() {
    // TODO: Get current user ID from auth provider
    // For now, assume messages from user ID 1 are own messages
    return message.userId == 1;
  }

  Widget _buildSenderInfo() {
    return Padding(
      padding: const EdgeInsets.only(left: 50, bottom: 4),
      child: Text(
        message.user?.name ?? 'Unknown User',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1B4D3E),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF52D681),
        backgroundImage: message.user?.avatar?.isNotEmpty == true
            ? NetworkImage(message.user!.avatar!)
            : null,
        child: message.user?.avatar?.isEmpty != false
            ? Text(
                message.user?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMessageContent(bool isOwnMessage) {
    return Flexible(
      child: LayoutBuilder(
        builder: (context, constraints) => Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * 0.7,
          ),
          margin: EdgeInsets.only(
            left: isOwnMessage ? 40 : 0,
            right: isOwnMessage ? 0 : 40,
          ),
          child: Column(
            crossAxisAlignment: isOwnMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isOwnMessage
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF52D681),
                            Color(0xFF1B4D3E),
                          ],
                        )
                      : null,
                  color: isOwnMessage ? null : Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isOwnMessage ? 20 : 4),
                    bottomRight: Radius.circular(isOwnMessage ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isOwnMessage ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    if (message.files.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...message.files.map(
                          (file) => _buildFileAttachment(file, isOwnMessage)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              _buildMessageTime(isOwnMessage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAttachment(MessageFile file, bool isOwnMessage) {
    final isImage = file.mimeType.startsWith('image/');

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOwnMessage
            ? Colors.white.withValues(alpha: 0.2)
            : const Color(0xFF52D681).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImage ? Icons.image : Icons.attach_file,
            size: 16,
            color: isOwnMessage ? Colors.white : const Color(0xFF52D681),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              file.fileName,
              style: TextStyle(
                color: isOwnMessage ? Colors.white : const Color(0xFF1B4D3E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTime(bool isOwnMessage) {
    return Text(
      _formatMessageTime(),
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildMessageStatus() {
    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: 4),
      child: Icon(
        // For now, just show delivered status
        Icons.done,
        size: 16,
        color: Colors.grey[500],
      ),
    );
  }

  String _formatMessageTime() {
    if (message.createdAt == null) return '';

    try {
      final messageTime = DateTime.parse(message.createdAt!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate =
          DateTime(messageTime.year, messageTime.month, messageTime.day);

      if (messageDate == today) {
        // Today: show time only
        return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        // Yesterday
        return 'Yesterday ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      } else if (now.difference(messageTime).inDays < 7) {
        // This week: show day name
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return '${weekdays[messageTime.weekday - 1]} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      } else {
        // Older: show date
        return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
