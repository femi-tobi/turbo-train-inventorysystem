import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/supplier_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/page_header.dart';
import 'report_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _svc = ReportExportService();
  final _db = DatabaseHelper();

  // Filters for Sales & Purchase reports
  DateTime? _from;
  DateTime? _to;
  int? _filterProductId;
  String _filterSaleType = 'all';

  List<Map<String, dynamic>> _reportData = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _loadReport();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      List<Map<String, dynamic>> data;
      switch (_tab.index) {
        case 0:
          data = await _db.reportInventoryByBrand();
          break;
        case 1:
          data = (await _db.getSales(
            dateFrom: _from != null ? toDbDate(_from!) : null,
            dateTo: _to != null ? toDbDate(_to!) : null,
            productId: _filterProductId,
            saleType: _filterSaleType == 'all' ? null : _filterSaleType,
          )).map((s) => {
            'date': formatDate(s.saleDate),
            'product': s.productName ?? '—',
            'type': s.saleTypeLabel,
            'qty': s.saleType == 'wholesale'
                ? '${formatNumber(s.qtyPacks)} packs'
                : '${formatNumber(s.qtyPieces)} pcs',
            'amount': s.totalAmount,
            'cogs': s.cogs,
            'profit': s.grossProfit,
          }).toList();
          break;
        case 2:
          data = await _db.reportDailySales();
          break;
        case 3:
          data = await _db.reportMonthlySales();
          break;
        case 4:
          data = (await _db.getPurchases(
            dateFrom: _from != null ? toDbDate(_from!) : null,
            dateTo: _to != null ? toDbDate(_to!) : null,
          )).map((p) => {
            'date': formatDate(p.purchaseDate),
            'supplier': p.supplierName ?? '—',
            'product': p.productName ?? '—',
            'qty_packs': p.qtyPacks,
            'total_cost': p.totalCost,
          }).toList();
          break;
        case 5:
          data = await _db.reportProfit();
          break;
        case 6:
          data = await _db.reportBrandPerformance();
          break;
        default:
          data = [];
      }
      setState(() => _reportData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _export() async {
    switch (_tab.index) {
      case 0: await _svc.exportInventoryByBrand(context); break;
      case 1: await _svc.exportSalesReport(context,
          dateFrom: _from != null ? toDbDate(_from!) : null,
          dateTo: _to != null ? toDbDate(_to!) : null,
          saleType: _filterSaleType == 'all' ? null : _filterSaleType); break;
      case 2: await _svc.exportDailySales(context); break;
      case 3: await _svc.exportMonthlySales(context); break;
      case 4: await _svc.exportPurchaseReport(context,
          dateFrom: _from != null ? toDbDate(_from!) : null,
          dateTo: _to != null ? toDbDate(_to!) : null); break;
      case 5: await _svc.exportProfitReport(context); break;
      case 6: await _svc.exportBrandPerformance(context); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Inventory by Brand',
      'Sales',
      'Daily Sales',
      'Monthly Sales',
      'Purchases',
      'Profit',
      'Brand Performance',
    ];

    return Column(
      children: [
        PageHeader(
          title: 'Reports',
          subtitle: 'View and export business reports to Excel',
          actions: [
            ElevatedButton.icon(
              onPressed: _export,
              icon: Icon(Icons.download_rounded, size: 16),
              label: Text('Export Excel'),
            ),
          ],
        ),

        // Tabs
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Inter'),
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),

        // Filters row (shown for Sales/Purchase tabs)
        if (_tab.index == 1 || _tab.index == 4)
          _filtersBar(context),

        const SizedBox(height: 4),

        // Table
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _reportData.isEmpty
                  ? Center(
                      child: Text('No data for this report',
                          style: TextStyle(color: AppColors.textMuted)))
                  : Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                        child: _buildTable(),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filtersBar(BuildContext context) {
    final products = context.read<ProductProvider>().products;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      color: AppColors.background,
      child: Row(
        children: [
          _dateBtn('From', _from, () => _pickDate(true)),
          const SizedBox(width: 8),
          _dateBtn('To', _to, () => _pickDate(false)),
          if (_tab.index == 1) ...[
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<String>(
                  value: _filterSaleType,
                  dropdownColor: AppColors.card,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontFamily: 'Inter'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Types')),
                    DropdownMenuItem(
                        value: 'wholesale', child: Text('Wholesale')),
                    DropdownMenuItem(value: 'retail', child: Text('Retail')),
                  ],
                  onChanged: (v) {
                    setState(() => _filterSaleType = v!);
                    _loadReport();
                  },
                ),
              ),
            ),
          ],
          if (_from != null || _to != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _from = null;
                  _to = null;
                });
                _loadReport();
              },
              icon: Icon(Icons.clear, size: 14),
              label: Text('Clear'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
            ),
          ],
          const Spacer(),
          Text('${_reportData.length} rows',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _dateBtn(String label, DateTime? dt, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: dt != null ? AppColors.accent : AppColors.border),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 13,
                color: dt != null
                    ? AppColors.accent
                    : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
                dt != null ? '$label: ${formatDate(dt)}' : label,
                style: TextStyle(
                    color: dt != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12)),
          ]),
        ),
      );

  Future<void> _pickDate(bool isFrom) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      builder: (ctx, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.accent)
                : const ColorScheme.light(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (dt != null) {
      setState(() => isFrom ? _from = dt : _to = dt);
      _loadReport();
    }
  }

  Widget _buildTable() {
    if (_reportData.isEmpty) return const SizedBox();
    final keys = _reportData.first.keys.toList();

    return Container(
      decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: AppColors.isDark ? Border.all(color: AppColors.border) : null,
                            boxShadow: AppColors.cardShadow,
                          ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surface),
            dataRowColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.hovered)
                    ? AppColors.cardHover
                    : AppColors.card),
            columns: keys.map((k) => DataColumn(
              label: Text(
                _formatKey(k),
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            )).toList(),
            rows: _reportData.asMap().entries.map((entry) {
              final row = entry.value;
              return DataRow(
                cells: keys.map((k) {
                  final v = row[k];
                  String display;
                  if (v is double) {
                    // Heuristic: if key contains 'amount', 'value', 'cost', 'profit', 'revenue'
                    final isNaira = RegExp(
                            r'amount|value|cost|profit|revenue|sales')
                        .hasMatch(k.toLowerCase());
                    display = isNaira ? formatNaira(v) : formatNumber(v);
                  } else {
                    display = v?.toString() ?? '—';
                  }
                  return DataCell(Text(display,
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 12)));
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatKey(String k) => k
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty
          ? '${w[0].toUpperCase()}${w.substring(1)}'
          : '')
      .join(' ');
}
