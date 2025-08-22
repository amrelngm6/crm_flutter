class EmailMessage {
  final int id;
  final String? messageId;
  final String subject;
  final String fromEmail;
  final String fromName;
  final String? toEmail;
  final String? toName;
  final String? cc;
  final String? bcc;
  final String? replyTo;
  final String? date;
  final String? bodyHtml;
  final String? bodyText;
  final String snippet;
  final bool isRead;
  final bool isStarred;
  final bool isFlagged;
  final bool isDraft;
  final bool isSent;
  final bool isArchived;
  final bool isDeleted;
  final bool isSpam;
  final String? folder;
  final List<String> labels;
  final String? priority;
  final String? importance;
  final String? threadId;
  final String? inReplyTo;
  final String? references;
  final EmailMessageAccount account;
  final bool hasAttachments;
  final int attachmentsCount;
  final List<EmailAttachment> attachments;
  final int? size;
  final String sizeHuman;
  final EmailSenderInfo senderInfo;
  final List<EmailRecipientInfo> recipientInfo;
  final bool isRecent;
  final bool isToday;
  final bool isThisWeek;
  final String relativeTime;
  final EmailThreadInfo threadInfo;
  final int businessId;
  final String? createdAt;
  final String? updatedAt;

  EmailMessage({
    required this.id,
    this.messageId,
    required this.subject,
    required this.fromEmail,
    required this.fromName,
    this.toEmail,
    this.toName,
    this.cc,
    this.bcc,
    this.replyTo,
    this.date,
    this.bodyHtml,
    this.bodyText,
    required this.snippet,
    required this.isRead,
    required this.isStarred,
    required this.isFlagged,
    required this.isDraft,
    required this.isSent,
    required this.isArchived,
    required this.isDeleted,
    required this.isSpam,
    this.folder,
    required this.labels,
    this.priority,
    this.importance,
    this.threadId,
    this.inReplyTo,
    this.references,
    required this.account,
    required this.hasAttachments,
    required this.attachmentsCount,
    required this.attachments,
    this.size,
    required this.sizeHuman,
    required this.senderInfo,
    required this.recipientInfo,
    required this.isRecent,
    required this.isToday,
    required this.isThisWeek,
    required this.relativeTime,
    required this.threadInfo,
    required this.businessId,
    this.createdAt,
    this.updatedAt,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'],
      messageId: json['message_id'],
      subject: json['subject'] ?? '',
      fromEmail: json['from_email'] ?? '',
      fromName: json['from_name'] ?? '',
      toEmail: json['to_email'],
      toName: json['to_name'],
      cc: json['cc'],
      bcc: json['bcc'],
      replyTo: json['reply_to'],
      date: json['date'],
      bodyHtml: json['body_html'],
      bodyText: json['body_text'],
      snippet: json['snippet'] ?? '',
      isRead: json['is_read'] ?? false,
      isStarred: json['is_starred'] ?? false,
      isFlagged: json['is_flagged'] ?? false,
      isDraft: json['is_draft'] ?? false,
      isSent: json['is_sent'] ?? false,
      isArchived: json['is_archived'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      isSpam: json['is_spam'] ?? false,
      folder: json['folder'],
      labels: (json['labels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      priority: json['priority'],
      importance: json['importance'],
      threadId: json['thread_id'],
      inReplyTo: json['in_reply_to'],
      references: json['references'],
      account: EmailMessageAccount.fromJson(json['account'] ?? {}),
      hasAttachments: json['has_attachments'] ?? false,
      attachmentsCount: json['attachments_count'] ?? 0,
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => EmailAttachment.fromJson(e)).toList() ?? [],
      size: json['size'],
      sizeHuman: json['size_human'] ?? '0 B',
      senderInfo: EmailSenderInfo.fromJson(json['sender_info'] ?? {}),
      recipientInfo: (json['recipient_info'] as List<dynamic>?)?.map((e) => EmailRecipientInfo.fromJson(e)).toList() ?? [],
      isRecent: json['is_recent'] ?? false,
      isToday: json['is_today'] ?? false,
      isThisWeek: json['is_this_week'] ?? false,
      relativeTime: json['relative_time'] ?? '',
      threadInfo: EmailThreadInfo.fromJson(json['thread_info'] ?? {}),
      businessId: json['business_id'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'subject': subject,
      'from_email': fromEmail,
      'from_name': fromName,
      'to_email': toEmail,
      'to_name': toName,
      'cc': cc,
      'bcc': bcc,
      'reply_to': replyTo,
      'date': date,
      'body_html': bodyHtml,
      'body_text': bodyText,
      'snippet': snippet,
      'is_read': isRead,
      'is_starred': isStarred,
      'is_flagged': isFlagged,
      'is_draft': isDraft,
      'is_sent': isSent,
      'is_archived': isArchived,
      'is_deleted': isDeleted,
      'is_spam': isSpam,
      'folder': folder,
      'labels': labels,
      'priority': priority,
      'importance': importance,
      'thread_id': threadId,
      'in_reply_to': inReplyTo,
      'references': references,
      'account': account.toJson(),
      'has_attachments': hasAttachments,
      'attachments_count': attachmentsCount,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'size': size,
      'size_human': sizeHuman,
      'sender_info': senderInfo.toJson(),
      'recipient_info': recipientInfo.map((e) => e.toJson()).toList(),
      'is_recent': isRecent,
      'is_today': isToday,
      'is_this_week': isThisWeek,
      'relative_time': relativeTime,
      'thread_info': threadInfo.toJson(),
      'business_id': businessId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class EmailMessageAccount {
  final int id;
  final String? name;
  final String? email;

  EmailMessageAccount({
    required this.id,
    this.name,
    this.email,
  });

  factory EmailMessageAccount.fromJson(Map<String, dynamic> json) {
    return EmailMessageAccount(
      id: json['id'] ?? 0,
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class EmailAttachment {
  final int id;
  final String filename;
  final String mimeType;
  final int size;
  final String sizeHuman;

  EmailAttachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.sizeHuman,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      id: json['id'] ?? 0,
      filename: json['filename'] ?? '',
      mimeType: json['mime_type'] ?? '',
      size: json['size'] ?? 0,
      sizeHuman: json['size_human'] ?? '0 B',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'mime_type': mimeType,
      'size': size,
      'size_human': sizeHuman,
    };
  }
}

class EmailSenderInfo {
  final String email;
  final String name;
  final String initials;
  final String displayName;

  EmailSenderInfo({
    required this.email,
    required this.name,
    required this.initials,
    required this.displayName,
  });

  factory EmailSenderInfo.fromJson(Map<String, dynamic> json) {
    return EmailSenderInfo(
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      initials: json['initials'] ?? '',
      displayName: json['display_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'initials': initials,
      'display_name': displayName,
    };
  }
}

class EmailRecipientInfo {
  final String type;
  final String email;
  final String name;
  final String displayName;

  EmailRecipientInfo({
    required this.type,
    required this.email,
    required this.name,
    required this.displayName,
  });

  factory EmailRecipientInfo.fromJson(Map<String, dynamic> json) {
    return EmailRecipientInfo(
      type: json['type'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'email': email,
      'name': name,
      'display_name': displayName,
    };
  }
}

class EmailThreadInfo {
  final String? threadId;
  final int? threadPosition;
  final bool hasPrevious;
  final bool hasNext;

  EmailThreadInfo({
    this.threadId,
    this.threadPosition,
    required this.hasPrevious,
    required this.hasNext,
  });

  factory EmailThreadInfo.fromJson(Map<String, dynamic> json) {
    return EmailThreadInfo(
      threadId: json['thread_id'],
      threadPosition: json['thread_position'],
      hasPrevious: json['has_previous'] ?? false,
      hasNext: json['has_next'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thread_id': threadId,
      'thread_position': threadPosition,
      'has_previous': hasPrevious,
      'has_next': hasNext,
    };
  }
}
