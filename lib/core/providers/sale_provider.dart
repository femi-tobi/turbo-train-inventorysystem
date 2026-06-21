import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/sale_model.dart';

class SaleProvider extends ChangeNotifier {
  List<SaleModel> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<SaleModel> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadSales({
    String? dateFrom,
    String? dateTo,
    int? productId,
    String? saleType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _sales = await _db.getSales(
        dateFrom: dateFrom,
        dateTo: dateTo,
        productId: productId,
        saleType: saleType,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Returns the newly created SaleModel on success, or throws on failure.
  Future<SaleModel> addSale(SaleModel sale) async {
    final id = await _db.insertSale(sale);
    final created = SaleModel(
      id: id,
      saleDate: sale.saleDate,
      productId: sale.productId,
      saleType: sale.saleType,
      qtyPacks: sale.qtyPacks,
      qtyPieces: sale.qtyPieces,
      unitPrice: sale.unitPrice,
      totalAmount: sale.totalAmount,
      cogs: sale.cogs,
      grossProfit: sale.grossProfit,
      receiptId: sale.receiptId,
      createdAt: sale.createdAt,
      productName: sale.productName,
      productCode: sale.productCode,
      brand: sale.brand,
    );
    await loadSales();
    return created;
  }
}
