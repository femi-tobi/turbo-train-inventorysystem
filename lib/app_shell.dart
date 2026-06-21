import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/models/user_model.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/product_provider.dart';
import 'core/providers/purchase_provider.dart';
import 'core/providers/sale_provider.dart';
import 'core/providers/supplier_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/products/products_screen.dart';
import 'features/purchases/purchases_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/sales/sales_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/suppliers/suppliers_screen.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/sidebar_nav.dart';

class AppShell extends StatefulWidget {
  final UserModel user;

  const AppShell({super.key, required this.user});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Build the ordered list of pages based on role
  List<Widget> _buildPages() {
    final isAdmin = widget.user.isAdmin;
    return [
      const DashboardScreen(),
      if (isAdmin) const ProductsScreen(),
      if (isAdmin) const SuppliersScreen(),
      if (isAdmin) const PurchasesScreen(),
      const SalesScreen(),
      const InventoryScreen(),
      if (isAdmin) const ReportsScreen(),
      if (isAdmin) const SettingsScreen(),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<DashboardProvider>().loadStats(),
      context.read<ProductProvider>().loadProducts(),
      context.read<SupplierProvider>().loadSuppliers(),
      context.read<PurchaseProvider>().loadPurchases(),
      context.read<SaleProvider>().loadSales(),
      if (widget.user.isAdmin)
        context.read<DashboardProvider>().loadUsers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      body: Row(
        children: [
          SidebarNav(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
            user: widget.user,
          ),
          // Vertical divider
          Container(width: 1, color: AppColors.border),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}
