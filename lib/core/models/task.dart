class Task {
  final int id;
  final String name;
  final String? description;
  final TaskPriority? priority;
  final TaskStatus? status;
  final int? progress;
  final TaskDates? dates;
  final TaskModel? model;
  final TaskProject? project;
  final List<TaskTeamMember> team;
  final TaskChecklist? checklist;
  final int commentsCount;
  final TaskTimesheets? timesheets;
  final TaskSettings? settings;
  final int businessId;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.name,
    this.description,
    required this.priority,
    required this.status,
    required this.progress,
    required this.dates,
    this.model,
    this.project,
    required this.team,
    this.checklist,
    required this.commentsCount,
    this.timesheets,
    this.settings,
    required this.businessId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      priority: json['priority'] != null
          ? TaskPriority.fromJson(json['priority'])
          : null,
      status:
          json['status'] != null ? TaskStatus.fromJson(json['status']) : null,
      progress: json['progress'] is int
          ? json['progress']
          : (int.tryParse(json['progress']?.toString() ?? '') ?? 0),
      dates: json['dates'] != null ? TaskDates.fromJson(json['dates']) : null,
      model: json['model'] != null ? TaskModel.fromJson(json['model']) : null,
      project: json['project'] != null
          ? TaskProject.fromJson(json['project'])
          : null,
      team: _parseTeamList(json['team']),
      checklist: json['checklist'] != null
          ? TaskChecklist.fromJson(json['checklist'])
          : null,
      commentsCount: json['comments_count'] is int
          ? json['comments_count']
          : (int.tryParse(json['comments_count']?.toString() ?? '') ?? 0),
      timesheets: json['timesheets'] != null
          ? TaskTimesheets.fromJson(json['timesheets'])
          : null,
      settings: json['settings'] != null
          ? TaskSettings.fromJson(json['settings'])
          : null,
      businessId: json['business_id'] is int
          ? json['business_id']
          : (int.tryParse(json['business_id']?.toString() ?? '') ?? 0),
      createdBy: json['created_by'] is int
          ? json['created_by']
          : (json['created_by'] != null
              ? int.tryParse(json['created_by'].toString())
              : null),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  // Helper method to parse team list
  static List<TaskTeamMember> _parseTeamList(dynamic teamData) {
    if (teamData == null) return [];
    if (teamData is List) {
      return teamData
          .map((e) =>
              TaskTeamMember.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return [];
  }

  // Helper method to parse DateTime
  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is String) {
      return DateTime.tryParse(dateData) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priority': priority?.toJson(),
      'status': status?.toJson(),
      'progress': progress,
      'dates': dates?.toJson(),
      'model': model?.toJson(),
      'project': project?.toJson(),
      'team': team.map((e) => e.toJson()).toList(),
      'checklist': checklist?.toJson(),
      'comments_count': commentsCount,
      'timesheets': timesheets?.toJson(),
      'business_id': businessId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get statusName => status?.name ?? 'Unknown';
  String get statusColor => status?.color ?? '#6c757d';
  String get priorityName => priority?.name ?? 'No Priority';
  String get priorityColor => priority?.color ?? '#6c757d';
  bool get isOverdue => dates?.isOverdue ?? false;
  int? get daysUntilDue => dates?.daysUntilDue;
  bool get isCompleted => (progress ?? 0) >= 100;
  String get progressText => '${progress ?? 0}%';

  String get assignedToNames {
    if (team.isEmpty) return 'Unassigned';
    return team.map((member) => member.name).join(', ');
  }

  String get timeRemaining {
    if (dates?.daysUntilDue == null) return 'No due date';
    if (dates?.isOverdue == true) return 'Overdue';
    final days = dates?.daysUntilDue ?? 0;
    if (days == 0) return 'Due today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }
}

class TaskPriority {
  final int id;
  final String name;
  final String color;
  final int? sort;

  TaskPriority({
    required this.id,
    required this.name,
    required this.color,
    this.sort,
  });

  factory TaskPriority.fromJson(Map<String, dynamic> json) {
    return TaskPriority(
        id: json['id'] is int
            ? json['id']
            : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
        name: json['name']?.toString() ?? 'Normal',
        color: json['color']?.toString() ?? '#6c757d');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'sort': sort,
    };
  }
}

class TaskStatus {
  final int id;
  final String name;
  final String color;

  TaskStatus({
    required this.id,
    required this.name,
    required this.color,
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    print(json);
    return TaskStatus(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? 'Unknown',
      color: json['color']?.toString() ?? '#6c757d',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}

class TaskDates {
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? finishedDate;
  final bool isOverdue;
  final int? daysUntilDue;

  TaskDates({
    this.startDate,
    this.dueDate,
    this.finishedDate,
    required this.isOverdue,
    this.daysUntilDue,
  });

  factory TaskDates.fromJson(Map<String, dynamic> json) {
    return TaskDates(
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      finishedDate: json['finished_date'] != null
          ? DateTime.tryParse(json['finished_date'].toString())
          : null,
      isOverdue: json['is_overdue'] == true || json['is_overdue'] == 'true',
      daysUntilDue: json['days_until_due'] is int
          ? json['days_until_due']
          : (json['days_until_due'] != null
              ? int.tryParse(json['days_until_due'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'finished_date': finishedDate?.toIso8601String(),
      'is_overdue': isOverdue,
      'days_until_due': daysUntilDue,
    };
  }
}

class TaskModel {
  final int id;
  final String type;
  final String? name;

  TaskModel({
    required this.id,
    required this.type,
    this.name,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
    };
  }
}

class TaskProject {
  final int id;
  final String? name;

  TaskProject({
    required this.id,
    this.name,
  });

  factory TaskProject.fromJson(Map<String, dynamic> json) {
    return TaskProject(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class TaskTeamMember {
  final int id;
  final String userType;
  final String name;
  final String? email;
  final String? avatar;

  TaskTeamMember({
    required this.id,
    required this.userType,
    required this.name,
    this.email,
    this.avatar,
  });

  factory TaskTeamMember.fromJson(Map<String, dynamic> json) {
    return TaskTeamMember(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userType: json['user_type']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_type': userType,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}

class TaskChecklist {
  final List<TaskChecklistItem> items;
  final int totalItems;
  final int completedItems;
  final int progressPercentage;

  TaskChecklist({
    required this.items,
    required this.totalItems,
    required this.completedItems,
    required this.progressPercentage,
  });

  factory TaskChecklist.fromJson(Map<String, dynamic> json) {
    List<TaskChecklistItem> parseItems(dynamic itemsData) {
      if (itemsData == null) return [];
      if (itemsData is List) {
        return itemsData
            .map((e) =>
                TaskChecklistItem.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    }

    return TaskChecklist(
      items: parseItems(json['items']),
      totalItems: json['total_items'] is int
          ? json['total_items']
          : (int.tryParse(json['total_items']?.toString() ?? '') ?? 0),
      completedItems: json['completed_items'] is int
          ? json['completed_items']
          : (int.tryParse(json['completed_items']?.toString() ?? '') ?? 0),
      progressPercentage: json['progress_percentage'] is int
          ? json['progress_percentage']
          : (int.tryParse(json['progress_percentage']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total_items': totalItems,
      'completed_items': completedItems,
      'progress_percentage': progressPercentage,
    };
  }
}

class TaskChecklistItem {
  final int id;
  final String description;
  bool finished;
  final DateTime? finishedDate;
  final int points;
  final int sort;
  final bool visibleToClient;
  final String status;
  final int? userId;

  TaskChecklistItem({
    required this.id,
    required this.description,
    required this.finished,
    this.finishedDate,
    required this.points,
    required this.sort,
    required this.visibleToClient,
    required this.status,
    this.userId,
  });

  factory TaskChecklistItem.fromJson(Map<String, dynamic> json) {
    return TaskChecklistItem(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      description: json['description']?.toString() ?? '',
      finished: json['finished'] != 0,
      finishedDate: json['finished_date'] != null
          ? DateTime.tryParse(json['finished_date'].toString())
          : null,
      points: json['points'] is int
          ? json['points']
          : (int.tryParse(json['points']?.toString() ?? '') ?? 0),
      sort: json['sort'] is int
          ? json['sort']
          : (int.tryParse(json['sort']?.toString() ?? '') ?? 0),
      visibleToClient: json['visible_to_client'] == true ||
          json['visible_to_client'] == 'true',
      status: json['status']?.toString() ?? '0',
      userId: json['user_id'] is int
          ? json['user_id']
          : (json['user_id'] != null
              ? int.tryParse(json['user_id'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'finished': finished,
      'finished_date': finishedDate?.toIso8601String(),
      'points': points,
      'sort': sort,
      'visible_to_client': visibleToClient,
      'status': status,
      'user_id': userId,
    };
  }
}

class TaskTimesheets {
  final int count;
  final double totalHours;

  TaskTimesheets({
    required this.count,
    required this.totalHours,
  });

  factory TaskTimesheets.fromJson(Map<String, dynamic> json) {
    return TaskTimesheets(
      count: json['count'] is int
          ? json['count']
          : (int.tryParse(json['count']?.toString() ?? '') ?? 0),
      totalHours: json['total_hours'] is num
          ? (json['total_hours'] as num).toDouble()
          : (double.tryParse(json['total_hours']?.toString() ?? '') ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'total_hours': totalHours,
    };
  }
}

class TaskSettings {
  final bool isPublic;
  final bool isPaid;
  final bool visibleToClient;
  final int points;
  final int sort;

  TaskSettings({
    required this.isPublic,
    required this.isPaid,
    required this.visibleToClient,
    required this.points,
    required this.sort,
  });

  factory TaskSettings.fromJson(Map<String, dynamic> json) {
    return TaskSettings(
      isPublic: json['is_public'] == true || json['is_public'] == 'true',
      isPaid: json['is_paid'] == true || json['is_paid'] == 'true',
      visibleToClient: json['visible_to_client'] == true ||
          json['visible_to_client'] == 'true',
      points: json['points'] is int
          ? json['points']
          : (int.tryParse(json['points']?.toString() ?? '') ?? 0),
      sort: json['sort'] is int
          ? json['sort']
          : (int.tryParse(json['sort']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_public': isPublic,
      'is_paid': isPaid,
      'visible_to_client': visibleToClient,
      'points': points,
      'sort': sort,
    };
  }
}
