import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/supplier_model.dart';

class SupplierProvider extends ChangeNotifier {
  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _suppliers = await _db.getSuppliers();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    await _db.insertSupplier(supplier);
    await loadSuppliers();
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    await _db.updateSupplier(supplier);
    await loadSuppliers();
  }

  Future<void> deleteSupplier(int id) async {
    await _db.deleteSupplier(id);
    await loadSuppliers();
  }
}
