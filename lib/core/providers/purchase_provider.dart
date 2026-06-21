import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/purchase_model.dart';

class PurchaseProvider extends ChangeNotifier {
  List<PurchaseModel> _purchases = [];
  bool _isLoading = false;
  String? _error;

  List<PurchaseModel> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadPurchases({
    String? dateFrom,
    String? dateTo,
    int? supplierId,
    int? productId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _purchases = await _db.getPurchases(
        dateFrom: dateFrom,
        dateTo: dateTo,
        supplierId: supplierId,
        productId: productId,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    await _db.insertPurchase(purchase);
    await loadPurchases();
  }
}
