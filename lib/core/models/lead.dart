import 'client.dart';

class Lead {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final String source;
  final String status;
  final double? value;
  final String? notes;
  final int? assignedTo;
  final DateTime? followUpDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Client? client;

  Lead({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.company,
    required this.source,
    required this.status,
    this.value,
    this.notes,
    this.assignedTo,
    this.followUpDate,
    required this.createdAt,
    required this.updatedAt,
    this.client,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] ?? 0,
      name: _buildFullName(json),
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      company: json['company'],
      source: _extractNestedName(json['source'], 'unknown'),
      status: _extractStatusName(json['status']),
      value: json['value']?.toDouble(),
      notes: json['notes'],
      assignedTo: json['assigned_to'],
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      client: json['client'] != null ? Client.fromJson(json['client']) : null,
    );
  }

  // Helper method to build full name from first_name and last_name
  static String _buildFullName(Map<String, dynamic> json) {
    String firstName = json['first_name']?.toString() ?? '';
    String lastName = json['last_name']?.toString() ?? '';
    String name = json['name']?.toString() ?? '';

    // If we have first_name and last_name, use them
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    // Otherwise use the name field
    return name.isNotEmpty ? name : 'Unknown';
  }

  // Helper method to extract name from nested objects
  static String _extractNestedName(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;

    if (value is String) {
      return value;
    } else if (value is Map<String, dynamic>) {
      // Try to get the name field from nested object
      String? name = value['name']?.toString();

      // If name is also a nested object (like in your status example), extract from it
      if (name != null && name.startsWith('{')) {
        try {
          // This looks like a JSON string, but it might be malformed
          // Let's try to extract the name value manually
          RegExp nameRegex = RegExp(r'"name":"([^"]*)"');
          Match? match = nameRegex.firstMatch(name);
          if (match != null) {
            return match.group(1) ?? defaultValue;
          }
        } catch (e) {
          // If parsing fails, return default
          return defaultValue;
        }
      } else if (name != null) {
        return name;
      }

      return defaultValue;
    }

    return value.toString();
  }

  // Helper method to extract status name
  static String _extractStatusName(dynamic statusValue) {
    if (statusValue == null) return 'new';

    if (statusValue is String) {
      return statusValue;
    } else if (statusValue is Map<String, dynamic>) {
      // Try to get the name field from status object
      return statusValue['name']?.toString() ?? 'new';
    }

    return statusValue.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'source': source,
      'status': status,
      'value': value,
      'notes': notes,
      'assigned_to': assignedTo,
      'follow_up_date': followUpDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static List<Lead> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Lead.fromJson(json)).toList();
  }

  // Lead status constants
  static const String statusNew = 'new';
  static const String statusContacted = 'contacted';
  static const String statusQualified = 'qualified';
  static const String statusProposal = 'proposal';
  static const String statusWon = 'won';
  static const String statusLost = 'lost';

  static List<String> get allStatuses => [
        statusNew,
        statusContacted,
        statusQualified,
        statusProposal,
        statusWon,
        statusLost,
      ];

  // Lead sources
  static const String sourceWebsite = 'website';
  static const String sourceReferral = 'referral';
  static const String sourceSocial = 'social';
  static const String sourceEmail = 'email';
  static const String sourcePhone = 'phone';
  static const String sourceOther = 'other';

  static List<String> get allSources => [
        sourceWebsite,
        sourceReferral,
        sourceSocial,
        sourceEmail,
        sourcePhone,
        sourceOther,
      ];
}
