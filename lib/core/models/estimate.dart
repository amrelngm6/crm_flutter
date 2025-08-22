import 'package:medians_ai_crm/core/constants/app_constants.dart';

class Estimate {
  final int id;
  final String estimateNumber;
  final String title;
  final String? content;
  final EstimateStatus status;
  final EstimateApproval approval;
  final EstimateDates dates;
  final EstimateFinancial financial;
  final EstimateConversion conversion;
  final EstimateClient? client;
  final EstimateAssignedTo? assignedTo;
  final EstimateModel model;
  final EstimateItems? items;
  final EstimateRequests? requests;
  final int businessId;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Estimate({
    required this.id,
    required this.estimateNumber,
    required this.title,
    this.content,
    required this.status,
    required this.approval,
    required this.dates,
    required this.financial,
    required this.conversion,
    this.client,
    this.assignedTo,
    required this.model,
    this.items,
    this.requests,
    required this.businessId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Estimate.fromJson(Map<String, dynamic> json) {
    return Estimate(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      estimateNumber: json['estimate_number']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      status: EstimateStatus.fromJson(json['status'] ?? {}),
      approval: EstimateApproval.fromJson(json['approval'] ?? {}),
      dates: EstimateDates.fromJson(json['dates'] ?? {}),
      financial: EstimateFinancial.fromJson(json['financial'] ?? {}),
      conversion: EstimateConversion.fromJson(json['conversion'] ?? {}),
      client: json['client'] != null
          ? EstimateClient.fromJson(json['client'])
          : null,
      assignedTo: json['assigned_to'] != null
          ? EstimateAssignedTo.fromJson(json['assigned_to'])
          : null,
      model: EstimateModel.fromJson(json['model'] ?? {}),
      items: json['items'] != null
          ? EstimateItems.fromJson(json['items']['items'])
          : null,
      requests: json['requests'] != null
          ? EstimateRequests.fromJson(json['requests'])
          : null,
      businessId: json['business_id'] is int
          ? json['business_id']
          : (int.tryParse(json['business_id']?.toString() ?? '') ?? 0),
      createdBy: json['created_by'] is int
          ? json['created_by']
          : (json['created_by'] != null
              ? int.tryParse(json['created_by'].toString())
              : null),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is String) {
      return DateTime.tryParse(dateData) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estimate_number': estimateNumber,
      'title': title,
      'content': content,
      'status': status.toJson(),
      'approval': approval.toJson(),
      'dates': dates.toJson(),
      'financial': financial.toJson(),
      'conversion': conversion.toJson(),
      'client': client?.toJson(),
      'assigned_to': assignedTo?.toJson(),
      'model': model.toJson(),
      'items': items?.toJson(),
      'requests': requests?.toJson(),
      'business_id': businessId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get statusName => status.name;
  String get statusColor => status.color;
  String get approvalStatusText => approval.status;
  bool get isApproved => approval.isApproved;
  bool get isRejected => approval.isRejected;
  bool get isPending => approval.isPending;
  bool get isExpired => dates.isExpired;
  bool get isConverted => conversion.isConverted;
  String get formattedTotal => financial.formattedTotal;
  String get formattedSubtotal => '\$${financial.subtotal.toStringAsFixed(2)}';
  String get formattedTax => '\$${financial.taxAmount.toStringAsFixed(2)}';
  String get formattedDiscount =>
      '\$${financial.discountAmount.toStringAsFixed(2)}';
  String get clientName => client?.name ?? 'No Client';
  String get clientEmail => client?.email ?? '';
  String get clientPhone => client?.phone ?? '';
  String get clientAddress => client?.companyName ?? '';
  String get assignedToName => assignedTo?.name ?? 'Unassigned';
  int get itemsCount => items?.count ?? 0;
  String get description => content ?? '';
  List<EstimateItem> get itemsList => items?.items ?? [];
}

class EstimateStatus {
  final int id;
  final String name;
  final String color;

  EstimateStatus({
    required this.id,
    required this.name,
    required this.color,
  });

  factory EstimateStatus.fromJson(Map<String, dynamic> json) {
    return EstimateStatus(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? 'Unknown',
      color: json['color']?.toString() ?? '#6c757d',
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

class EstimateApproval {
  final String status;
  final bool requiresApproval;
  final bool isApproved;
  final bool isRejected;
  final bool isPending;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? approvedBy;
  final String? rejectedBy;
  final String? rejectionReason;

  EstimateApproval({
    required this.status,
    required this.requiresApproval,
    required this.isApproved,
    required this.isRejected,
    required this.isPending,
    this.approvedAt,
    this.rejectedAt,
    this.approvedBy,
    this.rejectedBy,
    this.rejectionReason,
  });

  factory EstimateApproval.fromJson(Map<String, dynamic> json) {
    return EstimateApproval(
      status: json['status']?.toString() ?? 'pending',
      requiresApproval: json['requires_approval'] == true ||
          json['requires_approval'] == 'true',
      isApproved: json['is_approved'] == true || json['is_approved'] == 'true',
      isRejected: json['is_rejected'] == true || json['is_rejected'] == 'true',
      isPending: json['is_pending'] == true || json['is_pending'] == 'true',
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.tryParse(json['rejected_at'].toString())
          : null,
      approvedBy: json['approved_by']?.toString(),
      rejectedBy: json['rejected_by']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'requires_approval': requiresApproval,
      'is_approved': isApproved,
      'is_rejected': isRejected,
      'is_pending': isPending,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejected_by': rejectedBy,
      'rejection_reason': rejectionReason,
    };
  }

  String? get formattedApprovedAt => approvedAt != null
      ? '${approvedAt!.day}/${approvedAt!.month}/${approvedAt!.year}'
      : null;
  String? get formattedRejectedAt => rejectedAt != null
      ? '${rejectedAt!.day}/${rejectedAt!.month}/${rejectedAt!.year}'
      : null;
}

class EstimateDates {
  final DateTime? date;
  final DateTime? expiryDate;
  final bool isExpired;
  final double? daysUntilExpiry;
  final DateTime? convertedAt;

  EstimateDates({
    this.date,
    this.expiryDate,
    required this.isExpired,
    this.daysUntilExpiry,
    this.convertedAt,
  });

  factory EstimateDates.fromJson(Map<String, dynamic> json) {
    return EstimateDates(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      isExpired: json['is_expired'] == true || json['is_expired'] == 'true',
      daysUntilExpiry: json['days_until_expiry'] is num
          ? (json['days_until_expiry'] as num).toDouble()
          : null,
      convertedAt: json['converted_at'] != null
          ? DateTime.tryParse(json['converted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'is_expired': isExpired,
      'days_until_expiry': daysUntilExpiry,
      'converted_at': convertedAt?.toIso8601String(),
    };
  }

  String get formattedCreatedAt =>
      date != null ? '${date!.day}/${date!.month}/${date!.year}' : 'N/A';
  String get formattedValidUntil => expiryDate != null
      ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
      : 'N/A';
}

class EstimateFinancial {
  final String currencyCode;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String formattedTotal;

  EstimateFinancial({
    required this.currencyCode,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.formattedTotal,
  });

  factory EstimateFinancial.fromJson(Map<String, dynamic> json) {
    return EstimateFinancial(
      currencyCode: json['currency_code']?.toString() ?? 'USD',
      subtotal:
          json['subtotal'] is num ? (json['subtotal'] as num).toDouble() : 0.0,
      discountAmount: json['discount_amount'] is num
          ? (json['discount_amount'] as num).toDouble()
          : 0.0,
      taxAmount: json['tax_amount'] is num
          ? (json['tax_amount'] as num).toDouble()
          : 0.0,
      total: json['total'] is num ? (json['total'] as num).toDouble() : 0.0,
      formattedTotal: json['formatted_total']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency_code': currencyCode,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total': total,
      'formatted_total': formattedTotal,
    };
  }
}

class EstimateConversion {
  final bool convertedToInvoice;
  final bool isConverted;
  final int? invoiceId;
  final EstimateInvoice? invoice;
  final DateTime? convertedAt;

  EstimateConversion({
    required this.convertedToInvoice,
    required this.isConverted,
    this.invoiceId,
    this.invoice,
    this.convertedAt,
  });

  factory EstimateConversion.fromJson(Map<String, dynamic> json) {
    return EstimateConversion(
      convertedToInvoice: json['converted_to_invoice'] == true ||
          json['converted_to_invoice'] == 'true',
      isConverted:
          json['is_converted'] == true || json['is_converted'] == 'true',
      invoiceId: json['invoice_id'] is int
          ? json['invoice_id']
          : (json['invoice_id'] != null
              ? int.tryParse(json['invoice_id'].toString())
              : null),
      invoice: json['invoice'] != null
          ? EstimateInvoice.fromJson(json['invoice'])
          : null,
      convertedAt: json['converted_at'] != null
          ? DateTime.tryParse(json['converted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'converted_to_invoice': convertedToInvoice,
      'is_converted': isConverted,
      'invoice_id': invoiceId,
      'invoice': invoice?.toJson(),
      'converted_at': convertedAt?.toIso8601String(),
    };
  }

  String? get formattedConvertedAt => convertedAt != null
      ? '${convertedAt!.day}/${convertedAt!.month}/${convertedAt!.year}'
      : null;
  String? get invoiceNumber => invoice?.invoiceNumber;
}

class EstimateClient {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? avatar;

  EstimateClient({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.companyName,
    this.avatar,
  });

  factory EstimateClient.fromJson(Map<String, dynamic> json) {
    return EstimateClient(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      companyName: json['company_name']?.toString(),
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company_name': companyName,
      'avatar': avatar,
    };
  }
}

class EstimateAssignedTo {
  final int? id;
  final String? name;
  final String? email;
  final String? avatar;

  EstimateAssignedTo({
    this.id,
    this.name,
    this.email,
    this.avatar,
  });

  factory EstimateAssignedTo.fromJson(Map<String, dynamic> json) {
    return EstimateAssignedTo(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar'] != null
          ? AppConstants.publicUrl + json['avatar']
          : null,
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
}

class EstimateModel {
  final int? id;
  final String? type;
  final String? name;
  final EstimateModelDetails? details;

  EstimateModel({
    this.id,
    this.type,
    this.name,
    this.details,
  });

  factory EstimateModel.fromJson(Map<String, dynamic> json) {
    return EstimateModel(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      type: json['type']?.toString(),
      name: json['name']?.toString(),
      details: json['details'] != null
          ? EstimateModelDetails.fromJson(json['details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'details': details?.toJson(),
    };
  }
}

class EstimateModelDetails {
  final String? name;
  final String? title;

  EstimateModelDetails({
    this.name,
    this.title,
  });

  factory EstimateModelDetails.fromJson(Map<String, dynamic> json) {
    return EstimateModelDetails(
      name: json['name']?.toString(),
      title: json['title']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
    };
  }
}

class EstimateItems {
  final int count;
  final List<EstimateItem> items;

  EstimateItems({
    required this.count,
    required this.items,
  });

  factory EstimateItems.fromJson(Map<String, dynamic> json) {
    List<EstimateItem> parseItems(dynamic itemsData) {
      if (itemsData == null) return [];
      if (itemsData is List) {
        return itemsData
            .map((e) =>
                EstimateItem.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    }

    return EstimateItems(
      count: json['count'] is int
          ? json['count']
          : (int.tryParse(json['count']?.toString() ?? '') ?? 0),
      items: parseItems(json['items']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class EstimateItem {
  final int id;
  final String itemName;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final double tax;
  final double total;
  final int? itemId;
  final String? itemType;

  EstimateItem({
    required this.id,
    required this.itemName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.itemId,
    this.itemType,
  });

  factory EstimateItem.fromJson(Map<String, dynamic> json) {
    return EstimateItem(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      itemName: json['item_name']?.toString() ?? '',
      description: json['description']?.toString(),
      quantity:
          json['quantity'] is num ? (json['quantity'] as num).toDouble() : 0.0,
      unitPrice: json['unit_price'] is num
          ? (json['unit_price'] as num).toDouble()
          : 0.0,
      subtotal:
          json['subtotal'] is num ? (json['subtotal'] as num).toDouble() : 0.0,
      tax: json['tax'] is num ? (json['tax'] as num).toDouble() : 0.0,
      total: json['total'] is num ? (json['total'] as num).toDouble() : 0.0,
      itemId: json['item_id'] is int
          ? json['item_id']
          : (json['item_id'] != null
              ? int.tryParse(json['item_id'].toString())
              : null),
      itemType: json['item_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'item_id': itemId,
      'item_type': itemType,
    };
  }
}

class EstimateInvoice {
  final int? id;
  final String? invoiceNumber;
  final String? status;

  EstimateInvoice({
    this.id,
    this.invoiceNumber,
    this.status,
  });

  factory EstimateInvoice.fromJson(Map<String, dynamic> json) {
    return EstimateInvoice(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      invoiceNumber: json['invoice_number']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'status': status,
    };
  }
}

class EstimateRequests {
  final int count;
  final EstimateRequestLatest? latest;

  EstimateRequests({
    required this.count,
    this.latest,
  });

  factory EstimateRequests.fromJson(Map<String, dynamic> json) {
    return EstimateRequests(
      count: json['count'] is int
          ? json['count']
          : (int.tryParse(json['count']?.toString() ?? '') ?? 0),
      latest: json['latest'] != null
          ? EstimateRequestLatest.fromJson(json['latest'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'latest': latest?.toJson(),
    };
  }
}

class EstimateRequestLatest {
  final int id;
  final String status;
  final DateTime createdAt;

  EstimateRequestLatest({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  factory EstimateRequestLatest.fromJson(Map<String, dynamic> json) {
    return EstimateRequestLatest(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
