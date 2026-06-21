import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get productCount => _stats['productCount'] as int? ?? 0;
  int get brandCount => _stats['brandCount'] as int? ?? 0;
  double get totalStockPacks => _stats['totalStockPacks'] as double? ?? 0.0;
  double get totalInventoryValue =>
      _stats['totalInventoryValue'] as double? ?? 0.0;
  double get todaySales => _stats['todaySales'] as double? ?? 0.0;
  double get monthSales => _stats['monthSales'] as double? ?? 0.0;
  double get monthProfit => _stats['monthProfit'] as double? ?? 0.0;
  int get lowStockCount => _stats['lowStockCount'] as int? ?? 0;
  int get outOfStockCount => _stats['outOfStockCount'] as int? ?? 0;
  List<Map<String, dynamic>> get recentSales =>
      (_stats['recentSales'] as List?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  final DatabaseHelper _db = DatabaseHelper();

  // User management
  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _db.getDashboardStats();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    try {
      _users = await _db.getUsers();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createUser(
      String username, String rawPassword, String role) async {
    await _db.createUser(
        username: username, rawPassword: rawPassword, role: role);
    await loadUsers();
  }

  Future<void> updateUser(int id,
      {String? username, String? rawPassword, String? role}) async {
    await _db.updateUser(id,
        username: username, rawPassword: rawPassword, role: role);
    await loadUsers();
  }

  Future<void> deleteUser(int id) async {
    await _db.deleteUser(id);
    await loadUsers();
  }
}
