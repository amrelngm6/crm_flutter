import 'package:medians_ai_crm/core/constants/app_constants.dart';

class Deal {
  final int id;
  final String name;
  final String code;
  final String description;
  final DealAmount amount;
  final double probability;
  final String? expectedDueDate;
  final String status;
  final ContactInfo contactInfo;
  final DealClient? client;
  final DealLead? lead;
  final DealStage? stage;
  final List team;
  final Author? author;
  final TasksSummary? tasks;
  final LocationInfo? locationInfo;
  final DigitalActivity digitalActivity;
  final int businessId;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Deal({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.amount,
    required this.probability,
    this.expectedDueDate,
    required this.status,
    required this.contactInfo,
    this.client,
    this.lead,
    this.stage,
    required this.team,
    this.author,
    this.tasks,
    this.locationInfo,
    required this.digitalActivity,
    required this.businessId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: DealAmount.fromJson(json['amount'] ?? {}),
      probability: (json['probability'] is num)
          ? (json['probability'] as num).toDouble()
          : 0.0,
      expectedDueDate: json['expected_due_date']?.toString(),
      status: json['status']?.toString() ?? '',
      contactInfo: ContactInfo.fromJson(json['contact_info'] ?? {}),
      client:
          json['client'] != null ? DealClient.fromJson(json['client']) : null,
      lead: json['lead'] != null ? DealLead.fromJson(json['lead']) : null,
      stage: json['stage'] != null ? DealStage.fromJson(json['stage']) : null,
      team: _parseTeamList(json['team']),
      author: json['author'] != null ? Author.fromJson(json['author']) : null,
      tasks:
          json['tasks'] != null ? TasksSummary.fromJson(json['tasks']) : null,
      locationInfo: json['location_info'] != null
          ? LocationInfo.fromJson(json['location_info'])
          : null,
      digitalActivity: DigitalActivity.fromJson(json['digital_activity'] ?? {}),
      businessId: json['business_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static List<TeamMember> _parseTeamList(dynamic teamData) {
    if (teamData == null) return [];

    if (teamData is List) {
      return teamData.map((e) => TeamMember.fromJson(e)).toList();
    }

    return [];
  }

  static DateTime _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();

    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return DateTime.now();
    }
  }
}

class DealAmount {
  final double value;
  final String currencyCode;
  final String formatted;

  DealAmount({
    required this.value,
    required this.currencyCode,
    required this.formatted,
  });

  factory DealAmount.fromJson(Map<String, dynamic> json) {
    return DealAmount(
      value: _parseDouble(json['value']),
      currencyCode: json['currency_code']?.toString() ?? 'USD',
      formatted: json['formatted']?.toString() ?? '0.00',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }
}

class ContactInfo {
  final String? email;
  final String? phone;

  ContactInfo({this.email, this.phone});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class DealClient {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? avatar;

  DealClient({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.companyName,
    this.avatar,
  });

  factory DealClient.fromJson(Map<String, dynamic> json) {
    return DealClient(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      companyName: json['company_name']?.toString(),
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null,
    );
  }
}

class DealLead {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? source;

  DealLead({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.companyName,
    this.source,
  });

  factory DealLead.fromJson(Map<String, dynamic> json) {
    return DealLead(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      companyName: json['company_name']?.toString(),
      source: json['source']?.toString(),
    );
  }
}

class DealStage {
  final int? id;
  final String? name;
  final String color;
  final double? probability;
  final Pipeline? pipeline;

  DealStage({
    this.id,
    this.name,
    required this.color,
    this.probability,
    this.pipeline,
  });

  factory DealStage.fromJson(Map<String, dynamic> json) {
    return DealStage(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString(),
      color: json['color']?.toString() ?? '#6c757d',
      probability: (json['probability'] is num)
          ? (json['probability'] as num).toDouble()
          : null,
      pipeline:
          json['pipeline'] != null ? Pipeline.fromJson(json['pipeline']) : null,
    );
  }
}

class Pipeline {
  final int? id;
  final String? name;

  Pipeline({this.id, this.name});

  factory Pipeline.fromJson(Map<String, dynamic> json) {
    return Pipeline(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString(),
    );
  }
}

class TeamMember {
  final int id;
  final String userType;
  final String name;
  final String? email;
  final String? avatar;

  TeamMember({
    required this.id,
    required this.userType,
    required this.name,
    this.email,
    this.avatar,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
        id: json['id'] is int
            ? json['id']
            : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
        userType: json['user_type']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown',
        email: json['email']?.toString(),
        avatar: json['avatar'] != null
            ? AppConstants.publicUrl + json['avatar']
            : null);
  }
}

class Author {
  final int? id;
  final String name;
  final String? email;

  Author({
    this.id,
    required this.name,
    this.email,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
    );
  }
}

class TasksSummary {
  final int count;
  final int completed;
  final int pending;

  TasksSummary({
    required this.count,
    required this.completed,
    required this.pending,
  });

  factory TasksSummary.fromJson(Map<String, dynamic> json) {
    return TasksSummary(
      count: json['count'] is int
          ? json['count']
          : (int.tryParse(json['count']?.toString() ?? '') ?? 0),
      completed: json['completed'] is int
          ? json['completed']
          : (int.tryParse(json['completed']?.toString() ?? '') ?? 0),
      pending: json['pending'] is int
          ? json['pending']
          : (int.tryParse(json['pending']?.toString() ?? '') ?? 0),
    );
  }
}

class LocationInfo {
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  LocationInfo({
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      postalCode: json['postal_code']?.toString(),
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }
}

class DigitalActivity {
  final bool hasActivity;
  final int recentVisitsCount;
  final int recentSubmissionsCount;

  DigitalActivity({
    required this.hasActivity,
    required this.recentVisitsCount,
    required this.recentSubmissionsCount,
  });

  factory DigitalActivity.fromJson(Map<String, dynamic> json) {
    return DigitalActivity(
      hasActivity:
          json['has_activity'] == true || json['has_activity'] == 'true',
      recentVisitsCount: json['recent_visits_count'] is int
          ? json['recent_visits_count']
          : (int.tryParse(json['recent_visits_count']?.toString() ?? '') ?? 0),
      recentSubmissionsCount: json['recent_submissions_count'] is int
          ? json['recent_submissions_count']
          : (int.tryParse(json['recent_submissions_count']?.toString() ?? '') ??
              0),
    );
  }
}
