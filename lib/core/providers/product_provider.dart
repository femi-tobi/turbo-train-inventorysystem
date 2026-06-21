import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  List<ProductModel> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _db.getProducts();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    await _db.insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    await loadProducts();
  }

  ProductModel? getById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
