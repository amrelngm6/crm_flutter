class Meeting {
  final int id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final int? durationMinutes;
  final String? location;
  final String? meetingUrl;
  final int? reminderMinutes;
  final bool isRecurring;
  final String? recurringType;
  final DateTime? recurringEndDate;
  final MeetingStatus status;
  final MeetingClient? client;
  final List<MeetingAttendee> attendees;
  final bool isPast;
  final bool isToday;
  final bool isUpcoming;
  final String? timeUntilMeeting;
  final int businessId;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Meeting({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.durationMinutes,
    this.location,
    this.meetingUrl,
    this.reminderMinutes,
    this.isRecurring = false,
    this.recurringType,
    this.recurringEndDate,
    required this.status,
    this.client,
    this.attendees = const [],
    this.isPast = false,
    this.isToday = false,
    this.isUpcoming = false,
    this.timeUntilMeeting,
    required this.businessId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes']
          : (json['duration_minutes'] != null
              ? int.tryParse(json['duration_minutes'].toString())
              : null),
      location: json['location']?.toString(),
      meetingUrl: json['meeting_url']?.toString(),
      reminderMinutes: json['reminder_minutes'] is int
          ? json['reminder_minutes']
          : (json['reminder_minutes'] != null
              ? int.tryParse(json['reminder_minutes'].toString())
              : null),
      isRecurring:
          json['is_recurring'] == true || json['is_recurring'] == 'true',
      recurringType: json['recurring_type']?.toString(),
      recurringEndDate: json['recurring_end_date'] != null
          ? DateTime.tryParse(json['recurring_end_date'].toString())
          : null,
      status: MeetingStatus.fromJson(json['status'] ?? {}),
      client: json['client'] != null
          ? MeetingClient.fromJson(json['client'])
          : null,
      attendees: (json['attendees'] as List<dynamic>?)
              ?.map((attendee) => MeetingAttendee.fromJson(attendee))
              .toList() ??
          [],
      isPast: json['is_past'] == true || json['is_past'] == 'true',
      isToday: json['is_today'] == true || json['is_today'] == 'true',
      isUpcoming: json['is_upcoming'] == true || json['is_upcoming'] == 'true',
      timeUntilMeeting: json['time_until_meeting']?.toString(),
      businessId: json['business_id'] is int
          ? json['business_id']
          : (int.tryParse(json['business_id']?.toString() ?? '') ?? 0),
      createdBy: json['created_by'] is int
          ? json['created_by']
          : (int.tryParse(json['created_by']?.toString() ?? '') ?? 0),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'location': location,
      'meeting_url': meetingUrl,
      'reminder_minutes': reminderMinutes,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'recurring_end_date': recurringEndDate?.toIso8601String(),
      'status': status.toJson(),
      'client': client?.toJson(),
      'attendees': attendees.map((attendee) => attendee.toJson()).toList(),
      'is_past': isPast,
      'is_today': isToday,
      'is_upcoming': isUpcoming,
      'time_until_meeting': timeUntilMeeting,
      'business_id': businessId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedTime {
    final timeFormat =
        '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';
    if (endDate != null) {
      final endTimeFormat =
          '${endDate!.hour.toString().padLeft(2, '0')}:${endDate!.minute.toString().padLeft(2, '0')}';
      return '$timeFormat - $endTimeFormat';
    }
    return timeFormat;
  }

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[startDate.month - 1]} ${startDate.day}, ${startDate.year}';
  }

  String get attendeesText {
    if (attendees.isEmpty) return 'No attendees';
    if (attendees.length == 1) return attendees.first.name;
    if (attendees.length <= 3) {
      return attendees.map((a) => a.name).join(', ');
    }
    return '${attendees.take(2).map((a) => a.name).join(', ')} +${attendees.length - 2} more';
  }

  // Additional helper methods similar to Estimate model
  String get statusName => status.name;
  String get statusColor => status.color;
  String get clientName => client?.name ?? 'No Client';
  String get clientCompany => client?.company ?? '';
  String get formattedStartDate =>
      '${startDate.day}/${startDate.month}/${startDate.year}';
  String get formattedStartTime =>
      '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';
  String get formattedEndTime => endDate != null
      ? '${endDate!.hour.toString().padLeft(2, '0')}:${endDate!.minute.toString().padLeft(2, '0')}'
      : 'N/A';
  String get formattedTimeRange => endDate != null
      ? '$formattedStartTime - $formattedEndTime'
      : formattedStartTime;
  String get formattedDuration => durationMinutes != null
      ? '${(durationMinutes! / 60).floor()}h ${durationMinutes! % 60}m'
      : 'N/A';
  int get attendeesCount => attendees.length;
  bool get hasLocation => location != null && location!.isNotEmpty;
  bool get hasUrl => meetingUrl != null && meetingUrl!.isNotEmpty;
  bool get hasReminder => reminderMinutes != null && reminderMinutes! > 0;
}

class MeetingStatus {
  final String id;
  final String name;
  final String color;

  MeetingStatus({
    required this.id,
    required this.name,
    required this.color,
  });

  factory MeetingStatus.fromJson(Map<String, dynamic> json) {
    return MeetingStatus(
      id: json['id']?.toString() ?? 'scheduled',
      name: json['name']?.toString() ?? 'Scheduled',
      color: json['color']?.toString() ?? '#007bff',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}

class MeetingClient {
  final int? id;
  final String? name;
  final String? email;
  final String? company;

  MeetingClient({
    this.id,
    this.name,
    this.email,
    this.company,
  });

  factory MeetingClient.fromJson(Map<String, dynamic> json) {
    return MeetingClient(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      company: json['company']?.toString(),
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

class MeetingAttendee {
  final int id;
  final String name;
  final String? email;
  final String? avatar;

  MeetingAttendee({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
  });

  factory MeetingAttendee.fromJson(Map<String, dynamic> json) {
    return MeetingAttendee(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
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
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return 'U';
  }
}

class CalendarEvent {
  final String date;
  final List<Meeting> meetings;
  final int total;

  CalendarEvent({
    required this.date,
    required this.meetings,
    required this.total,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      date: json['date'] ?? '',
      meetings: (json['meetings'] as List<dynamic>?)
              ?.map((meeting) => Meeting.fromJson(meeting))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'meetings': meetings.map((meeting) => meeting.toJson()).toList(),
      'total': total,
    };
  }
}
