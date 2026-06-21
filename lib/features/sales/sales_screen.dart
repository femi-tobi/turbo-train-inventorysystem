import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/product_model.dart';
import '../../core/models/sale_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/sale_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_text_field.dart';
import 'receipt_dialog.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'Sales',
          subtitle: 'Process wholesale (Pack) and retail (Piece) sales',
        ),
        // Tab bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Inter'),
            tabs: const [
              Tab(icon: Icon(Icons.business_center_outlined, size: 18),
                  text: 'Wholesale (Pack)'),
              Tab(icon: Icon(Icons.shopping_bag_outlined, size: 18),
                  text: 'Retail (Piece)'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _SaleForm(type: 'wholesale'),
              _SaleForm(type: 'retail'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaleForm extends StatefulWidget {
  final String type;
  const _SaleForm({required this.type});

  @override
  State<_SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<_SaleForm>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  ProductModel? _product;
  final _qty = TextEditingController();
  bool _saving = false;
  String? _stockError;

  bool get _isWholesale => widget.type == 'wholesale';

  double get _unitPrice {
    if (_product == null) return 0;
    return _isWholesale
        ? _product!.wholesalePricePerPack
        : _product!.retailPricePerPiece;
  }

  double get _qty2 => double.tryParse(_qty.text) ?? 0;

  double get _total => _qty2 * _unitPrice;

  double get _qtyPacks =>
      _isWholesale ? _qty2 : (_qty2 / (_product?.unitsPerPack ?? 1));

  double get _cogs {
    if (_product == null) return 0;
    if (_isWholesale) {
      return _qtyPacks * _product!.avgCostPerPack;
    } else {
      final costPerPiece = _product!.avgCostPerPack /
          (_product!.unitsPerPack > 0 ? _product!.unitsPerPack : 1);
      return _qty2 * costPerPiece;
    }
  }

  double get _profit => _total - _cogs;

  void _validateStock() {
    if (_product == null || _qty2 <= 0) {
      setState(() => _stockError = null);
      return;
    }
    if (_product!.stockPacks < _qtyPacks) {
      final avail = _isWholesale
          ? '${formatNumber(_product!.stockPacks)} packs'
          : '${formatNumber(_product!.stockPieces)} pieces';
      setState(() => _stockError = 'Insufficient stock. Available: $avail');
    } else {
      setState(() => _stockError = null);
    }
  }

  Future<void> _processSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stockError != null) return;
    if (_product == null) return;

    setState(() => _saving = true);

    final sale = SaleModel(
      saleDate: DateTime.now(),
      productId: _product!.id!,
      saleType: widget.type,
      qtyPacks: _qtyPacks,
      qtyPieces: _isWholesale ? _qty2 * _product!.unitsPerPack : _qty2,
      unitPrice: _unitPrice,
      totalAmount: _total,
      cogs: _cogs,
      grossProfit: _profit,
      receiptId: const Uuid().v4().substring(0, 8).toUpperCase(),
      createdAt: DateTime.now(),
      productName: _product!.name,
      productCode: _product!.code,
      brand: _product!.brand,
    );

    try {
      final created = await context.read<SaleProvider>().addSale(sale);
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
        context.read<DashboardProvider>().loadStats();

        // Show receipt
        showDialog(
          context: context,
          builder: (_) => ReceiptDialog(sale: created, product: _product!),
        );

        // Reset form
        setState(() {
          _product = null;
          _qty.clear();
          _stockError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final products = context.watch<ProductProvider>().products;
    final recentSales = context.watch<SaleProvider>().sales
        .where((s) => s.saleType == widget.type)
        .take(10)
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Sale Form ──
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isWholesale
                                  ? AppColors.infoBg
                                  : AppColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _isWholesale
                                  ? Icons.business_center_outlined
                                  : Icons.shopping_bag_outlined,
                              color: _isWholesale
                                  ? AppColors.info
                                  : AppColors.success,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isWholesale
                                    ? 'Wholesale Sale'
                                    : 'Retail Sale',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _isWholesale
                                    ? 'Customer: Wholesale Customer'
                                    : 'Customer: Retail Customer',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      // Product dropdown
                      AppDropdown<int>(
                        value: _product?.id,
                        label:
                            'Select Product *',
                        items: products
                            .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                    '${p.code} — ${p.name} (${formatNumber(p.stockPacks)} pk left)',
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _product = products.firstWhere((p) => p.id == v);
                            _qty.clear();
                            _stockError = null;
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Please select a product' : null,
                      ),

                      if (_product != null) ...[
                        const SizedBox(height: 12),
                        _productInfo(),
                      ],

                      const SizedBox(height: 16),

                      // Quantity field
                      AppTextField(
                        controller: _qty,
                        label: _isWholesale
                            ? 'Quantity (Packs) *'
                            : 'Quantity (Pieces) *',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) {
                          setState(() {});
                          _validateStock();
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if ((double.tryParse(v) ?? 0) <= 0) {
                            return 'Quantity must be > 0';
                          }
                          return null;
                        },
                      ),

                      if (_stockError != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_stockError!,
                                    style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Sale summary
                      if (_product != null && _qty2 > 0) ...[
                        _summaryCard(),
                        const SizedBox(height: 24),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_saving || _stockError != null)
                              ? null
                              : _processSale,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_saving
                              ? 'Processing…'
                              : 'Confirm Sale & Print Receipt'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 24),

            // ── Right: Recent sales ──
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Transactions',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: recentSales.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('No transactions yet',
                                  style: TextStyle(
                                      color: AppColors.textMuted)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentSales.length,
                            separatorBuilder: (_, __) => const Divider(
                                color: AppColors.border, height: 1),
                            itemBuilder: (_, i) {
                              final s = recentSales[i];
                              return Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s.productName ?? '—',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          Text(
                                              '${formatDate(s.saleDate)}  •  '
                                              '${_isWholesale ? '${formatNumber(s.qtyPacks)} packs' : '${formatNumber(s.qtyPieces)} pcs'}',
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(formatNaira(s.totalAmount),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                        Text(
                                            'Profit: ${formatNaira(s.grossProfit)}',
                                            style: TextStyle(
                                                color: s.grossProfit >= 0
                                                    ? AppColors.success
                                                    : AppColors.error,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productInfo() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _infoChip('Brand', _product!.brand),
            const SizedBox(width: 16),
            _infoChip(
                _isWholesale ? 'Price/Pack' : 'Price/Piece',
                formatNaira(_unitPrice)),
            const SizedBox(width: 16),
            _infoChip(
                'Stock',
                _isWholesale
                    ? '${formatNumber(_product!.stockPacks)} packs'
                    : '${formatNumber(_product!.stockPieces)} pcs',
                color: _product!.isOutOfStock
                    ? AppColors.error
                    : _product!.isLowStock
                        ? AppColors.warning
                        : AppColors.success),
          ],
        ),
      );

  Widget _infoChip(String label, String value, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _summaryCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentGlow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            _sumRow('Quantity',
                _isWholesale
                    ? '${formatNumber(_qty2)} Packs'
                    : '${formatNumber(_qty2)} Pieces'),
            const SizedBox(height: 8),
            _sumRow('Unit Price',
                formatNaira(_unitPrice) +
                    (_isWholesale ? '/pack' : '/piece')),
            const SizedBox(height: 8),
            _sumRow('COGS', formatNaira(_cogs),
                color: AppColors.textSecondary),
            const Divider(color: AppColors.border, height: 20),
            _sumRow('Total Amount', formatNaira(_total),
                large: true),
            const SizedBox(height: 4),
            _sumRow('Gross Profit', formatNaira(_profit),
                color: _profit >= 0
                    ? AppColors.accentLight
                    : AppColors.error),
          ],
        ),
      );

  Widget _sumRow(String label, String value,
          {Color? color, bool large = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: large ? 14 : 13)),
          Text(value,
              style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontSize: large ? 20 : 13,
                fontWeight:
                    large ? FontWeight.bold : FontWeight.w500,
              )),
        ],
      );
}
