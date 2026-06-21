class SaleModel {
  final int? id;
  final DateTime saleDate;
  final int productId;
  final String saleType; // 'wholesale' or 'retail'
  final double qtyPacks; // pack-equivalent quantity
  final double qtyPieces; // actual pieces (full qty for retail, units_per_pack * packs for wholesale)
  final double unitPrice; // price per pack (wholesale) or per piece (retail)
  final double totalAmount;
  final double cogs;
  final double grossProfit;
  final String receiptId;
  final DateTime createdAt;

  // Joined fields
  final String? productName;
  final String? productCode;
  final String? brand;

  SaleModel({
    this.id,
    required this.saleDate,
    required this.productId,
    required this.saleType,
    required this.qtyPacks,
    required this.qtyPieces,
    required this.unitPrice,
    required this.totalAmount,
    required this.cogs,
    required this.grossProfit,
    required this.receiptId,
    required this.createdAt,
    this.productName,
    this.productCode,
    this.brand,
  });

  String get customerType =>
      saleType == 'wholesale' ? 'Wholesale Customer' : 'Retail Customer';

  String get saleTypeLabel =>
      saleType == 'wholesale' ? 'Wholesale' : 'Retail';

  Map<String, dynamic> toMap() => {
        'id': id,
        'sale_date': saleDate.toIso8601String(),
        'product_id': productId,
        'sale_type': saleType,
        'qty_packs': qtyPacks,
        'qty_pieces': qtyPieces,
        'unit_price': unitPrice,
        'total_amount': totalAmount,
        'cogs': cogs,
        'gross_profit': grossProfit,
        'receipt_id': receiptId,
        'created_at': createdAt.toIso8601String(),
      };

  factory SaleModel.fromMap(Map<String, dynamic> map) => SaleModel(
        id: map['id'] as int?,
        saleDate: DateTime.parse(map['sale_date'] as String),
        productId: map['product_id'] as int,
        saleType: map['sale_type'] as String,
        qtyPacks: (map['qty_packs'] as num).toDouble(),
        qtyPieces: (map['qty_pieces'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
        totalAmount: (map['total_amount'] as num).toDouble(),
        cogs: (map['cogs'] as num).toDouble(),
        grossProfit: (map['gross_profit'] as num).toDouble(),
        receiptId: map['receipt_id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        productName: map['product_name'] as String?,
        productCode: map['product_code'] as String?,
        brand: map['brand'] as String?,
      );
}
