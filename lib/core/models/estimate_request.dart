class EstimateRequest {
  final int id;
  final String title;
  final String description;
  final String? requirements;
  final String? budget;
  final String? timeline;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? companyName;
  final String? website;
  final String? industry;
  final String? projectType;
  final String? status;
  final int? statusId;
  final String? statusName;
  final String? statusColor;
  final int? assignedTo;
  final String? assignedToName;
  final String? assignedToEmail;
  final String? assignedToPicture;
  final int? estimateId;
  final String? estimateTitle;
  final String? estimateAmount;
  final String? estimateCurrency;
  final String? userType;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? source;
  final String? priority;
  final String? notes;
  final bool isUrgent;
  final bool isFollowUp;
  final String? followUpDate;
  final String? dueDate;
  final String? completedDate;
  final int businessId;
  final String? createdAt;
  final String? updatedAt;
  final String? relativeTime;
  final bool isToday;
  final bool isThisWeek;
  final bool isThisMonth;

  EstimateRequest({
    required this.id,
    required this.title,
    required this.description,
    this.requirements,
    this.budget,
    this.timeline,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.companyName,
    this.website,
    this.industry,
    this.projectType,
    this.status,
    this.statusId,
    this.statusName,
    this.statusColor,
    this.assignedTo,
    this.assignedToName,
    this.assignedToEmail,
    this.assignedToPicture,
    this.estimateId,
    this.estimateTitle,
    this.estimateAmount,
    this.estimateCurrency,
    this.userType,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.source,
    this.priority,
    this.notes,
    required this.isUrgent,
    required this.isFollowUp,
    this.followUpDate,
    this.dueDate,
    this.completedDate,
    required this.businessId,
    this.createdAt,
    this.updatedAt,
    this.relativeTime,
    required this.isToday,
    required this.isThisWeek,
    required this.isThisMonth,
  });

  factory EstimateRequest.fromJson(Map<String, dynamic> json) {
    return EstimateRequest(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirements: json['requirements'],
      budget: json['budget'],
      timeline: json['timeline'],
      contactName: json['contact_name'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      companyName: json['company_name'],
      website: json['website'],
      industry: json['industry'],
      projectType: json['project_type'],
      status: json['status'],
      statusId: json['status_id'],
      statusName: json['status_name'],
      statusColor: json['status_color'],
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      assignedToEmail: json['assigned_to_email'],
      assignedToPicture: json['assigned_to_picture'],
      estimateId: json['estimate_id'],
      estimateTitle: json['estimate_title'],
      estimateAmount: json['estimate_amount'],
      estimateCurrency: json['estimate_currency'],
      userType: json['user_type'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      userPhone: json['user_phone'],
      source: json['source'],
      priority: json['priority'],
      notes: json['notes'],
      isUrgent: json['is_urgent'] ?? false,
      isFollowUp: json['is_follow_up'] ?? false,
      followUpDate: json['follow_up_date'],
      dueDate: json['due_date'],
      completedDate: json['completed_date'],
      businessId: json['business_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      relativeTime: json['relative_time'],
      isToday: json['is_today'] ?? false,
      isThisWeek: json['is_this_week'] ?? false,
      isThisMonth: json['is_this_month'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requirements': requirements,
      'budget': budget,
      'timeline': timeline,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'company_name': companyName,
      'website': website,
      'industry': industry,
      'project_type': projectType,
      'status': status,
      'status_id': statusId,
      'status_name': statusName,
      'status_color': statusColor,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'assigned_to_email': assignedToEmail,
      'assigned_to_picture': assignedToPicture,
      'estimate_id': estimateId,
      'estimate_title': estimateTitle,
      'estimate_amount': estimateAmount,
      'estimate_currency': estimateCurrency,
      'user_type': userType,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'source': source,
      'priority': priority,
      'notes': notes,
      'is_urgent': isUrgent,
      'is_follow_up': isFollowUp,
      'follow_up_date': followUpDate,
      'due_date': dueDate,
      'completed_date': completedDate,
      'business_id': businessId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'relative_time': relativeTime,
      'is_today': isToday,
      'is_this_week': isThisWeek,
      'is_this_month': isThisMonth,
    };
  }
}

class EstimateRequestStatus {
  final int id;
  final String name;
  final String color;
  final String? description;
  final bool isActive;
  final int sortOrder;

  EstimateRequestStatus({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.isActive,
    required this.sortOrder,
  });

  factory EstimateRequestStatus.fromJson(Map<String, dynamic> json) {
    return EstimateRequestStatus(
      id: json['id'],
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
      description: json['description'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

class EstimateRequestFormData {
  final List<EstimateRequestStatus> statuses;
  final List<Map<String, dynamic>> staffMembers;
  final List<Map<String, dynamic>> projectTypes;
  final List<Map<String, dynamic>> industries;
  final List<Map<String, dynamic>> sources;
  final List<Map<String, dynamic>> priorities;
  final Map<String, dynamic> settings;

  EstimateRequestFormData({
    required this.statuses,
    required this.staffMembers,
    required this.projectTypes,
    required this.industries,
    required this.sources,
    required this.priorities,
    required this.settings,
  });

  factory EstimateRequestFormData.fromJson(Map<String, dynamic> json) {
    return EstimateRequestFormData(
      statuses: (json['statuses'] as List<dynamic>?)
          ?.map((e) => EstimateRequestStatus.fromJson(e))
          .toList() ?? [],
      staffMembers: (json['staff_members'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      projectTypes: (json['project_types'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      industries: (json['industries'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      sources: (json['sources'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      priorities: (json['priorities'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }
}