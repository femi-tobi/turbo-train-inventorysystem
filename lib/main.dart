import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_shell.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/product_provider.dart';
import 'core/providers/purchase_provider.dart';
import 'core/providers/sale_provider.dart';
import 'core/providers/supplier_provider.dart';
import 'features/auth/login_screen.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SQLite FFI for Windows/Linux/macOS desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const LagosStoreApp());
}

class LagosStoreApp extends StatelessWidget {
  const LagosStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'Lagos Store — Inventory',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Switches between LoginScreen and AppShell based on auth state.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    return AppShell(user: auth.currentUser!);
  }
}
