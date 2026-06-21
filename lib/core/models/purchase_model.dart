class PurchaseModel {
  final int? id;
  final DateTime purchaseDate;
  final int supplierId;
  final int productId;
  final double qtyPacks;
  final double costPricePerPack;
  final double totalCost;
  final String? invoiceNumber;
  final DateTime createdAt;

  // Joined fields
  final String? supplierName;
  final String? productName;
  final String? productCode;

  PurchaseModel({
    this.id,
    required this.purchaseDate,
    required this.supplierId,
    required this.productId,
    required this.qtyPacks,
    required this.costPricePerPack,
    required this.totalCost,
    this.invoiceNumber,
    required this.createdAt,
    this.supplierName,
    this.productName,
    this.productCode,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'purchase_date': purchaseDate.toIso8601String(),
        'supplier_id': supplierId,
        'product_id': productId,
        'qty_packs': qtyPacks,
        'cost_price_per_pack': costPricePerPack,
        'total_cost': totalCost,
        'invoice_number': invoiceNumber,
        'created_at': createdAt.toIso8601String(),
      };

  factory PurchaseModel.fromMap(Map<String, dynamic> map) => PurchaseModel(
        id: map['id'] as int?,
        purchaseDate: DateTime.parse(map['purchase_date'] as String),
        supplierId: map['supplier_id'] as int,
        productId: map['product_id'] as int,
        qtyPacks: (map['qty_packs'] as num).toDouble(),
        costPricePerPack: (map['cost_price_per_pack'] as num).toDouble(),
        totalCost: (map['total_cost'] as num).toDouble(),
        invoiceNumber: map['invoice_number'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        supplierName: map['supplier_name'] as String?,
        productName: map['product_name'] as String?,
        productCode: map['product_code'] as String?,
      );
}
