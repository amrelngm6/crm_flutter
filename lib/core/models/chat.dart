class ChatRoom {
  final int id;
  final String name;
  final int businessId;
  final int createdBy;
  final bool hasVideoMeeting;
  final String? meetingId;
  final Message? lastMessage;
  final int unreadCount;
  final List<Participant> participants;
  final int participantsCount;
  final bool isModerator;
  final String? createdAt;
  final String? updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    required this.businessId,
    required this.createdBy,
    required this.hasVideoMeeting,
    this.meetingId,
    this.lastMessage,
    required this.unreadCount,
    required this.participants,
    required this.participantsCount,
    required this.isModerator,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      businessId: json['business_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      hasVideoMeeting: json['has_video_meeting'] != 0 ? true : false,
      meetingId: json['meeting_id'],
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      participants: (json['participants'] as List?)
              ?.map((item) => Participant.fromJson(item))
              .toList() ??
          [],
      participantsCount: json['participants_count'] ?? 0,
      isModerator: json['is_moderator'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'business_id': businessId,
      'created_by': createdBy,
      'has_video_meeting': hasVideoMeeting,
      'meeting_id': meetingId,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'participants': participants.map((p) => p.toJson()).toList(),
      'participants_count': participantsCount,
      'is_moderator': isModerator,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Message {
  final int id;
  final int businessId;
  final int roomId;
  final String message;
  final String type;
  final int userId;
  final String userType;
  final String? sentAt;
  final String? seenAt;
  final ChatUser? user;
  final List<MessageFile> files;
  final String? createdAt;
  final String? updatedAt;

  Message({
    required this.id,
    required this.businessId,
    required this.roomId,
    required this.message,
    required this.type,
    required this.userId,
    required this.userType,
    this.sentAt,
    this.seenAt,
    this.user,
    required this.files,
    this.createdAt,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      roomId: json['room_id'] ?? 0,
      message: json['message'] ?? '',
      type: json['type'] ?? 'text',
      userId: json['user_id'] ?? 0,
      userType: json['user_type'] ?? '',
      sentAt: json['sent_at'],
      seenAt: json['seen_at'],
      user: json['user'] != null ? ChatUser.fromJson(json['user']) : null,
      files: (json['files'] as List?)
              ?.map((item) => MessageFile.fromJson(item))
              .toList() ??
          [],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'room_id': roomId,
      'message': message,
      'type': type,
      'user_id': userId,
      'user_type': userType,
      'sent_at': sentAt,
      'seen_at': seenAt,
      'user': user?.toJson(),
      'files': files.map((f) => f.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isRead => seenAt != null;
  bool get isMyMessage => user?.isCurrent == true;
}

class Participant {
  final int id;
  final int businessId;
  final int roomId;
  final int userId;
  final String userType;
  final bool isModerator;
  final ChatUser? user;
  final String? joinedAt;
  final String? leftAt;

  Participant({
    required this.id,
    required this.businessId,
    required this.roomId,
    required this.userId,
    required this.userType,
    required this.isModerator,
    this.user,
    this.joinedAt,
    this.leftAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      roomId: json['room_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userType: json['user_type'] ?? '',
      isModerator: json['is_moderator'] > 0,
      user: json['user'] != null ? ChatUser.fromJson(json['user']) : null,
      joinedAt: json['joined_at'],
      leftAt: json['left_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'room_id': roomId,
      'user_id': userId,
      'user_type': userType,
      'is_moderator': isModerator,
      'user': user?.toJson(),
      'joined_at': joinedAt,
      'left_at': leftAt,
    };
  }
}

class ChatUser {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? firstName;
  final String? lastName;
  final bool isCurrent;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.firstName,
    this.lastName,
    required this.isCurrent,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isCurrent: json['is_current'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'first_name': firstName,
      'last_name': lastName,
      'is_current': isCurrent,
    };
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return 'U';
  }
}

class MessageFile {
  final int id;
  final int messageId;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final String? createdAt;

  MessageFile({
    required this.id,
    required this.messageId,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    this.createdAt,
  });

  factory MessageFile.fromJson(Map<String, dynamic> json) {
    return MessageFile(
      id: json['id'] ?? 0,
      messageId: json['message_id'] ?? 0,
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      mimeType: json['mime_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'created_at': createdAt,
    };
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isDocument => !isImage && !isVideo && !isAudio;
}

class StaffMember {
  final int? id;
  final String name;
  final String email;
  final String? avatar;

  StaffMember({
    this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
