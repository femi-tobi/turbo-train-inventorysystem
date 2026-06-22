import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as xl;
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/supplier_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_text_field.dart';

// ─── Row data model for the import table ────────────────────────────────────

class _ImportRow {
  final String code;
  final String name;
  final String unitOfMeasure; // pcs / packs from xlsx

  final TextEditingController brand;
  final TextEditingController category;
  final TextEditingController upp; // units per pack
  final TextEditingController costPack;
  final TextEditingController wholePack;
  final TextEditingController retailPiece;
  final TextEditingController reorderLevel;
  final TextEditingController stockPacks;

  int? supplierId;
  bool selected;

  _ImportRow({
    required this.code,
    required this.name,
    required this.unitOfMeasure,
    required this.brand,
    required this.category,
    required this.upp,
    required this.costPack,
    required this.wholePack,
    required this.retailPiece,
    required this.reorderLevel,
    required this.stockPacks,
    this.supplierId,
    this.selected = true,
  });

  factory _ImportRow.fromExcel(String code, String name, String uom) {
    return _ImportRow(
      code: code,
      name: name,
      unitOfMeasure: uom,
      brand: TextEditingController(),
      category: TextEditingController(),
      upp: TextEditingController(text: uom.toLowerCase().contains('pcs') ? '1' : ''),
      costPack: TextEditingController(),
      wholePack: TextEditingController(),
      retailPiece: TextEditingController(),
      reorderLevel: TextEditingController(text: '5'),
      stockPacks: TextEditingController(text: '0'),
    );
  }

  void dispose() {
    for (final c in [
      brand, category, upp, costPack, wholePack, retailPiece, reorderLevel, stockPacks,
    ]) {
      c.dispose();
    }
  }

  bool get isValid {
    return brand.text.trim().isNotEmpty &&
        category.text.trim().isNotEmpty &&
        (int.tryParse(upp.text) ?? 0) > 0 &&
        (double.tryParse(costPack.text) ?? 0) > 0 &&
        (double.tryParse(wholePack.text) ?? 0) > 0 &&
        (double.tryParse(retailPiece.text) ?? 0) > 0 &&
        supplierId != null;
  }
}

// ─── Dialog ─────────────────────────────────────────────────────────────────

class ImportProductsDialog extends StatefulWidget {
  const ImportProductsDialog({super.key});

  @override
  State<ImportProductsDialog> createState() => _ImportProductsDialogState();
}

class _ImportProductsDialogState extends State<ImportProductsDialog> {
  bool _loading = true;
  String? _error;
  List<_ImportRow> _rows = [];
  bool _importing = false;
  int _importedCount = 0;

  // Global defaults applied to all rows at once
  final _globalBrand = TextEditingController();
  final _globalCategory = TextEditingController();
  final _globalUpp = TextEditingController();
  int? _globalSupplierId;

  @override
  void initState() {
    super.initState();
    _loadExcel();
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    _globalBrand.dispose();
    _globalCategory.dispose();
    _globalUpp.dispose();
    super.dispose();
  }

