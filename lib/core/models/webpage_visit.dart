class WebpageVisit {
  final int id;
  final int businessId;
  final String? visitorType;
  final int? visitorId;
  final String pageUrl;
  final String? pageTitle;
  final String? referrerUrl;
  final String? userAgent;
  final String? ipAddress;
  final String? sessionId;
  final int? durationSeconds;
  final bool isUniqueVisit;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmTerm;
  final String? utmContent;
  final String? deviceType;
  final String? browser;
  final String? operatingSystem;
  final String? country;
  final String? countryCode;
  final String? city;
  final DateTime visitedAt;
  final bool? exitPage;
  final bool? bounce;
  final DateTime createdAt;
  final DateTime updatedAt;

  WebpageVisit({
    required this.id,
    required this.businessId,
    this.visitorType,
    this.visitorId,
    required this.pageUrl,
    this.pageTitle,
    this.referrerUrl,
    this.userAgent,
    this.ipAddress,
    this.sessionId,
    this.durationSeconds,
    required this.isUniqueVisit,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmTerm,
    this.utmContent,
    this.deviceType,
    this.browser,
    this.operatingSystem,
    this.country,
    this.countryCode,
    this.city,
    required this.visitedAt,
    this.exitPage,
    this.bounce,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WebpageVisit.fromJson(Map<String, dynamic> json) {
    return WebpageVisit(
      id: json['id'] ?? 0,
      businessId: json['business_id'] ?? 0,
      visitorType: json['visitor_type'],
      visitorId: json['visitor_id'],
      pageUrl: json['page_url'] ?? '',
      pageTitle: json['page_title'],
      referrerUrl: json['referrer_url'],
      userAgent: json['user_agent'],
      ipAddress: json['ip_address'],
      sessionId: json['session_id'],
      durationSeconds: json['duration_seconds'],
      isUniqueVisit: json['is_unique_visit'] ?? false,
      utmSource: json['utm_source'],
      utmMedium: json['utm_medium'],
      utmCampaign: json['utm_campaign'],
      utmTerm: json['utm_term'],
      utmContent: json['utm_content'],
      deviceType: json['device_type'],
      browser: json['browser'],
      operatingSystem: json['operating_system'],
      country: json['country'],
      countryCode: json['country_code'],
      city: json['city'],
      visitedAt: json['visited_at'] != null
          ? DateTime.parse(json['visited_at'])
          : DateTime.now(),
      exitPage: json['exit_page'],
      bounce: json['bounce'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  static List<WebpageVisit> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => WebpageVisit.fromJson(json)).toList();
  }

  // Helper methods
  String getDurationFormatted() {
    if (durationSeconds == null || durationSeconds == 0) {
      return 'Unknown';
    }

    final minutes = (durationSeconds! / 60).floor();
    final seconds = durationSeconds! % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }

  bool isOrganicSearch() {
    if (referrerUrl == null) return false;

    const searchEngines = [
      'google.com',
      'bing.com',
      'yahoo.com',
      'duckduckgo.com'
    ];

    for (final engine in searchEngines) {
      if (referrerUrl!.contains(engine)) {
        return true;
      }
    }

    return false;
  }

  bool isSocialMedia() {
    if (referrerUrl == null) return false;

    const socialPlatforms = [
      'facebook.com',
      'twitter.com',
      'linkedin.com',
      'instagram.com',
      'youtube.com'
    ];

    for (final platform in socialPlatforms) {
      if (referrerUrl!.contains(platform)) {
        return true;
      }
    }

    return false;
  }

  String getTrafficSource() {
    if (utmSource != null) {
      return 'Campaign ($utmSource)';
    }

    if (isOrganicSearch()) {
      return 'Organic Search';
    }

    if (isSocialMedia()) {
      return 'Social Media';
    }

    if (referrerUrl != null) {
      return 'Referral';
    }

    return 'Direct';
  }
}
