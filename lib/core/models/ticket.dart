import 'package:medians_ai_crm/core/constants/app_constants.dart';

class Ticket {
  final int id;
  final String subject;
  final String message;
  final String? dueDate;
  final bool isOverdue;
  final double? daysUntilDue;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketCategory? category;
  final TicketClient? client;
  final TicketModel? model;
  final List<TicketStaff> assignedStaff;
  final TicketCreator creator;
  final TicketComments? comments;
  final TicketTasks? tasks;
  final int businessId;
  final String createdAt;
  final String updatedAt;

  Ticket({
    required this.id,
    required this.subject,
    required this.message,
    required this.dueDate,
    required this.isOverdue,
    required this.daysUntilDue,
    required this.status,
    required this.priority,
    this.category,
    this.client,
    this.model,
    required this.assignedStaff,
    required this.creator,
    this.comments,
    this.tasks,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      dueDate: json['due_date'],
      isOverdue: json['is_overdue'] ?? false,
      daysUntilDue: (json['days_until_due'] is int)
          ? (json['days_until_due'] as int).toDouble()
          : (json['days_until_due'] as num?)?.toDouble(),
      status: TicketStatus.fromJson(json['status'] ?? {}),
      priority: TicketPriority.fromJson(json['priority'] ?? {}),
      category: json['category'] != null
          ? TicketCategory.fromJson(json['category'])
          : null,
      client:
          json['client'] != null ? TicketClient.fromJson(json['client']) : null,
      model: json['model'] != null ? TicketModel.fromJson(json['model']) : null,
      assignedStaff: (json['assigned_staff'] as List?)
              ?.map((e) => TicketStaff.fromJson(e))
              .toList() ??
          [],
      creator: TicketCreator.fromJson(json['creator'] ?? {}),
      comments: json['comments'] != null
          ? TicketComments.fromJson(json['comments'])
          : null,
      tasks: json['tasks'] != null ? TicketTasks.fromJson(json['tasks']) : null,
      businessId: json['business_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Ticket copyWith({
    int? id,
    String? subject,
    String? message,
    String? dueDate,
    bool? isOverdue,
    double? daysUntilDue,
    TicketStatus? status,
    TicketPriority? priority,
    TicketCategory? category,
    TicketClient? client,
    TicketModel? model,
    List<TicketStaff>? assignedStaff,
    TicketCreator? creator,
    TicketComments? comments,
    TicketTasks? tasks,
    int? businessId,
    String? createdAt,
    String? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      dueDate: dueDate ?? this.dueDate,
      isOverdue: isOverdue ?? this.isOverdue,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      client: client ?? this.client,
      model: model ?? this.model,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      creator: creator ?? this.creator,
      comments: comments ?? this.comments,
      tasks: tasks ?? this.tasks,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TicketStatus {
  final int id;
  final String name;
  final String color;

  TicketStatus({required this.id, required this.name, required this.color});

  factory TicketStatus.fromJson(Map<String, dynamic> json) {
    return TicketStatus(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '#6c757d',
    );
  }
}

class TicketPriority {
  final int id;
  final String name;
  final String color;
  final int level;

  TicketPriority(
      {required this.id,
      required this.name,
      required this.color,
      required this.level});

  factory TicketPriority.fromJson(Map<String, dynamic> json) {
    return TicketPriority(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'] ?? '#6c757d',
      level: json['level'] ?? 1,
    );
  }
}

class TicketCategory {
  final int? id;
  final String? name;
  final String? description;

  TicketCategory({this.id, this.name, this.description});

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class TicketClient {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? avatar;

  TicketClient(
      {this.id,
      this.name,
      this.email,
      this.phone,
      this.companyName,
      this.avatar});

  factory TicketClient.fromJson(Map<String, dynamic> json) {
    return TicketClient(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null,
    );
  }
}

class TicketModel {
  final int? id;
  final String? type;
  final String? name;
  final Map<String, dynamic>? details;

  TicketModel({this.id, this.type, this.name, this.details});

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      details: json['details'],
    );
  }
}

class TicketStaff {
  final int? id;
  final String? name;
  final String? email;
  final String? avatar;

  TicketStaff({this.id, this.name, this.email, this.avatar});

  factory TicketStaff.fromJson(Map<String, dynamic> json) {
    return TicketStaff(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null,
    );
  }
}

class TicketCreator {
  final int? id;
  final String? type;
  final String? name;

  TicketCreator({this.id, this.type, this.name});

  factory TicketCreator.fromJson(Map<String, dynamic> json) {
    return TicketCreator(
      id: json['id'],
      type: json['type'],
      name: json['name'],
    );
  }
}

class TicketComments {
  final int count;
  final TicketComment? latest;
  final List<TicketComment>? comments;

  TicketComments({required this.count, this.latest, this.comments});

  factory TicketComments.fromJson(Map<String, dynamic> json) {
    return TicketComments(
      count: json['count'] ?? 0,
      latest: json['latest'] != null
          ? TicketComment.fromJson(json['latest'])
          : null,
      comments: json['data'] != null
          ? List<TicketComment>.from(
              json['data'].map((x) => TicketComment.fromJson(x)))
          : null,
    );
  }
}

class TicketComment {
  final int id;
  final String content;
  final String createdAt;
  final String author;
  final String? avatar;

  TicketComment(
      {required this.id,
      required this.content,
      required this.createdAt,
      required this.author,
      this.avatar});

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'] ?? 0,
      content: json['message'] ?? '',
      createdAt: json['created_at'] ?? '',
      author: json['author'] ?? 'Unknown',
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null, // Default avatar URL
    );
  }
}

class TicketTasks {
  final int count;
  final int completedCount;
  final int pendingCount;

  TicketTasks(
      {required this.count,
      required this.completedCount,
      required this.pendingCount});

  factory TicketTasks.fromJson(Map<String, dynamic> json) {
    return TicketTasks(
      count: json['count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
    );
  }
}
