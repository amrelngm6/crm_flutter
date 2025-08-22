class EmailAccount {
  final int id;
  final String name;
  final String email;
  final String? type;
  final String? serverType;
  final String? host;
  final int? port;
  final String? encryption;
  final String? username;
  final bool isActive;
  final bool isDefault;
  final String? lastSync;
  final String syncStatus;
  final String? syncError;
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpEncryption;
  final String? smtpUsername;
  final String connectionStatus;
  final String? lastConnectionTest;
  final EmailAccountStats stats;
  final EmailAccountUser? user;
  final int businessId;
  final String? createdAt;
  final String? updatedAt;

  EmailAccount({
    required this.id,
    required this.name,
    required this.email,
    this.type,
    this.serverType,
    this.host,
    this.port,
    this.encryption,
    this.username,
    required this.isActive,
    required this.isDefault,
    this.lastSync,
    required this.syncStatus,
    this.syncError,
    this.smtpHost,
    this.smtpPort,
    this.smtpEncryption,
    this.smtpUsername,
    required this.connectionStatus,
    this.lastConnectionTest,
    required this.stats,
    this.user,
    required this.businessId,
    this.createdAt,
    this.updatedAt,
  });

  factory EmailAccount.fromJson(Map<String, dynamic> json) {
    return EmailAccount(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      type: json['type'],
      serverType: json['server_type'],
      host: json['host'],
      port: json['port'],
      encryption: json['encryption'],
      username: json['username'],
      isActive: json['is_active'] ?? false,
      isDefault: json['is_default'] ?? false,
      lastSync: json['last_sync'],
      syncStatus: json['sync_status'] ?? 'never_synced',
      syncError: json['sync_error'],
      smtpHost: json['smtp_host'],
      smtpPort: json['smtp_port'],
      smtpEncryption: json['smtp_encryption'],
      smtpUsername: json['smtp_username'],
      connectionStatus: json['connection_status'] ?? 'inactive',
      lastConnectionTest: json['last_connection_test'],
      stats: EmailAccountStats.fromJson(json['stats'] ?? {}),
      user: json['user'] != null ? EmailAccountUser.fromJson(json['user']) : null,
      businessId: json['business_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type,
      'server_type': serverType,
      'host': host,
      'port': port,
      'encryption': encryption,
      'username': username,
      'is_active': isActive,
      'is_default': isDefault,
      'last_sync': lastSync,
      'sync_status': syncStatus,
      'sync_error': syncError,
      'smtp_host': smtpHost,
      'smtp_port': smtpPort,
      'smtp_encryption': smtpEncryption,
      'smtp_username': smtpUsername,
      'connection_status': connectionStatus,
      'last_connection_test': lastConnectionTest,
      'stats': stats.toJson(),
      'user': user?.toJson(),
      'business_id': businessId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class EmailAccountStats {
  final int totalMessages;
  final int unreadMessages;
  final int recentMessages;

  EmailAccountStats({
    required this.totalMessages,
    required this.unreadMessages,
    required this.recentMessages,
  });

  factory EmailAccountStats.fromJson(Map<String, dynamic> json) {
    return EmailAccountStats(
      totalMessages: json['total_messages'] ?? 0,
      unreadMessages: json['unread_messages'] ?? 0,
      recentMessages: json['recent_messages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_messages': totalMessages,
      'unread_messages': unreadMessages,
      'recent_messages': recentMessages,
    };
  }
}

class EmailAccountUser {
  final int id;
  final String? name;

  EmailAccountUser({
    required this.id,
    this.name,
  });

  factory EmailAccountUser.fromJson(Map<String, dynamic> json) {
    return EmailAccountUser(
      id: json['id'] ?? 0,
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
