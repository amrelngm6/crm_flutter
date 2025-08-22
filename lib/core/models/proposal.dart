import 'package:medians_ai_crm/core/constants/app_constants.dart';

class Proposal {
  final int id;
  final String title;
  final String? content;
  final ProposalStatus status;
  final ProposalDates dates;
  final ProposalFinancial financial;
  final ProposalConversion conversion;
  final ProposalClient? client;
  final ProposalAssignedTo? assignedTo;
  final ProposalModel model;
  final ProposalItems? items;
  final int businessId;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proposal({
    required this.id,
    required this.title,
    this.content,
    required this.status,
    required this.dates,
    required this.financial,
    required this.conversion,
    this.client,
    this.assignedTo,
    required this.model,
    this.items,
    required this.businessId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      status: ProposalStatus.fromJson(json['status'] ?? {}),
      dates: ProposalDates.fromJson(json['dates'] ?? {}),
      financial: ProposalFinancial.fromJson(json['financial'] ?? {}),
      conversion: ProposalConversion.fromJson(json['conversion'] ?? {}),
      client: json['client'] != null
          ? ProposalClient.fromJson(json['client'])
          : null,
      assignedTo: json['assigned_to'] != null
          ? ProposalAssignedTo.fromJson(json['assigned_to'])
          : null,
      model: ProposalModel.fromJson(json['model'] ?? {}),
      items:
          json['items'] != null ? ProposalItems.fromJson(json['items']) : null,
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
      'title': title,
      'content': content,
      'status': status.toJson(),
      'dates': dates.toJson(),
      'financial': financial.toJson(),
      'conversion': conversion.toJson(),
      'client': client?.toJson(),
      'assigned_to': assignedTo?.toJson(),
      'model': model.toJson(),
      'items': items?.toJson(),
      'business_id': businessId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get statusName => status.name;
  String get statusColor => status.color;
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
  List<ProposalItem> get itemsList => items?.items ?? [];
}

class ProposalStatus {
  final int id;
  final String name;
  final String color;

  ProposalStatus({
    required this.id,
    required this.name,
    required this.color,
  });

  factory ProposalStatus.fromJson(Map<String, dynamic> json) {
    return ProposalStatus(
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

class ProposalDates {
  final DateTime? date;
  final DateTime? expiryDate;
  final bool isExpired;
  final double? daysUntilExpiry;
  final DateTime? convertedAt;

  ProposalDates({
    this.date,
    this.expiryDate,
    required this.isExpired,
    this.daysUntilExpiry,
    this.convertedAt,
  });

  factory ProposalDates.fromJson(Map<String, dynamic> json) {
    return ProposalDates(
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
  String? get formattedConvertedAt => convertedAt != null
      ? '${convertedAt!.day}/${convertedAt!.month}/${convertedAt!.year}'
      : null;
}

class ProposalFinancial {
  final String currencyCode;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String formattedTotal;

  ProposalFinancial({
    required this.currencyCode,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.formattedTotal,
  });

  factory ProposalFinancial.fromJson(Map<String, dynamic> json) {
    return ProposalFinancial(
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

class ProposalConversion {
  final bool convertedToInvoice;
  final bool isConverted;
  final int? invoiceId;
  final ProposalInvoice? invoice;

  ProposalConversion({
    required this.convertedToInvoice,
    required this.isConverted,
    this.invoiceId,
    this.invoice,
  });

  factory ProposalConversion.fromJson(Map<String, dynamic> json) {
    return ProposalConversion(
      convertedToInvoice: json['converted_to_invoice'] == true ||
          json['converted_to_invoice'] == 'true',
      isConverted: json['converted_to_invoice'] == true ||
          json['converted_to_invoice'] == 'true',
      invoiceId: json['invoice_id'] is int
          ? json['invoice_id']
          : (json['invoice_id'] != null
              ? int.tryParse(json['invoice_id'].toString())
              : null),
      invoice: json['invoice'] != null
          ? ProposalInvoice.fromJson(json['invoice'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'converted_to_invoice': convertedToInvoice,
      'invoice_id': invoiceId,
      'invoice': invoice?.toJson(),
    };
  }

  String? get invoiceNumber => invoice?.invoiceNumber;
}

class ProposalClient {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? avatar;

  ProposalClient({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.companyName,
    this.avatar,
  });

  factory ProposalClient.fromJson(Map<String, dynamic> json) {
    return ProposalClient(
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

class ProposalAssignedTo {
  final int? id;
  final String? name;
  final String? email;
  final String? avatar;

  ProposalAssignedTo({
    this.id,
    this.name,
    this.email,
    this.avatar,
  });

  factory ProposalAssignedTo.fromJson(Map<String, dynamic> json) {
    return ProposalAssignedTo(
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

class ProposalModel {
  final int? id;
  final String? type;
  final String? name;
  final ProposalModelDetails? details;

  ProposalModel({
    this.id,
    this.type,
    this.name,
    this.details,
  });

  factory ProposalModel.fromJson(Map<String, dynamic> json) {
    return ProposalModel(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      type: json['type']?.toString(),
      name: json['name']?.toString(),
      details: json['details'] != null
          ? ProposalModelDetails.fromJson(json['details'])
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

class ProposalModelDetails {
  final String? name;
  final String? title;

  ProposalModelDetails({
    this.name,
    this.title,
  });

  factory ProposalModelDetails.fromJson(Map<String, dynamic> json) {
    return ProposalModelDetails(
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

class ProposalItems {
  final int count;
  final List<ProposalItem> items;

  ProposalItems({
    required this.count,
    required this.items,
  });

  factory ProposalItems.fromJson(Map<String, dynamic> json) {
    List<ProposalItem> parseItems(dynamic itemsData) {
      if (itemsData == null) return [];
      if (itemsData is List) {
        return itemsData
            .map((e) =>
                ProposalItem.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
      return [];
    }

    return ProposalItems(
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

class ProposalItem {
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

  ProposalItem({
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

  factory ProposalItem.fromJson(Map<String, dynamic> json) {
    return ProposalItem(
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

class ProposalInvoice {
  final int? id;
  final String? invoiceNumber;
  final String? status;

  ProposalInvoice({
    this.id,
    this.invoiceNumber,
    this.status,
  });

  factory ProposalInvoice.fromJson(Map<String, dynamic> json) {
    return ProposalInvoice(
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

// Available Item model for selection
class AvailableItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? unit;
  final AvailableItemGroup? group;

  AvailableItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.unit,
    this.group,
  });

  factory AvailableItem.fromJson(Map<String, dynamic> json) {
    return AvailableItem(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0.0,
      unit: json['unit']?.toString(),
      group: json['group'] != null
          ? AvailableItemGroup.fromJson(json['group'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'group': group?.toJson(),
    };
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
}

class AvailableItemGroup {
  final int id;
  final String name;
  final int itemsCount;

  AvailableItemGroup({
    required this.id,
    required this.name,
    required this.itemsCount,
  });

  factory AvailableItemGroup.fromJson(Map<String, dynamic> json) {
    return AvailableItemGroup(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
      itemsCount: json['items_count'] is int
          ? json['items_count']
          : (int.tryParse(json['items_count']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items_count': itemsCount,
    };
  }
}
