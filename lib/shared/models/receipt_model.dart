class ReceiptItem {
  final String itemName;
  final String itemNameRaw;
  final String category;
  final int unitPrice;
  final int quantity;
  final int amount;
  final int points; // 医療レシートの場合の点数（通常は0）

  ReceiptItem({
    required this.itemName,
    required this.itemNameRaw,
    required this.category,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
    this.points = 0,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        itemName: json['item_name'] as String,
        itemNameRaw: json['item_name_raw'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        unitPrice: (json['unit_price'] as num).toInt(),
        quantity: (json['quantity'] as num).toInt(),
        amount: (json['amount'] as num).toInt(),
        points: (json['points'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'item_name': itemName,
        'item_name_raw': itemNameRaw,
        'category': category,
        'unit_price': unitPrice,
        'quantity': quantity,
        'amount': amount,
        'points': points,
      };

  ReceiptItem copyWith({
    String? itemName,
    String? category,
    int? unitPrice,
    int? quantity,
    int? amount,
  }) =>
      ReceiptItem(
        itemName: itemName ?? this.itemName,
        itemNameRaw: itemNameRaw,
        category: category ?? this.category,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
        amount: amount ?? this.amount,
        points: points,
      );
}

class CouponDetected {
  final String description;
  final int discountAmount;
  final String? validFrom;
  final String? validUntil;
  final String? storageLocation;

  CouponDetected({
    required this.description,
    required this.discountAmount,
    this.validFrom,
    this.validUntil,
    this.storageLocation,
  });

  factory CouponDetected.fromJson(Map<String, dynamic> json) => CouponDetected(
        description: json['description'] as String,
        discountAmount: (json['discount_amount'] as num).toInt(),
        validFrom: json['valid_from'] as String?,
        validUntil: json['valid_until'] as String?,
        storageLocation: json['storage_location'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'discount_amount': discountAmount,
        if (validFrom != null) 'valid_from': validFrom,
        if (validUntil != null) 'valid_until': validUntil,
        if (storageLocation != null) 'storage_location': storageLocation,
      };
}

class ReceiptAnalysis {
  final String storeName;
  final String purchasedAt;
  final int totalAmount;
  final int? taxAmount;
  final String paymentMethod;
  final String? category;
  final List<ReceiptItem> items;
  final List<CouponDetected> couponsDetected;
  final String duplicateCheckHash;
  final bool isMedical;
  final int? totalPoints; // 医療レシートの場合の合計点数
  final double? burdenRate; // 負担率（例: 0.3）

  ReceiptAnalysis({
    required this.storeName,
    required this.purchasedAt,
    required this.totalAmount,
    this.taxAmount,
    required this.paymentMethod,
    this.category,
    required this.items,
    required this.couponsDetected,
    required this.duplicateCheckHash,
    this.isMedical = false,
    this.totalPoints,
    this.burdenRate,
  });

  factory ReceiptAnalysis.fromJson(Map<String, dynamic> json) =>
      ReceiptAnalysis(
        storeName: json['store_name'] as String,
        purchasedAt: json['purchased_at'] as String,
        totalAmount: (json['total_amount'] as num).toInt(),
        taxAmount: json['tax_amount'] != null
            ? (json['tax_amount'] as num).toInt()
            : null,
        paymentMethod: json['payment_method'] as String? ?? 'cash',
        items: (json['items'] as List<dynamic>)
            .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        couponsDetected: (json['coupons_detected'] as List<dynamic>? ?? [])
            .map((e) => CouponDetected.fromJson(e as Map<String, dynamic>))
            .toList(),
        duplicateCheckHash: json['duplicate_check_hash'] as String? ?? '',
        isMedical: json['is_medical'] as bool? ?? false,
        totalPoints: (json['total_points'] as num?)?.toInt(),
        burdenRate: (json['burden_rate'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'store_name': storeName,
        'purchased_at': purchasedAt,
        'total_amount': totalAmount,
        if (taxAmount != null) 'tax_amount': taxAmount,
        'payment_method': paymentMethod,
        if (category != null) 'category': category,
        'items': items.map((e) => e.toJson()).toList(),
        'coupons_detected': couponsDetected.map((e) => e.toJson()).toList(),
        'duplicate_check_hash': duplicateCheckHash,
        'is_medical': isMedical,
        if (totalPoints != null) 'total_points': totalPoints,
        if (burdenRate != null) 'burden_rate': burdenRate,
      };
}

class ReceiptDiscount {
  final String description;
  final int discountAmount;

  ReceiptDiscount({required this.description, required this.discountAmount});

  factory ReceiptDiscount.fromJson(Map<String, dynamic> json) => ReceiptDiscount(
        description: json['description'] as String,
        discountAmount: (json['discount_amount'] as num).toInt(),
      );
}

class Receipt {
  final String receiptId;
  final String storeName;
  final int totalAmount;
  final String purchasedAt;
  final String paymentMethod;
  final List<ReceiptItem> items;
  final List<ReceiptDiscount> discounts;

  Receipt({
    required this.receiptId,
    required this.storeName,
    required this.totalAmount,
    required this.purchasedAt,
    required this.paymentMethod,
    required this.items,
    this.discounts = const [],
  });

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        receiptId: json['receipt_id'] as String,
        storeName: json['store_name'] as String,
        totalAmount: (json['total_amount'] as num).toInt(),
        purchasedAt: json['purchased_at'] as String,
        paymentMethod: json['payment_method'] as String? ?? 'cash',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        discounts: (json['discounts'] as List<dynamic>? ?? [])
            .map((e) => ReceiptDiscount.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
