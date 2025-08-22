import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  static final DashboardProvider _instance = DashboardProvider._internal();
  factory DashboardProvider() => _instance;
  DashboardProvider._internal();

  final ApiService _apiService = ApiService();

  // Dashboard state
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  // Helper getters for individual stats
  int get totalClients => _dashboardData?.stats.totalClients ?? 0;
  int get activeLeads => _dashboardData?.stats.activeLeads ?? 0;
  int get todayTasks => _dashboardData?.stats.todayTasks ?? 0;
  int get upcomingMeetings => _dashboardData?.stats.upcomingMeetings ?? 0;
  double get monthlyRevenue => _dashboardData?.stats.monthlyRevenue ?? 0.0;
  double get conversionRate => _dashboardData?.stats.conversionRate ?? 0.0;

  List<RecentActivity> get recentActivities =>
      _dashboardData?.recentActivities ?? [];
  List<Task> get todayTasksList => _dashboardData?.todayTasks ?? [];

  // Load dashboard data from API
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    // Check if we need to refresh
    if (!forceRefresh && _dashboardData != null && _lastUpdated != null) {
      final difference = DateTime.now().difference(_lastUpdated!);
      if (difference.inMinutes < 5) {
        // Data is fresh, no need to reload
        return;
      }
    }

    try {
      _setLoading(true);
      _setError(null);

      // Call the API
      final response = await _apiService.getDashboardData();

      // Parse the response
      if (response['success'] == true && response['data'] != null) {
        _dashboardData = DashboardData.fromJson(response['data']);
        _lastUpdated = DateTime.now();
        _setError(null);
      } else {
        throw Exception(response['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      _setError(e.toString());
      // Use mock data if API fails in development
    } finally {
      _setLoading(false);
    }
  }

  // Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData(forceRefresh: true);
  }

  // Clear dashboard data
  void clearDashboard() {
    _dashboardData = null;
    _error = null;
    _lastUpdated = null;
    notifyListeners();
  }

  // Helper methods to update state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Format currency
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  // Format percentage
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Get activity icon based on type
  IconData getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'client':
        return Icons.person_add;
      case 'lead':
        return Icons.trending_up;
      case 'task':
        return Icons.task_alt;
      case 'meeting':
        return Icons.event;
      default:
        return Icons.info;
    }
  }

  // Get activity color based on type
  Color getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'client':
        return const Color(0xFF52D681);
      case 'lead':
        return const Color(0xFF2196F3);
      case 'task':
        return const Color(0xFFFF9800);
      case 'meeting':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  // Get priority color for tasks
  Color getTaskPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Format time ago
  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}
