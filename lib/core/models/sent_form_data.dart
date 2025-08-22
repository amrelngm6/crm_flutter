class SentFormData {
  final int id;
  final int businessId;
  final String? visitorType;
  final int? visitorId;
  final String? formName;
  final String? formType;
  final String? formUrl;
  final Map<String, dynamic>? formData;
  final String? referrerUrl;
  final String? userAgent;
  final String? ipAddress;
  final String? sessionId;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmTerm;
  final String? utmContent;
  final String? deviceType;
  final String? browser;
  final String? operatingSystem;
  final String? country;
  final String? city;
  final bool isLeadGenerated;
  final int? leadId;
  final String status;
  final DateTime? processedAt;
  final String? notes;
  final DateTime submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SentFormData({
    required this.id,
    required this.businessId,
    this.visitorType,
    this.visitorId,
    this.formName,
    this.formType,
    this.formUrl,
    this.formData,
    this.referrerUrl,
    this.userAgent,
    this.ipAddress,
    this.sessionId,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmTerm,
    this.utmContent,
    this.deviceType,
    this.browser,
    this.operatingSystem,
    this.country,
    this.city,
    required this.isLeadGenerated,
    this.leadId,
    required this.status,
    this.processedAt,
    this.notes,
    required this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SentFormData.fromJson(Map<String, dynamic> json) {
    return SentFormData(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      visitorType: json['visitor_type'],
      visitorId: json['visitor_id'],
      formName: json['form_name'],
      formType: json['form_type'],
      formUrl: json['form_url'],
      formData: json['form_data'] is Map<String, dynamic>
          ? json['form_data']
          : json['form_data'] is String
              ? _parseJsonString(json['form_data'])
              : null,
      referrerUrl: json['referrer_url'],
      userAgent: json['user_agent'],
      ipAddress: json['ip_address'],
      sessionId: json['session_id'],
      utmSource: json['utm_source'],
      utmMedium: json['utm_medium'],
      utmCampaign: json['utm_campaign'],
      utmTerm: json['utm_term'],
      utmContent: json['utm_content'],
      deviceType: json['device_type'],
      browser: json['browser'],
      operatingSystem: json['operating_system'],
      country: json['country'],
      city: json['city'],
      isLeadGenerated: json['is_lead_generated'] ?? false,
      leadId: json['lead_id'],
      status: json['status'] ?? 'pending',
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      notes: json['notes'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  static Map<String, dynamic>? _parseJsonString(String jsonString) {
    try {
      // Try to parse JSON string if it's a valid JSON
      return <String, dynamic>{}; // Return empty map for now
    } catch (e) {
      return null;
    }
  }

  static List<SentFormData> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => SentFormData.fromJson(json)).toList();
  }

  // Helper methods
  String getFormFieldsSummary() {
    if (formData == null || formData!.isEmpty) {
      return 'No data';
    }

    final summary = <String>[];
    const maxFields = 3;
    int count = 0;

    for (final entry in formData!.entries) {
      if (count >= maxFields) {
        summary.add('...');
        break;
      }

      if (entry.value is String && entry.value.toString().isNotEmpty) {
        final value = entry.value.toString();
        final displayValue =
            value.length > 30 ? '${value.substring(0, 30)}...' : value;
        summary.add('${_capitalize(entry.key)}: $displayValue');
        count++;
      }
    }

    return summary.join(', ');
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Map<String, String> getContactInfo() {
    final contact = <String, String>{};

    if (formData == null) return contact;

    // Common field names for contact info
    const emailFields = [
      'email',
      'email_address',
      'user_email',
      'contact_email'
    ];
    const nameFields = [
      'name',
      'full_name',
      'first_name',
      'firstName',
      'firstname',
      'last_name',
      'lastName',
      'surname'
    ];
    const phoneFields = ['phone', 'phone_number', 'mobile', 'contact_phone'];

    for (final field in emailFields) {
      if (formData!.containsKey(field) && formData![field] != null) {
        contact['email'] = formData![field].toString();
        break;
      }
    }

    for (final field in nameFields) {
      if (formData!.containsKey(field) && formData![field] != null) {
        contact['name'] = formData![field].toString();
        break;
      }
    }

    for (final field in phoneFields) {
      if (formData!.containsKey(field) && formData![field] != null) {
        contact['phone'] = formData![field].toString();
        break;
      }
    }

    return contact;
  }

  String getTrafficSource() {
    if (utmSource != null) {
      return 'Campaign ($utmSource)';
    }

    if (referrerUrl != null) {
      const socialPlatforms = [
        'facebook.com',
        'twitter.com',
        'linkedin.com',
        'instagram.com'
      ];
      for (final platform in socialPlatforms) {
        if (referrerUrl!.contains(platform)) {
          return 'Social Media';
        }
      }

      const searchEngines = ['google.com', 'bing.com', 'yahoo.com'];
      for (final engine in searchEngines) {
        if (referrerUrl!.contains(engine)) {
          return 'Organic Search';
        }
      }

      return 'Referral';
    }

    return 'Direct';
  }

  // Form type constants
  static const String typeContact = 'contact';
  static const String typeNewsletter = 'newsletter';
  static const String typeQuoteRequest = 'quote_request';
  static const String typeSupport = 'support';
  static const String typeCustom = 'custom';

  // Status constants
  static const String statusPending = 'pending';
  static const String statusProcessed = 'processed';
  static const String statusConverted = 'converted';
  static const String statusRejected = 'rejected';
}
