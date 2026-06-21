import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/purchase_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/purchase_provider.dart';
import '../../core/providers/supplier_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_text_field.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.dark(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (dt != null) {
      setState(() {
        if (isFrom) _from = dt;
        else _to = dt;
      });
      _reload();
    }
  }

  void _reload() {
    context.read<PurchaseProvider>().loadPurchases(
          dateFrom: _from != null ? toDbDate(_from!) : null,
          dateTo: _to != null ? toDbDate(_to!) : null,
        );
  }

  void _clearFilters() {
    setState(() { _from = null; _to = null; });
    context.read<PurchaseProvider>().loadPurchases();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PurchaseProvider>();

    return Column(
      children: [
        PageHeader(
          title: 'Purchases',
          subtitle: 'Record stock received from suppliers',
          actions: [
            HeaderButton(
              label: 'Record Purchase',
              icon: Icons.add,
              isPrimary: true,
              onPressed: () => _showForm(context),
            ),
          ],
        ),

        // Date filters
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
          child: Row(
            children: [
              _dateChip('From', _from, () => _pickDate(true)),
              const SizedBox(width: 10),
              _dateChip('To', _to, () => _pickDate(false)),
              const SizedBox(width: 10),
              if (_from != null || _to != null)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: prov.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : prov.purchases.isEmpty
                  ? const Center(
                      child: Text('No purchases recorded',
                          style: TextStyle(color: AppColors.textMuted)))
                  : Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(110),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(2.5),
                                3: FixedColumnWidth(90),
                                4: FixedColumnWidth(120),
                                5: FixedColumnWidth(130),
                                6: FixedColumnWidth(130),
                              },
                              children: [
                                _header(),
                                ...prov.purchases.asMap().entries.map(
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

  TableRow _header() => TableRow(
        decoration: const BoxDecoration(color: AppColors.surface),
        children: ['Date', 'Supplier', 'Product', 'Packs', 'Cost/Pack',
                   'Total Cost', 'Invoice']
            .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Text(c,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ))
            .toList(),
      );

  TableRow _row(PurchaseModel p, int index) {
    final bg = index.isEven ? AppColors.card : AppColors.cardHover;
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _cell(formatDate(p.purchaseDate)),
        _cell(p.supplierName ?? '—'),
        _cell(p.productName ?? '—'),
        _cell(formatNumber(p.qtyPacks)),
        _cell(formatNaira(p.costPricePerPack)),
        _cell(formatNaira(p.totalCost), bold: true),
        _cell(p.invoiceNumber ?? '—', muted: p.invoiceNumber == null),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, bool muted = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(text,
            style: TextStyle(
                color: muted ? AppColors.textMuted : AppColors.textPrimary,
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.w600 : FontWeight.normal)),
      );

  Widget _dateChip(String label, DateTime? dt, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: dt != null ? AppColors.accent : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14,
                  color: dt != null
                      ? AppColors.accent
                      : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                dt != null ? '$label: ${formatDate(dt)}' : label,
                style: TextStyle(
                    color: dt != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      );

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PurchaseFormDialog(onSaved: _reload),
    );
  }
}

// ─────────────────── Purchase Form Dialog ───────────────────

class _PurchaseFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _PurchaseFormDialog({required this.onSaved});

  @override
  State<_PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends State<_PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  int? _supplierId;
  int? _productId;
  final _qty = TextEditingController();
  final _cost = TextEditingController();
  final _invoice = TextEditingController();
  bool _saving = false;

  double get _total {
    final q = double.tryParse(_qty.text) ?? 0;
    final c = double.tryParse(_cost.text) ?? 0;
    return q * c;
  }

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    _invoice.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (dt != null) setState(() => _date = dt);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null || _productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a supplier and product')));
      return;
    }

    setState(() => _saving = true);
    final qty = double.parse(_qty.text);
    final cost = double.parse(_cost.text);

    final purchase = PurchaseModel(
      purchaseDate: _date,
      supplierId: _supplierId!,
      productId: _productId!,
      qtyPacks: qty,
      costPricePerPack: cost,
      totalCost: qty * cost,
      invoiceNumber:
          _invoice.text.trim().isEmpty ? null : _invoice.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await context.read<PurchaseProvider>().addPurchase(purchase);
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
        context.read<DashboardProvider>().loadStats();
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase recorded — stock updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.read<SupplierProvider>().suppliers;
    final products = context.read<ProductProvider>().products;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _dialogHeader(context, 'Record Purchase'),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Date
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Purchase Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined)),
                        child: Text(formatDate(_date)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppDropdown<int>(
                      value: _supplierId,
                      label: 'Supplier *',
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _supplierId = v),
                      validator: (v) =>
                          v == null ? 'Select a supplier' : null,
                    ),
                    const SizedBox(height: 16),

                    AppDropdown<int>(
                      value: _productId,
                      label: 'Product *',
                      items: products
                          .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.code} — ${p.name}')))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _productId = v);
                        if (v != null) {
                          final prod =
                              products.firstWhere((p) => p.id == v);
                          _cost.text =
                              prod.costPricePerPack.toString();
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Select a product' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _qty,
                            label: 'Quantity (Packs) *',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if ((double.tryParse(v) ?? 0) <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _cost,
                            label: 'Cost / Pack (₦) *',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if ((double.tryParse(v) ?? 0) <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total cost preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentGlow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Cost',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          Text(formatNaira(_total),
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _invoice,
                      label: 'Invoice Number (optional)',
                    ),
                  ],
                ),
              ),
            ),

            _dialogFooter(context, _saving, _save, 'Record Purchase'),
          ],
        ),
      ),
    );
  }
}

Widget _dialogHeader(BuildContext context, String title) => Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close)),
        ],
      ),
    );

Widget _dialogFooter(BuildContext context, bool saving, VoidCallback onSave,
    String label) =>
    Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text(label),
          ),
        ],
      ),
    );
