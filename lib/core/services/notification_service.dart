import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medians_ai_crm/core/constants/app_constants.dart';
import '../models/notification.dart';
import 'storage_service.dart';

class NotificationService {
  static String _endpoint = '${AppConstants.baseUrl}/notifications';
  final StorageService _storage = StorageService();

  // Get headers with authorization token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all notifications with pagination and filters
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
    String? type,
    bool? isRead,
    String search = '',
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      if (isRead != null) {
        queryParams['unread_only'] = isRead ? 'false' : 'true';
      }

      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(_endpoint).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];
          final notifications = (responseData['notifications'] as List)
              .map((item) => Notification.fromJson(item))
              .toList();

          final pagination = responseData['pagination'] ?? {};

          return {
            'notifications': notifications,
            'pagination': {
              'current_page': pagination['current_page'] ?? 1,
              'total': pagination['total'] ?? 0,
              'per_page': pagination['per_page'] ?? 20,
              'last_page': pagination['last_page'] ?? 1,
              'has_more': (pagination['current_page'] ?? 1) <
                  (pagination['last_page'] ?? 1),
            },
            'unread_count': responseData['unread_count'] ?? 0,
            'statistics': responseData['statistics'] ?? {},
          };
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_endpoint/statistics'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint/$notificationId/mark-read'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ??
            'Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint/mark-all-read'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ??
            'Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_endpoint/$notificationId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ??
            'Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Bulk delete notifications
  Future<void> bulkDelete(List<int> notificationIds) async {
    try {
      final response = await http.delete(
        Uri.parse('$_endpoint/bulk-delete'),
        headers: await _getHeaders(),
        body: json.encode({
          'notification_ids': notificationIds,
        }),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ??
            'Failed to bulk delete notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error bulk deleting notifications: $e');
    }
  }

  // Create notification (admin only)
  Future<Notification> createNotification({
    required String title,
    required String content,
    required String type,
    String priority = 'normal',
    Map<String, dynamic>? actionData,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'content': content,
          'type': type,
          'priority': priority,
          'action_data': actionData,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Notification.fromJson(data['notification']);
      } else {
        throw Exception(
            'Failed to create notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  // Get notification types
  List<String> getNotificationTypes() {
    return [
      'system',
      'task',
      'meeting',
      'lead',
      'deal',
      'client',
      'urgent',
      'general',
    ];
  }

  // Get notification priorities
  List<String> getNotificationPriorities() {
    return [
      'low',
      'normal',
      'high',
      'urgent',
    ];
  }
}
