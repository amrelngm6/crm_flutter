class Todo {
  final int id;
  final String description;
  final String? date;
  final int sort;
  final bool isCompleted;
  final int statusId;
  final String? finishedTime;
  final CompletionStatus completionStatus;
  final DateInfo dateInfo;
  final TodoPriority? priority;
  final TodoUser user;
  final int businessId;
  final String? createdAt;
  final String? updatedAt;

  Todo({
    required this.id,
    required this.description,
    this.date,
    required this.sort,
    required this.isCompleted,
    required this.statusId,
    this.finishedTime,
    required this.completionStatus,
    required this.dateInfo,
    this.priority,
    required this.user,
    required this.businessId,
    this.createdAt,
    this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      date: json['date'],
      sort: json['sort'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      statusId: json['status_id'] ?? 0,
      finishedTime: json['finished_time'],
      completionStatus:
          CompletionStatus.fromJson(json['completion_status'] ?? {}),
      dateInfo: DateInfo.fromJson(json['date_info'] ?? {}),
      priority: json['priority'] != null
          ? TodoPriority.fromJson(json['priority'])
          : null,
      user: TodoUser.fromJson(json['user'] ?? {}),
      businessId: json['business_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'date': date,
      'sort': sort,
      'is_completed': isCompleted,
      'status_id': statusId,
      'finished_time': finishedTime,
      'completion_status': completionStatus.toJson(),
      'date_info': dateInfo.toJson(),
      'priority': priority?.toJson(),
      'user': user.toJson(),
      'business_id': businessId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Todo copyWith({
    int? id,
    String? description,
    String? date,
    int? sort,
    bool? isCompleted,
    int? statusId,
    String? finishedTime,
    CompletionStatus? completionStatus,
    DateInfo? dateInfo,
    TodoPriority? priority,
    TodoUser? user,
    int? businessId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      description: description ?? this.description,
      date: date ?? this.date,
      sort: sort ?? this.sort,
      isCompleted: isCompleted ?? this.isCompleted,
      statusId: statusId ?? this.statusId,
      finishedTime: finishedTime ?? this.finishedTime,
      completionStatus: completionStatus ?? this.completionStatus,
      dateInfo: dateInfo ?? this.dateInfo,
      priority: priority ?? this.priority,
      user: user ?? this.user,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CompletionStatus {
  final bool isCompleted;
  final String? completedAt;
  final String statusText;

  CompletionStatus({
    required this.isCompleted,
    this.completedAt,
    required this.statusText,
  });

  factory CompletionStatus.fromJson(Map<String, dynamic> json) {
    return CompletionStatus(
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'],
      statusText: json['status_text'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_completed': isCompleted,
      'completed_at': completedAt,
      'status_text': statusText,
    };
  }
}

class DateInfo {
  final String? date;
  final bool isToday;
  final bool isOverdue;
  final bool isThisWeek;
  final double? daysUntilDue;
  final String? formattedDate;

  DateInfo({
    this.date,
    required this.isToday,
    required this.isOverdue,
    required this.isThisWeek,
    this.daysUntilDue,
    this.formattedDate,
  });

  factory DateInfo.fromJson(Map<String, dynamic> json) {
    return DateInfo(
      date: json['date'],
      isToday: json['is_today'] ?? false,
      isOverdue: json['is_overdue'] ?? false,
      isThisWeek: json['is_this_week'] ?? false,
      daysUntilDue: json['days_until_due']?.toDouble(),
      formattedDate: json['formatted_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'is_today': isToday,
      'is_overdue': isOverdue,
      'is_this_week': isThisWeek,
      'days_until_due': daysUntilDue,
      'formatted_date': formattedDate,
    };
  }
}

class TodoPriority {
  final int? id;
  final String name;
  final String color;
  final int level;
  final int sort;

  TodoPriority({
    this.id,
    required this.name,
    required this.color,
    required this.level,
    required this.sort,
  });

  factory TodoPriority.fromJson(Map<String, dynamic> json) {
    return TodoPriority(
      id: json['id'],
      name: json['name'] ?? 'Normal',
      color: json['color'] ?? '#6c757d',
      level: json['level'] ?? 1,
      sort: json['sort'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'level': level,
      'sort': sort,
    };
  }
}

class TodoUser {
  final int? id;
  final String? type;
  final String name;
  final TodoUserDetails? details;

  TodoUser({
    this.id,
    this.type,
    required this.name,
    this.details,
  });

  factory TodoUser.fromJson(Map<String, dynamic> json) {
    return TodoUser(
      id: json['id'],
      type: json['type'],
      name: json['name'] ?? 'Unknown User',
      details: json['details'] != null
          ? TodoUserDetails.fromJson(json['details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'details': details?.toJson(),
    };
  }
}

class TodoUserDetails {
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? avatar;

  TodoUserDetails({
    this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.avatar,
  });

  factory TodoUserDetails.fromJson(Map<String, dynamic> json) {
    return TodoUserDetails(
      name: json['name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'avatar': avatar,
    };
  }
}

class TodoStatistics {
  final TodoOverview overview;
  final List<PriorityBreakdown> priorityBreakdown;
  final List<DailyTrend> dailyTrends;

  TodoStatistics({
    required this.overview,
    required this.priorityBreakdown,
    required this.dailyTrends,
  });

  factory TodoStatistics.fromJson(Map<String, dynamic> json) {
    return TodoStatistics(
      overview: TodoOverview.fromJson(json['overview'] ?? {}),
      priorityBreakdown: (json['priority_breakdown'] as List?)
              ?.map((item) => PriorityBreakdown.fromJson(item))
              .toList() ??
          [],
      dailyTrends: (json['daily_trends'] as List?)
              ?.map((item) => DailyTrend.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class TodoOverview {
  final int totalTodos;
  final int completedTodos;
  final int pendingTodos;
  final int overdueTodos;
  final int todayTodos;
  final int thisWeekTodos;
  final double completionRate;

  TodoOverview({
    required this.totalTodos,
    required this.completedTodos,
    required this.pendingTodos,
    required this.overdueTodos,
    required this.todayTodos,
    required this.thisWeekTodos,
    required this.completionRate,
  });

  factory TodoOverview.fromJson(Map<String, dynamic> json) {
    return TodoOverview(
      totalTodos: json['total_todos'] ?? 0,
      completedTodos: json['completed_todos'] ?? 0,
      pendingTodos: json['pending_todos'] ?? 0,
      overdueTodos: json['overdue_todos'] ?? 0,
      todayTodos: json['today_todos'] ?? 0,
      thisWeekTodos: json['this_week_todos'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
    );
  }
}

class PriorityBreakdown {
  final String priorityName;
  final String color;
  final int count;

  PriorityBreakdown({
    required this.priorityName,
    required this.color,
    required this.count,
  });

  factory PriorityBreakdown.fromJson(Map<String, dynamic> json) {
    return PriorityBreakdown(
      priorityName: json['priority_name'] ?? '',
      color: json['color'] ?? '#6c757d',
      count: json['count'] ?? 0,
    );
  }
}

class DailyTrend {
  final String date;
  final int completed;

  DailyTrend({
    required this.date,
    required this.completed,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'] ?? '',
      completed: json['completed'] ?? 0,
    );
  }
}
