import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/supplier_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/app_text_field.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;

  const ProductFormDialog({super.key, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _category;
  late final TextEditingController _barcode;
  late final TextEditingController _upp;
  late final TextEditingController _costPack;
  late final TextEditingController _wholePack;
  late final TextEditingController _retailPiece;
  late final TextEditingController _reorder;
  late final TextEditingController _stockPacks;

  int? _supplierId;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _code = TextEditingController(text: p?.code ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _upp = TextEditingController(
        text: p != null ? '${p.unitsPerPack}' : '');
    _costPack = TextEditingController(
        text: p != null ? p.costPricePerPack.toString() : '');
    _wholePack = TextEditingController(
        text: p != null ? p.wholesalePricePerPack.toString() : '');
    _retailPiece = TextEditingController(
        text: p != null ? p.retailPricePerPiece.toString() : '');
    _reorder = TextEditingController(
        text: p != null ? '${p.reorderLevel}' : '');
    _stockPacks = TextEditingController(
        text: p != null ? '${p.stockPacks}' : '0');
    _supplierId = p?.supplierId;
  }

  @override
  void dispose() {
    for (final c in [
      _code, _name, _brand, _category, _barcode,
      _upp, _costPack, _wholePack, _retailPiece, _reorder, _stockPacks
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _costPerPiece {
    final upp = int.tryParse(_upp.text) ?? 0;
    final cost = double.tryParse(_costPack.text) ?? 0;
    return upp > 0 ? cost / upp : 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    setState(() => _saving = true);

    final product = ProductModel(
      id: widget.product?.id,
      code: _code.text.trim().toUpperCase(),
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      category: _category.text.trim(),
      supplierId: _supplierId!,
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      unitsPerPack: int.parse(_upp.text),
      costPricePerPack: double.parse(_costPack.text),
      wholesalePricePerPack: double.parse(_wholePack.text),
      retailPricePerPiece: double.parse(_retailPiece.text),
      reorderLevel: int.parse(_reorder.text),
      stockPacks: double.tryParse(_stockPacks.text) ?? widget.product?.stockPacks ?? 0.0,
      avgCostPerPack: widget.product?.avgCostPerPack ?? double.parse(_costPack.text),
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    try {
      final prov = context.read<ProductProvider>();
      if (_isEdit) {
        await prov.updateProduct(product);
      } else {
        await prov.addProduct(product);
      }
      if (mounted) {
        context.read<DashboardProvider>().loadStats();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.read<SupplierProvider>().suppliers;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Icon(_isEdit ? Icons.edit : Icons.add_circle_outline,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Text(_isEdit ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Basic Info'),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _code,
                              label: 'Product Code *',
                              hint: 'e.g. PRD001',
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              controller: _name,
                              label: 'Product Name *',
                              validator: _required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                                controller: _brand,
                                label: 'Brand *',
                                hint: 'e.g. Indomie',
                                validator: _required),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                                controller: _category,
                                label: 'Category *',
                                hint: 'e.g. Noodles',
                                validator: _required),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppDropdown<int>(
                              value: _supplierId,
                              label: 'Supplier *',
                              items: suppliers
                                  .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.name)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _supplierId = v),
                              validator: (v) =>
                                  v == null ? 'Select supplier' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                          controller: _barcode,
                          label: 'Barcode (optional)',
                          hint: 'Scan or type barcode'),

                      const SizedBox(height: 24),
                      _section('Units & Pricing'),

                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _upp,
                              label: 'Units per Pack *',
                              hint: 'e.g. 12',
                              keyboardType: TextInputType.number,
                              validator: _positiveInt,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _costPack,
                              label: 'Cost Price / Pack (₦) *',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _positiveNum,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _readonlyField(
                              'Cost Price / Piece (₦)',
                              formatNaira(_costPerPiece),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _wholePack,
                              label: 'Wholesale Price / Pack (₦) *',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _positiveNum,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _retailPiece,
                              label: 'Retail Price / Piece (₦) *',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _positiveNum,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _reorder,
                              label: 'Reorder Level (Packs) *',
                              keyboardType: TextInputType.number,
                              validator: _nonNegInt,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _stockPacks,
                              label: 'Stock (Packs)',
                              hint: 'e.g. 10',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _nonNegNum,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : Text(_isEdit ? 'Save Changes' : 'Add Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(title,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      );

  Widget _readonlyField(String label, String value) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Text(value,
            style: const TextStyle(
                color: AppColors.accentLight,
                fontWeight: FontWeight.w600)),
      );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _positiveNum(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Enter a valid number > 0';
    return null;
  }

  String? _positiveInt(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n <= 0) return 'Enter a valid integer > 0';
    return null;
  }

  String? _nonNegInt(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n < 0) return 'Enter 0 or greater';
    return null;
  }

  String? _nonNegNum(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n < 0) return 'Enter 0 or greater';
    return null;
  }
}
