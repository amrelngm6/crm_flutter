import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<Notification> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _unreadCount = 0;
  Map<dynamic, dynamic> _statistics = {};
  Map<dynamic, dynamic> _pagination = {};

  // Filters
  String _selectedType = '';
  bool? _selectedReadStatus;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Getters
  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  Map<dynamic, dynamic> get statistics => _statistics;
  Map<dynamic, dynamic> get pagination => _pagination;
  String get selectedType => _selectedType;
  bool? get selectedReadStatus => _selectedReadStatus;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;

  // Filtered notifications
  List<Notification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<Notification> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  // Load notifications with optional filters
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _notifications.clear();
    }

    if (_isLoading || (_isLoadingMore && !refresh)) return;

    _setLoading(refresh ? true : false, !refresh);
    _setError(null);

    try {
      final result = await _notificationService.getNotifications(
        page: _currentPage,
        type: _selectedType.isEmpty ? null : _selectedType,
        isRead: _selectedReadStatus,
        search: _searchQuery,
      );

      final newNotifications = result['notifications'] as List<Notification>;

      if (refresh || _currentPage == 1) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _pagination = result['pagination'];
      _unreadCount = result['unread_count'];
      _statistics = result['statistics'];
      _hasMoreData = _pagination['has_more'] ?? false;

      if (_hasMoreData) {
        _currentPage++;
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false, false);
    }
  }

  // Load more notifications (pagination)
  Future<void> loadMore() async {
    if (_hasMoreData && !_isLoadingMore) {
      await loadNotifications();
    }
  }

  // Load notifications with optional filters
  Future<void> loadLatestNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _notifications.clear();
    }

    if (_isLoading || (_isLoadingMore && !refresh)) return;

    _setLoading(refresh ? true : false, !refresh);
    _setError(null);

    try {
      final result = await _notificationService.getNotifications(
        page: _currentPage,
        perPage: 5,
        isRead: false,
        search: _searchQuery,
      );

      final newNotifications = result['notifications'] as List<Notification>;

      if (refresh || _currentPage == 1) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _pagination = result['pagination'];
      _unreadCount = result['unread_count'];
      _statistics = result['statistics'];
      _hasMoreData = _pagination['has_more'] ?? false;

      if (_hasMoreData) {
        _currentPage++;
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false, false);
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _notificationService.getStatistics();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Update local notifications
      _notifications = _notifications
          .map((n) => n.copyWith(
                isRead: true,
                readAt: DateTime.now(),
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Remove from local list
      final notification =
          _notifications.firstWhere((n) => n.id == notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);

      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Bulk delete notifications
  Future<void> bulkDelete(List<int> notificationIds) async {
    try {
      await _notificationService.bulkDelete(notificationIds);

      // Remove from local list
      final deletedUnreadCount = _notifications
          .where((n) => notificationIds.contains(n.id) && !n.isRead)
          .length;

      _notifications.removeWhere((n) => notificationIds.contains(n.id));
      _unreadCount =
          (_unreadCount - deletedUnreadCount).clamp(0, double.infinity).toInt();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Set filters
  void setTypeFilter(String type) {
    if (_selectedType != type) {
      _selectedType = type;
      _resetAndReload();
    }
  }

  void setReadStatusFilter(bool? isRead) {
    if (_selectedReadStatus != isRead) {
      _selectedReadStatus = isRead;
      _resetAndReload();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _resetAndReload();
    }
  }

  // Clear all filters
  void clearFilters() {
    _selectedType = '';
    _selectedReadStatus = null;
    _searchQuery = '';
    _resetAndReload();
  }

  // Reset pagination and reload
  void _resetAndReload() {
    _currentPage = 1;
    _hasMoreData = true;
    loadNotifications(refresh: true);
  }

  // Helper methods
  void _setLoading(bool loading, bool loadingMore) {
    _isLoading = loading;
    _isLoadingMore = loadingMore;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Refresh notifications
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }

  // Get notification by ID
  Notification? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications by type
  List<Notification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Check if there are unread notifications of specific type
  bool hasUnreadOfType(String type) {
    return _notifications.any((n) => n.type == type && !n.isRead);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
