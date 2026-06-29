import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/page_header.dart';
import 'import_products_dialog.dart';
import 'product_form_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';
  String _filterBrand = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final all = provider.products;
    final brands = ['All', ...(all.map((p) => p.brand).toSet().toList()..sort())];

    final filtered = all.where((p) {
      final matchSearch = _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.code.toLowerCase().contains(_search.toLowerCase()) ||
          p.brand.toLowerCase().contains(_search.toLowerCase());
      final matchBrand = _filterBrand == 'All' || p.brand == _filterBrand;
      return matchSearch && matchBrand;
    }).toList();

    return Column(
      children: [
        PageHeader(
          title: 'Products',
          subtitle: '${all.length} products across ${brands.length - 1} brands',
          actions: [
            HeaderButton(
              label: 'Import from Excel',
              icon: Icons.upload_file,
              isPrimary: false,
              onPressed: () => _showImport(context),
            ),
            const SizedBox(width: 8),
            HeaderButton(
              label: 'Add Product',
              icon: Icons.add,
              isPrimary: true,
              onPressed: () => _showForm(context),
            ),
          ],
        ),

        // Filter bar
        Container(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, code or brand…',
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _filterBrand,
                    dropdownColor: AppColors.card,
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    items: brands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setState(() => _filterBrand = v!),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Table
        Expanded(
          child: provider.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent))
              : filtered.isEmpty
                  ? _empty()
                  : _buildTable(context, filtered),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, List<ProductModel> items) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        child: Container(
          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: AppColors.isDark ? Border.all(color: AppColors.border) : null,
                            boxShadow: AppColors.cardShadow,
                          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(90),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FixedColumnWidth(80),
                5: FixedColumnWidth(100),
                6: FixedColumnWidth(110),
                7: FixedColumnWidth(110),
                8: FixedColumnWidth(90),
                9: FixedColumnWidth(100),
              },
              children: [
                _headerRow(['Code', 'Product Name', 'Brand', 'Category',
                    'UPP', 'Cost/Pack', 'Wholesale', 'Retail', 'Stock', 'Actions']),
                ...items.asMap().entries.map((e) =>
                    _dataRow(context, e.value, e.key)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _headerRow(List<String> cols) {
    return TableRow(
      decoration: BoxDecoration(color: AppColors.surface),
      children: cols
          .map((c) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Text(c,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
              ))
          .toList(),
    );
  }

  TableRow _dataRow(
      BuildContext context, ProductModel p, int index) {
    final bg = index.isEven ? AppColors.card : AppColors.cardHover;
    Color stockColor = AppColors.textPrimary;
    if (p.isOutOfStock) stockColor = AppColors.error;
    if (p.isLowStock) stockColor = AppColors.warning;

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _cell(p.code, mono: true),
        _cell(p.name),
        _cell(p.brand),
        _cell(p.category),
        _cell('${p.unitsPerPack}'),
        _cell(formatNaira(p.costPricePerPack)),
        _cell(formatNaira(p.wholesalePricePerPack)),
        _cell(formatNaira(p.retailPricePerPiece)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            '${formatNumber(p.stockPacks)} pk',
            style: TextStyle(
                color: stockColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.edit_outlined, AppColors.info, () =>
                  _showForm(context, product: p)),
              const SizedBox(width: 4),
              _iconBtn(Icons.delete_outline, AppColors.error, () =>
                  _confirmDelete(context, p)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, {bool mono = false}) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(text,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: mono ? 'monospace' : 'Inter')),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No products found',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );

  void _showImport(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ImportProductsDialog(),
    );
  }

  void _showForm(BuildContext context, {ProductModel? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(product: product),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ProductProvider>().deleteProduct(p.id!);
      context.read<DashboardProvider>().loadStats();
    }
  }
}
