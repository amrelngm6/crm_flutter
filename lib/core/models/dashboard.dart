import 'lead.dart';

class DashboardData {
  final DashboardStats stats;
  final List<RecentActivity> recentActivities;
  final List<Lead> upcomingFollowUps;
  final List<Task> todayTasks;

  DashboardData({
    required this.stats,
    required this.recentActivities,
    required this.upcomingFollowUps,
    required this.todayTasks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(json['overview'] ?? {}),
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((activity) => RecentActivity.fromJson(activity))
              .toList() ??
          [],
      upcomingFollowUps: (json['upcoming_events'] as List<dynamic>?)
              ?.where((event) => event['type'] == 'task')
              .map((event) => Lead.fromJson({
                    'id': event['id'] ?? 0,
                    'name': event['title'] ?? '',
                    'email': '',
                    'phone': '',
                    'status': 'pending',
                    'created_at':
                        event['start_time'] ?? DateTime.now().toIso8601String(),
                  }))
              .toList() ??
          [],
      todayTasks: (json['upcoming_events'] as List<dynamic>?)
              ?.where((event) => event['type'] == 'task')
              .map((event) => Task.fromJson({
                    'id': event['id'] ?? 0,
                    'title': event['title'] ?? '',
                    'type': event['type'] ?? '',
                    'description': '',
                    'status': 'pending',
                    'priority': 'medium',
                    'due_date': event['start_time'],
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  }))
              .toList() ??
          [],
    );
  }
}

class DashboardStats {
  final int totalClients;
  final int activeLeads;
  final int todayTasks;
  final int upcomingMeetings;
  final double monthlyRevenue;
  final double conversionRate;

  DashboardStats({
    required this.totalClients,
    required this.activeLeads,
    required this.todayTasks,
    required this.upcomingMeetings,
    required this.monthlyRevenue,
    required this.conversionRate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalClients: json['total_clients'] ?? 0,
      activeLeads: json['my_leads'] ?? 0,
      todayTasks: json['my_tasks'] ?? 0,
      upcomingMeetings: json['my_meetings_today'] ?? 0,
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
    );
  }
}

class RecentActivity {
  final int id;
  final String type;
  final String title;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic>? relatedData;

  RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.relatedData,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      relatedData: json['related_data'],
    );
  }
}

class Task {
  final int id;
  final String title;
  final String? description;
  final String? type;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final int? assignedTo;
  final int? relatedClientId;
  final int? relatedLeadId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.type,
    required this.status,
    required this.priority,
    this.dueDate,
    this.assignedTo,
    this.relatedClientId,
    this.relatedLeadId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      assignedTo: json['assigned_to'],
      relatedClientId: json['related_client_id'],
      relatedLeadId: json['related_lead_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  static List<Task> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Task.fromJson(json)).toList();
  }

  // Task status constants
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Task priority constants
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';
}