  Future<void> _loadExcel() async {
    try {
      final bytes = await rootBundle.load('assets/Product Master Data.xlsx');
      final excel = xl.Excel.decodeBytes(bytes.buffer.asUint8List());
      final sheet = excel.sheets.values.first;

      final rows = <_ImportRow>[];
      bool firstRow = true;
      for (final row in sheet.rows) {
        if (firstRow) { firstRow = false; continue; } // skip header
        if (row.isEmpty) continue;

        String cellVal(int i) {
          if (i >= row.length) return '';
          final c = row[i];
          return c?.value?.toString().trim() ?? '';
        }

        final code = cellVal(0);
        final name = cellVal(1);
        final uom = cellVal(4); // Unit of Measure column (index 4)
        if (code.isEmpty && name.isEmpty) continue;

        rows.add(_ImportRow.fromExcel(code, name, uom));
      }

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to read Excel file: $e';
        _loading = false;
      });
    }
  }

  void _applyGlobalDefaults() {
    setState(() {
      for (final r in _rows) {
        if (_globalBrand.text.trim().isNotEmpty) r.brand.text = _globalBrand.text.trim();
        if (_globalCategory.text.trim().isNotEmpty) r.category.text = _globalCategory.text.trim();
        if (_globalUpp.text.trim().isNotEmpty) r.upp.text = _globalUpp.text.trim();
        if (_globalSupplierId != null) r.supplierId = _globalSupplierId;
      }
    });
  }

  Future<void> _import() async {
    final selected = _rows.where((r) => r.selected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rows selected')));
      return;
    }

    final invalid = selected.where((r) => !r.isValid).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${invalid.length} row(s) are incomplete. Please fill in all required fields.')));
      return;
    }

    setState(() => _importing = true);
    final prov = context.read<ProductProvider>();
    int count = 0;
    for (final r in selected) {
      try {
        final cost = double.parse(r.costPack.text);
        await prov.addProduct(ProductModel(
          code: r.code.toUpperCase(),
          name: r.name,
          brand: r.brand.text.trim(),
          category: r.category.text.trim(),
          supplierId: r.supplierId!,
          unitsPerPack: int.parse(r.upp.text),
          costPricePerPack: cost,
          wholesalePricePerPack: double.parse(r.wholePack.text),
          retailPricePerPiece: double.parse(r.retailPiece.text),
          reorderLevel: int.tryParse(r.reorderLevel.text) ?? 5,
          stockPacks: double.tryParse(r.stockPacks.text) ?? 0.0,
          avgCostPerPack: cost,
          createdAt: DateTime.now(),
        ));
        count++;
      } catch (_) {}
    }
    if (mounted) {
      context.read<DashboardProvider>().loadStats();
      setState(() {
        _importing = false;
        _importedCount = count;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count products imported successfully!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.read<SupplierProvider>().suppliers;
    final selectedCount = _rows.where((r) => r.selected).length;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 800),
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Import from Excel',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Product Master Data.xlsx  •  Fill in pricing & details, then import',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error)),
                ),
              )
            else ...[
              // ── Global defaults bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Apply to all rows:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _miniField(_globalBrand, 'Brand (all)'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniField(_globalCategory, 'Category (all)'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniField(_globalUpp, 'Units/Pack (all)',
                              numeric: true),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _miniDropdown(
                            value: _globalSupplierId,
                            hint: 'Supplier (all)',
                            suppliers: suppliers,
                            onChanged: (v) =>
                                setState(() => _globalSupplierId = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _applyGlobalDefaults,
                          icon: const Icon(Icons.auto_fix_high, size: 15),
                          label: const Text('Apply'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Table header ──
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Checkbox(
                        value: _rows.every((r) => r.selected),
                        tristate: true,
                        onChanged: (v) => setState(() {
                          final sel = v ?? false;
                          for (final r in _rows) r.selected = sel;
                        }),
                        activeColor: AppColors.accent,
                      ),
                    ),
                    _th('Code', 90),
                    _th('Name', 160),
                    _th('UOM', 50),
                    _th('Brand *', 90),
                    _th('Category *', 90),
                    _th('Supplier *', 110),
                    _th('UPP *', 55),
                    _th('Cost/Pk ₦ *', 85),
                    _th('Whole/Pk ₦ *', 95),
                    _th('Retail/Pc ₦ *', 95),
                    _th('Reorder', 65),
                    _th('Stock', 55),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // ── Rows ──
              Expanded(
                child: Scrollbar(
                  child: ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (ctx, i) =>
                        _buildRow(_rows[i], suppliers, i),
                  ),
                ),
              ),
            ],

            // ── Footer ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Text('${_rows.length} rows  •  $selectedCount selected',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (_loading || _importing) ? null : _import,
                    icon: _importing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.file_download_done, size: 16),
                    label: Text(_importing
                        ? 'Importing…'
                        : 'Import $selectedCount Products'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_ImportRow r, suppliers, int index) {
    final bg = index.isEven ? AppColors.card : AppColors.cardHover;
    return Container(
      color: r.selected ? bg : AppColors.surface.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: r.selected,
              onChanged: (v) => setState(() => r.selected = v ?? false),
              activeColor: AppColors.accent,
            ),
          ),
          _staticCell(r.code, 90, mono: true),
          _staticCell(r.name, 160),
          _staticCell(r.unitOfMeasure, 50),
          _editCell(r.brand, 90),
          _editCell(r.category, 90),
          // Supplier dropdown
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DropdownButtonHideUnderline(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(
                        color: r.supplierId == null
                            ? AppColors.error.withOpacity(0.5)
                            : AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<int>(
                    value: r.supplierId,
                    hint: const Text('Select',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    dropdownColor: AppColors.card,
                    isExpanded: true,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 12),
                    items: suppliers
                        .map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
                            value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setState(() => r.supplierId = v),
                  ),
                ),
              ),
            ),
          ),
          _editCell(r.upp, 55, numeric: true),
          _editCell(r.costPack, 85, decimal: true),
          _editCell(r.wholePack, 95, decimal: true),
          _editCell(r.retailPiece, 95, decimal: true),
          _editCell(r.reorderLevel, 65, numeric: true),
          _editCell(r.stockPacks, 55, decimal: true),
        ],
      ),
    );
  }

  Widget _th(String label, double width) => SizedBox(
        width: width,
        child: Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _staticCell(String text, double width, {bool mono = false}) => SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontFamily: mono ? 'monospace' : null)),
        ),
      );

  Widget _editCell(TextEditingController ctrl, double width,
      {bool numeric = false, bool decimal = false}) =>
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            height: 34,
            child: TextField(
              controller: ctrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12),
              keyboardType: decimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : numeric
                      ? TextInputType.number
                      : TextInputType.text,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _miniField(TextEditingController ctrl, String hint,
          {bool numeric = false}) =>
      SizedBox(
        height: 36,
        child: TextField(
          controller: ctrl,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style:
              const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 12),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      );

  Widget _miniDropdown(
          {required int? value,
          required String hint,
          required List suppliers,
          required ValueChanged<int?> onChanged}) =>
      DropdownButtonHideUnderline(
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: value,
            hint: Text(hint,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            dropdownColor: AppColors.card,
            isExpanded: true,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            items: suppliers
                .map<DropdownMenuItem<int>>(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}
