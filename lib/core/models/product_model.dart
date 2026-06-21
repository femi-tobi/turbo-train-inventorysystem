class ProductModel {
  final int? id;
  final String code;
  final String name;
  final String brand;
  final String category;
  final int supplierId;
  final String? barcode;
  final int unitsPerPack;
  final double costPricePerPack;
  final double wholesalePricePerPack;
  final double retailPricePerPiece;
  final int reorderLevel;
  final double stockPacks;
  final double avgCostPerPack;
  final DateTime createdAt;

  // Joined field from suppliers table
  final String? supplierName;

  ProductModel({
    this.id,
    required this.code,
    required this.name,
    required this.brand,
    required this.category,
    required this.supplierId,
    this.barcode,
    required this.unitsPerPack,
    required this.costPricePerPack,
    required this.wholesalePricePerPack,
    required this.retailPricePerPiece,
    required this.reorderLevel,
    this.stockPacks = 0,
    this.avgCostPerPack = 0,
    required this.createdAt,
    this.supplierName,
  });

  double get costPricePerPiece =>
      unitsPerPack > 0 ? costPricePerPack / unitsPerPack : 0;

  double get stockPieces => stockPacks * unitsPerPack;

  double get inventoryValue => stockPacks * avgCostPerPack;

  bool get isLowStock => stockPacks <= reorderLevel && stockPacks > 0;

  bool get isOutOfStock => stockPacks <= 0;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'name': name,
        'brand': brand,
        'category': category,
        'supplier_id': supplierId,
        'barcode': barcode,
        'units_per_pack': unitsPerPack,
        'cost_price_per_pack': costPricePerPack,
        'wholesale_price_per_pack': wholesalePricePerPack,
        'retail_price_per_piece': retailPricePerPiece,
        'reorder_level': reorderLevel,
        'stock_packs': stockPacks,
        'avg_cost_per_pack': avgCostPerPack,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'] as int?,
        code: map['code'] as String,
        name: map['name'] as String,
        brand: map['brand'] as String,
        category: map['category'] as String,
        supplierId: map['supplier_id'] as int,
        barcode: map['barcode'] as String?,
        unitsPerPack: map['units_per_pack'] as int,
        costPricePerPack: (map['cost_price_per_pack'] as num).toDouble(),
        wholesalePricePerPack:
            (map['wholesale_price_per_pack'] as num).toDouble(),
        retailPricePerPiece: (map['retail_price_per_piece'] as num).toDouble(),
        reorderLevel: map['reorder_level'] as int,
        stockPacks: (map['stock_packs'] as num).toDouble(),
        avgCostPerPack: (map['avg_cost_per_pack'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        supplierName: map['supplier_name'] as String?,
      );

  ProductModel copyWith({
    double? stockPacks,
    double? avgCostPerPack,
  }) =>
      ProductModel(
        id: id,
        code: code,
        name: name,
        brand: brand,
        category: category,
        supplierId: supplierId,
        barcode: barcode,
        unitsPerPack: unitsPerPack,
        costPricePerPack: costPricePerPack,
        wholesalePricePerPack: wholesalePricePerPack,
        retailPricePerPiece: retailPricePerPiece,
        reorderLevel: reorderLevel,
        stockPacks: stockPacks ?? this.stockPacks,
        avgCostPerPack: avgCostPerPack ?? this.avgCostPerPack,
        createdAt: createdAt,
        supplierName: supplierName,
      );
}
