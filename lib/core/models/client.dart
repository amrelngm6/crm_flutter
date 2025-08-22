import 'package:medians_ai_crm/core/constants/app_constants.dart';

class Client {
  final int id;
  final String? firstName;
  final String? lastName;
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final String? position;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? website;
  final String? notes;
  final String? avatar;
  final String status;
  final int? businessId;
  final int? createdBy;
  final int? projectsCount;
  final int? invoicesCount;
  final double? totalInvoiced;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    this.firstName,
    this.lastName,
    required this.name,
    required this.email,
    this.phone,
    this.company,
    this.position,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.website,
    this.notes,
    this.avatar,
    required this.status,
    this.businessId,
    this.createdBy,
    this.projectsCount,
    this.invoicesCount,
    this.totalInvoiced,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      firstName: json['first_name'],
      lastName: json['last_name'],
      name: _buildFullName(json),
      email: json['email'] ?? '',
      phone: json['phone'],
      company: json['company'],
      position: json['position'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      website: json['website'],
      notes: json['notes'],
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null,
      status: _extractStatusName(json['status']),
      businessId: json['business_id'],
      createdBy: json['created_by'],
      projectsCount: json['projects_count'],
      invoicesCount: json['invoices'] != null ? json['invoices'].length : 0,
      totalInvoiced: json['total_invoiced']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
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
    return name.isNotEmpty ? name : 'Unknown Client';
  }

  // Helper method to extract status name
  static String _extractStatusName(dynamic statusValue) {
    if (statusValue == null) return 'active';

    if (statusValue is String) {
      return statusValue;
    } else if (statusValue is num) {
      return statusValue.toString();
    } else if (statusValue is Map<String, dynamic>) {
      // Try to get the name field from status object
      return statusValue['name']?.toString() ?? 'active';
    }

    return statusValue.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'position': position,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'website': website,
      'notes': notes,
      'avatar': avatar,
      'status': status,
      'business_id': businessId,
      'created_by': createdBy,
      'projects_count': projectsCount,
      'invoices_count': invoicesCount,
      'total_invoiced': totalInvoiced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static List<Client> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Client.fromJson(json)).toList();
  }

  // Client status constants
  static const String statusActive = 'active';
  static const String statusInactive = 'inactive';
  static const String statusPending = 'pending';
  static const String statusSuspended = 'suspended';

  static List<String> get allStatuses => [
        statusActive,
        statusInactive,
        statusPending,
        statusSuspended,
      ];
}
