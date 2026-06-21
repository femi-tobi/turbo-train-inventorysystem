import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/product_model.dart';
import '../models/purchase_model.dart';
import '../models/sale_model.dart';
import '../models/supplier_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(appDir.path, 'LagosStore'));
    if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
    final dbPath = p.join(dbDir.path, 'inventory.db');

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'staff',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        category TEXT NOT NULL,
        supplier_id INTEGER NOT NULL,
        barcode TEXT,
        units_per_pack INTEGER NOT NULL DEFAULT 1,
        cost_price_per_pack REAL NOT NULL DEFAULT 0,
        wholesale_price_per_pack REAL NOT NULL DEFAULT 0,
        retail_price_per_piece REAL NOT NULL DEFAULT 0,
        reorder_level INTEGER NOT NULL DEFAULT 0,
        stock_packs REAL NOT NULL DEFAULT 0,
        avg_cost_per_pack REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_date TEXT NOT NULL,
        supplier_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty_packs REAL NOT NULL,
        cost_price_per_pack REAL NOT NULL,
        total_cost REAL NOT NULL,
        invoice_number TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_date TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        sale_type TEXT NOT NULL,
        qty_packs REAL NOT NULL,
        qty_pieces REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        cogs REAL NOT NULL,
        gross_profit REAL NOT NULL,
        receipt_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Seed default accounts
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'username': 'admin',
      'password_hash': _hash('admin123'),
      'role': 'admin',
      'created_at': now,
    });
    await db.insert('users', {
      'username': 'staff',
      'password_hash': _hash('staff123'),
      'role': 'staff',
      'created_at': now,
    });
  }

  static String _hash(String raw) {
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString();
  }

  // ───────────────────────── USERS ─────────────────────────

  Future<List<UserModel>> getUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'username ASC');
    return rows.map(UserModel.fromMap).toList();
  }

  Future<UserModel?> authenticate(String username, String password) async {
    final db = await database;
    final rows = await db.query('users',
        where: 'username = ? AND password_hash = ?',
        whereArgs: [username, _hash(password)]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<int> createUser(
      {required String username,
      required String rawPassword,
      required String role}) async {
    final db = await database;
    return await db.insert('users', {
      'username': username,
      'password_hash': _hash(rawPassword),
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateUser(int id,
      {String? username, String? rawPassword, String? role}) async {
    final db = await database;
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (rawPassword != null && rawPassword.isNotEmpty) {
      data['password_hash'] = _hash(rawPassword);
    }
    if (role != null) data['role'] = role;
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────── SUPPLIERS ─────────────────────────

  Future<List<SupplierModel>> getSuppliers() async {
    final db = await database;
    final rows = await db.query('suppliers', orderBy: 'name ASC');
    return rows.map(SupplierModel.fromMap).toList();
  }

  Future<int> insertSupplier(SupplierModel s) async {
    final db = await database;
    final map = s.toMap()..remove('id');
    return await db.insert('suppliers', map);
  }

  Future<void> updateSupplier(SupplierModel s) async {
    final db = await database;
    await db.update('suppliers', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  Future<void> deleteSupplier(int id) async {
    final db = await database;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────── PRODUCTS ─────────────────────────

  Future<List<ProductModel>> getProducts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM products p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      ORDER BY p.brand ASC, p.name ASC
    ''');
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM products p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    final map = product.toMap()..remove('id');
    return await db.insert('products', map);
  }

  Future<void> updateProduct(ProductModel product) async {
    final db = await database;
    await db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ───────────────────────── PURCHASES ─────────────────────────

  Future<List<PurchaseModel>> getPurchases({
    String? dateFrom,
    String? dateTo,
    int? supplierId,
    int? productId,
  }) async {
    final db = await database;
    var q = '''
      SELECT pu.*, s.name as supplier_name,
             p.name as product_name, p.code as product_code
      FROM purchases pu
      LEFT JOIN suppliers s ON pu.supplier_id = s.id
      LEFT JOIN products p ON pu.product_id = p.id
      WHERE 1=1
    ''';
    final args = <dynamic>[];
    if (dateFrom != null) {
      q += ' AND pu.purchase_date >= ?';
      args.add('$dateFrom 00:00:00');
    }
    if (dateTo != null) {
      q += ' AND pu.purchase_date <= ?';
      args.add('$dateTo 23:59:59');
    }
    if (supplierId != null) {
      q += ' AND pu.supplier_id = ?';
      args.add(supplierId);
    }
    if (productId != null) {
      q += ' AND pu.product_id = ?';
      args.add(productId);
    }
    q += ' ORDER BY pu.purchase_date DESC';
    final rows = await db.rawQuery(q, args);
    return rows.map(PurchaseModel.fromMap).toList();
  }

  Future<int> insertPurchase(PurchaseModel purchase) async {
    final db = await database;
    final product = await getProductById(purchase.productId);
    if (product == null) throw Exception('Product not found');

    final oldStock = product.stockPacks;
    final oldCost = product.avgCostPerPack;
    final newQty = purchase.qtyPacks;
    final newCost = purchase.costPricePerPack;

    final newStock = oldStock + newQty;
    final newAvgCost = newStock == 0
        ? newCost
        : (oldStock * oldCost + newQty * newCost) / newStock;

    return await db.transaction((txn) async {
      final id = await txn.insert('purchases', purchase.toMap()..remove('id'));
      await txn.update(
        'products',
        {'stock_packs': newStock, 'avg_cost_per_pack': newAvgCost},
        where: 'id = ?',
        whereArgs: [purchase.productId],
      );
      return id;
    });
  }

  // ───────────────────────── SALES ─────────────────────────

  Future<List<SaleModel>> getSales({
    String? dateFrom,
    String? dateTo,
    int? productId,
    String? saleType,
  }) async {
    final db = await database;
    var q = '''
      SELECT sa.*, p.name as product_name, p.code as product_code, p.brand
      FROM sales sa
      LEFT JOIN products p ON sa.product_id = p.id
      WHERE 1=1
    ''';
    final args = <dynamic>[];
    if (dateFrom != null) {
      q += ' AND sa.sale_date >= ?';
      args.add('$dateFrom 00:00:00');
    }
    if (dateTo != null) {
      q += ' AND sa.sale_date <= ?';
      args.add('$dateTo 23:59:59');
    }
    if (productId != null) {
      q += ' AND sa.product_id = ?';
      args.add(productId);
    }
    if (saleType != null && saleType != 'all') {
      q += ' AND sa.sale_type = ?';
      args.add(saleType);
    }
    q += ' ORDER BY sa.sale_date DESC';
    final rows = await db.rawQuery(q, args);
    return rows.map(SaleModel.fromMap).toList();
  }

  Future<int> insertSale(SaleModel sale) async {
    final db = await database;
    final product = await getProductById(sale.productId);
    if (product == null) throw Exception('Product not found');

    if (product.stockPacks < sale.qtyPacks) {
      throw Exception(
        'Insufficient stock.\n'
        'Available: ${product.stockPacks.toStringAsFixed(2)} packs '
        '(${product.stockPieces.toStringAsFixed(0)} pieces)',
      );
    }

    final newStock = product.stockPacks - sale.qtyPacks;

    return await db.transaction((txn) async {
      final id = await txn.insert('sales', sale.toMap()..remove('id'));
      await txn.update(
        'products',
        {'stock_packs': newStock},
        where: 'id = ?',
        whereArgs: [sale.productId],
      );
      return id;
    });
  }

  // ───────────────────────── DASHBOARD ─────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final monthStart =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

    final productCount = (await db.rawQuery('SELECT COUNT(*) FROM products'))
            .first.values.first as int? ??
        0;

    final brandCount = (await db
            .rawQuery('SELECT COUNT(DISTINCT brand) FROM products'))
            .first.values.first as int? ??
        0;

    final totalStockPacks =
        (await db.rawQuery('SELECT SUM(stock_packs) as v FROM products'))
                .first['v'] as double? ??
            0.0;

    final totalInventoryValue = (await db.rawQuery(
                'SELECT SUM(stock_packs * avg_cost_per_pack) as v FROM products'))
            .first['v'] as double? ??
        0.0;

    final todaySales = (await db.rawQuery(
                'SELECT SUM(total_amount) as v FROM sales WHERE sale_date >= ? AND sale_date <= ?',
                ['$today 00:00:00', '$today 23:59:59']))
            .first['v'] as double? ??
        0.0;

    final monthSales = (await db.rawQuery(
                'SELECT SUM(total_amount) as v FROM sales WHERE sale_date >= ?',
                ['$monthStart 00:00:00']))
            .first['v'] as double? ??
        0.0;

    final monthProfit = (await db.rawQuery(
                'SELECT SUM(gross_profit) as v FROM sales WHERE sale_date >= ?',
                ['$monthStart 00:00:00']))
            .first['v'] as double? ??
        0.0;

    final lowStockCount = (await db.rawQuery(
            'SELECT COUNT(*) FROM products WHERE stock_packs <= reorder_level AND stock_packs > 0'))
            .first.values.first as int? ??
        0;

    final outOfStockCount = (await db.rawQuery(
            'SELECT COUNT(*) FROM products WHERE stock_packs <= 0'))
            .first.values.first as int? ??
        0;

    final recentSales = await db.rawQuery('''
      SELECT sa.*, p.name as product_name, p.brand
      FROM sales sa
      LEFT JOIN products p ON sa.product_id = p.id
      ORDER BY sa.created_at DESC LIMIT 8
    ''');

    return {
      'productCount': productCount,
      'brandCount': brandCount,
      'totalStockPacks': totalStockPacks,
      'totalInventoryValue': totalInventoryValue,
      'todaySales': todaySales,
      'monthSales': monthSales,
      'monthProfit': monthProfit,
      'lowStockCount': lowStockCount,
      'outOfStockCount': outOfStockCount,
      'recentSales': recentSales,
    };
  }

  // ───────────────────────── REPORTS ─────────────────────────

  Future<List<Map<String, dynamic>>> reportInventoryByBrand() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT brand, name as product_name,
             stock_packs,
             stock_packs * units_per_pack as stock_pieces,
             stock_packs * avg_cost_per_pack as inventory_value
      FROM products
      ORDER BY brand ASC, name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> reportSales({
    String? dateFrom,
    String? dateTo,
    int? productId,
    String? saleType,
  }) async {
    final sales = await getSales(
        dateFrom: dateFrom,
        dateTo: dateTo,
        productId: productId,
        saleType: saleType);
    return sales.map((s) => s.toMap()
      ..['product_name'] = s.productName
      ..['sale_type_label'] = s.saleTypeLabel).toList();
  }

  Future<List<Map<String, dynamic>>> reportDailySales() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        DATE(sale_date) as sale_day,
        SUM(CASE WHEN sale_type='wholesale' THEN total_amount ELSE 0 END) as wholesale_amount,
        SUM(CASE WHEN sale_type='retail'    THEN total_amount ELSE 0 END) as retail_amount,
        SUM(total_amount) as total_amount
      FROM sales
      GROUP BY DATE(sale_date)
      ORDER BY sale_day DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> reportMonthlySales() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        strftime('%Y-%m', sale_date) as sale_month,
        SUM(CASE WHEN sale_type='wholesale' THEN total_amount ELSE 0 END) as wholesale_amount,
        SUM(CASE WHEN sale_type='retail'    THEN total_amount ELSE 0 END) as retail_amount,
        SUM(total_amount) as total_amount
      FROM sales
      GROUP BY strftime('%Y-%m', sale_date)
      ORDER BY sale_month DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> reportPurchases({
    String? dateFrom,
    String? dateTo,
  }) async {
    final purchases =
        await getPurchases(dateFrom: dateFrom, dateTo: dateTo);
    return purchases.map((pu) => pu.toMap()
      ..['supplier_name'] = pu.supplierName
      ..['product_name'] = pu.productName).toList();
  }

  Future<List<Map<String, dynamic>>> reportProfit() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        p.name as product_name,
        SUM(sa.total_amount) as sales_revenue,
        SUM(sa.cogs) as total_cogs,
        SUM(sa.gross_profit) as gross_profit
      FROM sales sa
      LEFT JOIN products p ON sa.product_id = p.id
      GROUP BY sa.product_id, p.name
      ORDER BY gross_profit DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> reportBrandPerformance() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        p.brand,
        SUM(sa.qty_pieces) as qty_sold,
        SUM(sa.total_amount) as sales_amount,
        SUM(sa.gross_profit) as profit
      FROM sales sa
      LEFT JOIN products p ON sa.product_id = p.id
      GROUP BY p.brand
      ORDER BY sales_amount DESC
    ''');
  }

  // ───────────────────────── BACKUP ─────────────────────────

  Future<String> getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'LagosStore', 'inventory.db');
  }
}
