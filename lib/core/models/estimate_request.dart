import 'package:flutter/material.dart';

class EstimateRequest {
  final int id;
  final String message;
  final String? date;
  final String? estimatedBudget;
  final String? timeframe;
  final String? projectType;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? companyName;
  final String userType;
  final int? userId;
  final EstimateRequestStatus status;
  final EstimateRequestStaff? assignedStaff;
  final EstimateRequestUser? user;
  final EstimateRequestEstimate? estimate;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? internalNotes;
  final String priority;
  final String? source;
  final bool isUrgent;
  final bool hasFollowUp;
  final String? followUpDate;
  final int businessId;
  final DateTime createdAt;
  final DateTime updatedAt;

  EstimateRequest({
    required this.id,
    required this.message,
    this.date,
    this.estimatedBudget,
    this.timeframe,
    this.projectType,
    this.contactPerson,
    this.email,
    this.phone,
    this.companyName,
    required this.userType,
    this.userId,
    required this.status,
    this.assignedStaff,
    this.user,
    this.estimate,
    required this.customFields,
    this.notes,
    this.internalNotes,
    required this.priority,
    this.source,
    required this.isUrgent,
    required this.hasFollowUp,
    this.followUpDate,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EstimateRequest.fromJson(Map<String, dynamic> json) {
    return EstimateRequest(
      id: json['id'] ?? 0,
      message: json['message'] ?? '',
      date: json['date'],
      estimatedBudget: json['estimated_budget'],
      timeframe: json['timeframe'],
      projectType: json['project_type'],
      contactPerson: json['contact_person'],
      email: json['email'],
      phone: json['phone'],
      companyName: json['company_name'],
      userType: json['user_type'] ?? 'client',
      userId: json['user_id'],
      status: EstimateRequestStatus.fromJson(json['status'] ?? {}),
      assignedStaff: json['assigned_staff'] != null 
          ? EstimateRequestStaff.fromJson(json['assigned_staff']) 
          : null,
      user: json['user'] != null 
          ? EstimateRequestUser.fromJson(json['user']) 
          : null,
      estimate: json['estimate'] != null 
          ? EstimateRequestEstimate.fromJson(json['estimate']) 
          : null,
      customFields: Map<String, dynamic>.from(json['custom_fields'] ?? {}),
      notes: json['notes'],
      internalNotes: json['internal_notes'],
      priority: json['priority'] ?? 'medium',
      source: json['source'],
      isUrgent: json['is_urgent'] ?? false,
      hasFollowUp: json['has_follow_up'] ?? false,
      followUpDate: json['follow_up_date'],
      businessId: json['business_id'] ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

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
      'message': message,
      'date': date,
      'estimated_budget': estimatedBudget,
      'timeframe': timeframe,
      'project_type': projectType,
      'contact_person': contactPerson,
      'email': email,
      'phone': phone,
      'company_name': companyName,
      'user_type': userType,
      'user_id': userId,
      'status': status.toJson(),
      'assigned_staff': assignedStaff?.toJson(),
      'user': user?.toJson(),
      'estimate': estimate?.toJson(),
      'custom_fields': customFields,
      'notes': notes,
      'internal_notes': internalNotes,
      'priority': priority,
      'source': source,
      'is_urgent': isUrgent,
      'has_follow_up': hasFollowUp,
      'follow_up_date': followUpDate,
      'business_id': businessId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get formattedBudget {
    if (estimatedBudget == null) return 'Not specified';
    return '\$${estimatedBudget}';
  }

  String get statusDisplayName {
    return status.name;
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE74C3C);
      case 'medium':
        return const Color(0xFFF39C12);
      case 'low':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class EstimateRequestStatus {
  final int id;
  final String name;
  final String? color;
  final String? description;

  EstimateRequestStatus({
    required this.id,
    required this.name,
    this.color,
    this.description,
  });

  factory EstimateRequestStatus.fromJson(Map<String, dynamic> json) {
    return EstimateRequestStatus(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      color: json['color'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
    };
  }
}

class EstimateRequestStaff {
  final int id;
  final String name;
  final String? email;
  final String? photo;

  EstimateRequestStaff({
    required this.id,
    required this.name,
    this.email,
    this.photo,
  });

  factory EstimateRequestStaff.fromJson(Map<String, dynamic> json) {
    return EstimateRequestStaff(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo': photo,
    };
  }
}

class EstimateRequestUser {
  final int id;
  final String name;
  final String? email;
  final String? company;

  EstimateRequestUser({
    required this.id,
    required this.name,
    this.email,
    this.company,
  });

  factory EstimateRequestUser.fromJson(Map<String, dynamic> json) {
    return EstimateRequestUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      company: json['company'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'company': company,
    };
  }
}

class EstimateRequestEstimate {
  final int id;
  final String estimateNumber;
  final String? title;
  final String? status;
  final double? total;

  EstimateRequestEstimate({
    required this.id,
    required this.estimateNumber,
    this.title,
    this.status,
    this.total,
  });

  factory EstimateRequestEstimate.fromJson(Map<String, dynamic> json) {
    return EstimateRequestEstimate(
      id: json['id'] ?? 0,
      estimateNumber: json['estimate_number'] ?? '',
      title: json['title'],
      status: json['status'],
      total: json['total']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estimate_number': estimateNumber,
      'title': title,
      'status': status,
      'total': total,
    };
  }
}

