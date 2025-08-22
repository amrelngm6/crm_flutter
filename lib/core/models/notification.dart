import 'package:flutter/material.dart';

class Notification {
  final int id;
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? actionData;
  final String? imageUrl;
  final String priority;

  Notification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.actionData,
    this.imageUrl,
    this.priority = 'normal',
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      imageUrl: json['image_url'],
      priority: json['priority'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'action_data': actionData,
      'image_url': imageUrl,
      'priority': priority,
    };
  }

  Notification copyWith({
    int? id,
    String? title,
    String? content,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? actionData,
    String? imageUrl,
    String? priority,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionData: actionData ?? this.actionData,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
    );
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today at ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(createdAt.weekday)} at ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  // Get priority color
  static getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return const Color(0xFF607D8B);
      case 'task':
        return const Color(0xFF2196F3);
      case 'meeting':
        return const Color(0xFFFF9800);
      case 'lead':
        return const Color(0xFF4CAF50);
      case 'deal':
        return const Color(0xFF9C27B0);
      case 'client':
        return const Color(0xFF00BCD4);
      case 'invoice':
        return const Color.fromARGB(255, 248, 107, 159);
      case 'proposal':
        return const Color(0xFFF44336);
      case 'estimate':
        return const Color.fromARGB(255, 18, 96, 84);
      case 'ticket':
        return const Color.fromARGB(255, 61, 69, 89);
      default:
        return const Color(0xFF757575);
    }
  }

  // Get priority icon
  static getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return Icons.settings;
      case 'task':
        return Icons.task_alt;
      case 'meeting':
        return Icons.event;
      case 'lead':
        return Icons.person_add;
      case 'ticket':
        return Icons.support_agent;
      case 'deal':
        return Icons.handshake;
      case 'estimate':
      case 'proposal':
        return Icons.picture_as_pdf;
      case 'invoice':
        return Icons.payments;
      default:
        return Icons.notifications;
    }
  }
}
