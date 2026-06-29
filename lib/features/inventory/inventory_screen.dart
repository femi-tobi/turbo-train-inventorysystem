import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/page_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';
  String _filter = 'All'; // All, Low Stock, Out of Stock

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final all = prov.products;

    final filtered = all.where((p) {
      final matchSearch = _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.brand.toLowerCase().contains(_search.toLowerCase());
      final matchFilter = _filter == 'All' ||
          (_filter == 'Low Stock' && p.isLowStock) ||
          (_filter == 'Out of Stock' && p.isOutOfStock);
      return matchSearch && matchFilter;
    }).toList();

    final totalValue =
        all.fold<double>(0, (s, p) => s + p.inventoryValue);
    final lowCount = all.where((p) => p.isLowStock).length;
    final outCount = all.where((p) => p.isOutOfStock).length;

    return Column(
      children: [
        PageHeader(
          title: 'Inventory',
          subtitle:
              '${all.length} products  •  Value: ${formatNaira(totalValue)}',
          actions: [
            IconButton(
              onPressed: () => prov.loadProducts(),
              icon: Icon(Icons.refresh_rounded,
                  color: AppColors.textSecondary),
              tooltip: 'Refresh',
            ),
          ],
        ),

        // Summary chips
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
          child: Row(
            children: [
              _chip('All', all.length, Colors.transparent, AppColors.textSecondary),
              SizedBox(width: 8),
              _chip('Low Stock', lowCount, AppColors.warningBg, AppColors.warning),
              SizedBox(width: 8),
              _chip('Out of Stock', outCount, AppColors.errorBg, AppColors.error),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search products…',
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textMuted, size: 18),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Table
        Expanded(
          child: prov.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : filtered.isEmpty
                  ? Center(
                      child: Text('No products match your filter',
                          style: TextStyle(color: AppColors.textMuted)))
                  : Scrollbar(
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
                                0: FlexColumnWidth(2.5),
                                1: FlexColumnWidth(1.5),
                                2: FlexColumnWidth(1.5),
                                3: FixedColumnWidth(110),
                                4: FixedColumnWidth(110),
                                5: FixedColumnWidth(140),
                                6: FixedColumnWidth(110),
                              },
                              children: [
                                _header(),
                                ...filtered.asMap().entries.map(
                                    (e) => _row(e.value, e.key)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _chip(String label, int count, Color bg, Color color) =>
      GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _filter == label ? bg : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _filter == label ? color : AppColors.border),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: _filter == label ? color : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  TableRow _header() => TableRow(
        decoration: BoxDecoration(color: AppColors.surface),
        children: [
          'Product / Brand',
          'Category',
          'Supplier',
          'Stock (Packs)',
          'Stock (Pieces)',
          'Inventory Value',
          'Status',
        ]
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

  TableRow _row(ProductModel p, int index) {
    final bg = index.isEven ? AppColors.card : AppColors.cardHover;
    Color statusColor;
    String statusLabel;
    Color statusBg;

    if (p.isOutOfStock) {
      statusColor = AppColors.error;
      statusBg = AppColors.errorBg;
      statusLabel = 'Out of Stock';
    } else if (p.isLowStock) {
      statusColor = AppColors.warning;
      statusBg = AppColors.warningBg;
      statusLabel = 'Low Stock';
    } else {
      statusColor = AppColors.success;
      statusBg = AppColors.successBg;
      statusLabel = 'In Stock';
    }

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        // Product / Brand
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(p.brand,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        _cell(p.category),
        _cell(p.supplierName ?? '—'),
        _cell(formatNumber(p.stockPacks),
            bold: true,
            color: p.isOutOfStock
                ? AppColors.error
                : p.isLowStock
                    ? AppColors.warning
                    : null),
        _cell(formatNumber(p.stockPieces)),
        _cell(formatNaira(p.inventoryValue)),
        // Status badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, Color? color}) =>
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(text,
            style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.w600 : FontWeight.normal)),
      );
}
