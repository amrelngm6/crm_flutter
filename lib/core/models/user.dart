import 'package:medians_ai_crm/core/constants/app_constants.dart';

class Role {
  final int id;
  final String name;

  Role({
    required this.id,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class UserStatus {
  final int id;
  final String name;

  UserStatus({
    required this.id,
    required this.name,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Business {
  final int id;
  final String name;

  Business({
    required this.id,
    required this.name,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Tokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int refreshExpiresIn;

  Tokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshExpiresIn,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'] ?? 3600,
      refreshExpiresIn: json['refresh_expires_in'] ?? 2592000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_expires_in': refreshExpiresIn,
    };
  }
}

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String name;
  final String email;
  final String? phone;
  final String? position;
  final String? about;
  final String? avatar;
  final int businessId;
  final Role role;
  final UserStatus status;
  final List<String> permissions;
  final int? lastActivity;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.email,
    this.phone,
    this.position,
    this.about,
    this.avatar,
    required this.businessId,
    required this.role,
    required this.status,
    required this.permissions,
    this.lastActivity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      position: json['position'],
      about: json['about'],
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null,
      businessId: json['business_id'] ?? 0,
      role: Role.fromJson(json['role'] ?? {}),
      status: UserStatus.fromJson(json['status'] ?? {}),
      permissions: List<String>.from(json['permissions'] ?? []),
      lastActivity: json['last_activity'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'about': about,
      'avatar': avatar,
      'business_id': businessId,
      'role': role.toJson(),
      'status': status.toJson(),
      'permissions': permissions,
      'last_activity': lastActivity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  String get fullName => '$firstName $lastName';

  String get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return '';
    // Assuming your Laravel app serves images from storage
    return avatar!.startsWith('http')
        ? avatar!
        : AppConstants.publicUrl + avatar!;
  }
}

class AuthResponse {
  final User user;
  final Tokens tokens;
  final Business business;
  final bool success;
  final String message;

  AuthResponse({
    required this.user,
    required this.tokens,
    required this.business,
    required this.success,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['data']['user']),
      tokens: Tokens.fromJson(json['data']['tokens']),
      business: Business.fromJson(json['data']['business']),
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'user': user.toJson(),
        'tokens': tokens.toJson(),
        'business': business.toJson(),
      },
    };
  }
}
