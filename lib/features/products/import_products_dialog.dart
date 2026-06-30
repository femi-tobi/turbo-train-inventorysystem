import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as xl;
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/supplier_provider.dart';
import '../../core/models/supplier_model.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../shared/theme/app_theme.dart';

// ─── Row data model ──────────────────────────────────────────────────────────

class _ImportRow {
  final String code;
  final String name;
  final String unitOfMeasure;

  final TextEditingController brand;
  final TextEditingController category;
  final TextEditingController upp;
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

  factory _ImportRow.fromExcel(String code, String name, String uom,
      {String categoryHint = ''}) {
    return _ImportRow(
      code: code,
      name: name,
      unitOfMeasure: uom,
      brand: TextEditingController(),
      category: TextEditingController(text: categoryHint),
      upp: TextEditingController(
          text: uom.toUpperCase().contains('PCS') ? '1' : ''),
      costPack: TextEditingController(),
      wholePack: TextEditingController(),
      retailPiece: TextEditingController(),
      reorderLevel: TextEditingController(text: '5'),
      stockPacks: TextEditingController(text: '0'),
    );
  }

  void dispose() {
    for (final c in [
      brand, category, upp, costPack, wholePack, retailPiece, reorderLevel, stockPacks
    ]) {
      c.dispose();
    }
  }

  bool get isValid => true; // Make everything optional as requested
}

// ─── Dialog ──────────────────────────────────────────────────────────────────

class ImportProductsDialog extends StatefulWidget {
  const ImportProductsDialog({super.key});

  @override
  State<ImportProductsDialog> createState() => _ImportProductsDialogState();
}

class _ImportProductsDialogState extends State<ImportProductsDialog> {
  /// null = waiting for user to browse; true = loading; false = done
  bool? _loading; // starts null
  String? _error;
  List<_ImportRow> _rows = [];
  bool _importing = false;
  String? _pickedFileName;
  final _scrollController = ScrollController();

  final _globalBrand    = TextEditingController();
  final _globalCategory = TextEditingController();
  final _globalUpp      = TextEditingController();
  int? _globalSupplierId;

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    _globalBrand.dispose();
    _globalCategory.dispose();
    _globalUpp.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── numFmt patch ─────────────────────────────────────────────────────────
  //
  // The `excel` package requires custom numFmtIds to start at 164.  Older
  // Excel files (and some generated ones) use lower IDs, which causes:
  //   "custom numFmtId start at 164 but found a value of X"
  // We fix this by opening the .xlsx ZIP, removing the offending <numFmt>
  // elements from xl/styles.xml, and re-encoding the archive.
List<int> _fixExcelBytes(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final newArchive = Archive();
      // Matches numFmtId= followed by an optional quote char then digits
      final idRe = RegExp(r'numFmtId=.?(\d+)');

      bool needsRemoval(String tag) {
        final m = idRe.firstMatch(tag);
        final id = int.tryParse(m?.group(1) ?? '999') ?? 999;
        return id < 164;
      }

      for (final file in archive) {
        if (file.name == 'xl/styles.xml' && file.isFile) {
          var xml = utf8.decode(file.content as List<int>, allowMalformed: true);
          // Self-closing: <numFmt ... />
          xml = xml.replaceAllMapped(
            RegExp(r'<numFmt [^/]*/>', dotAll: true),
            (m) => needsRemoval(m.group(0)!) ? '' : m.group(0)!,
          );
          // Paired: <numFmt ...>...</numFmt>
          xml = xml.replaceAllMapped(
            RegExp(r'<numFmt [^>]*>.*?</numFmt>', dotAll: true),
            (m) => needsRemoval(m.group(0)!) ? '' : m.group(0)!,
          );
          final encoded = utf8.encode(xml);
          newArchive.addFile(ArchiveFile(file.name, encoded.length, encoded));
        } else {
          newArchive.addFile(file);
        }
      }
      return ZipEncoder().encode(newArchive) ?? bytes;
    } catch (_) {
      return bytes;
    }
  }

  // ── File picker + parser ──────────────────────────────────────────────────

  Future<void> _pickAndLoadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    setState(() {
      _loading = true;
      _error = null;
      _pickedFileName = picked.name;
      _rows = [];
    });

    try {
      final List<int> bytes;
      if (picked.path != null) {
        bytes = await File(picked.path!).readAsBytes();
      } else if (picked.bytes != null) {
        bytes = picked.bytes!;
      } else {
        throw Exception('Could not read file bytes.');
      }

      // Fix: some Excel files have custom numFmtIds < 164 which crash the
      // dart `excel` package. Pre-process the ZIP to patch styles.xml first.
      final fixedBytes = _fixExcelBytes(bytes);
      final excel = xl.Excel.decodeBytes(fixedBytes);
      final sheet = excel.sheets.values.first;

      final rows = <_ImportRow>[];
      String currentCategory = '';

      for (final row in sheet.rows) {
        if (row.isEmpty) continue;

        String cellStr(int i) {
          if (i >= row.length) return '';
          return row[i]?.value?.toString().trim() ?? '';
        }

        final col0 = cellStr(0); // Product Code
        final col1 = cellStr(1); // Product Name
        final col2 = cellStr(2);
        final col3 = cellStr(3);
        final col4 = cellStr(4); // Unit of Measure
        final col5 = cellStr(5);

        // ── Detect section-header rows ────────────────────────────────────
        // A header row has one of the column-label strings in it,
        // e.g. "WHOLESALE PRICE", "UNIT OF MEASURE", etc.
        final allCells = [col0, col1, col2, col3, col4, col5].join(' ').toUpperCase();
        final isHeaderRow = allCells.contains('WHOLESALE PRICE') ||
            allCells.contains('UNIT OF MEASURE') ||
            (col0.isEmpty && col2.toUpperCase().contains('WHOLESALE'));

        if (isHeaderRow) {
          // The category name is the first non-empty cell that isn't a label
          for (final c in [col0, col1]) {
            final up = c.toUpperCase();
            if (c.isNotEmpty &&
                !up.contains('PRODUCT') &&
                !up.contains('CODE') &&
                !up.contains('NAME') &&
                !up.contains('WHOLESALE') &&
                !up.contains('RETAIL') &&
                !up.contains('UNIT')) {
              currentCategory = _prettifyCategory(c);
              break;
            }
          }
          continue; // skip header rows from product list
        }

        // ── Skip totally empty or label-only rows ─────────────────────────
        if (col0.isEmpty && col1.isEmpty) continue;
        if (col0.toUpperCase() == 'PRODUCT CODE') continue;

        final uom = col4.isNotEmpty ? col4 : 'PCS';
        rows.add(_ImportRow.fromExcel(col0, col1, uom,
            categoryHint: currentCategory));
      }

      if (rows.isEmpty) {
        throw Exception(
            'No product rows found.\n\nMake sure the file has columns:\n'
            'Product Code | Product Name | … | Unit of Measure\n'
            'with category header rows in between.');
      }

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Converts category codes like "DRYIN" or "S C H N A P P S" into
  /// a clean, readable name.
  String _prettifyCategory(String raw) {
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    const map = <String, String>{
      'DRYIN': 'Dry Gin',
      'DRY GIN': 'Dry Gin',
      'SCHNAPPS': 'Schnapps',
      'WHISKY': 'Whisky',
      'WHISKEY': 'Whiskey',
      'CREAM': 'Cream',
      'VODKA': 'Vodka',
      'LIQUORS': 'Liquors',
      'LIQUEUR': 'Liqueur',
      'BEER': 'Beer',
      'BITTERS': 'Bitters',
      'BITTER': 'Bitters',
      'WINE': 'Wine',
      'ENERGY': 'Energy Drinks',
      'SOFT': 'Soft Drinks',
      'WATER': 'Water',
      'JUICE': 'Juice',
      'SPIRIT': 'Spirits',
      'SPIRITS': 'Spirits',
      'STOUT': 'Stout',
      'LAGER': 'Lager',
      'CHAMPAGNE': 'Champagne',
      'COGNAC': 'Cognac',
      'BRANDY': 'Brandy',
      'TEQUILA': 'Tequila',
      'GIN': 'Gin',
      'RUM': 'Rum',
    };
    final upper = collapsed.toUpperCase();
    for (final entry in map.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    // Title-case fallback
    return collapsed
        .split(' ')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  // ── Apply global defaults ─────────────────────────────────────────────────

  void _applyGlobalDefaults() {
    setState(() {
      for (final r in _rows) {
        if (_globalBrand.text.trim().isNotEmpty)
          r.brand.text = _globalBrand.text.trim();
        if (_globalCategory.text.trim().isNotEmpty)
          r.category.text = _globalCategory.text.trim();
        if (_globalUpp.text.trim().isNotEmpty)
          r.upp.text = _globalUpp.text.trim();
        if (_globalSupplierId != null) r.supplierId = _globalSupplierId;
      }
    });
  }

  // ── Import ────────────────────────────────────────────────────────────────

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
              '${invalid.length} row(s) are incomplete. Fill in all required fields.')));
      return;
    }

    setState(() => _importing = true);
    final prov = context.read<ProductProvider>();
    final supplierProv = context.read<SupplierProvider>();

    // Prepare a fallback supplier if any are missing
    int? fallbackSupplierId;
    if (selected.any((r) => r.supplierId == null)) {
      if (supplierProv.suppliers.isNotEmpty) {
        fallbackSupplierId = supplierProv.suppliers.first.id;
      } else {
        try {
          await supplierProv.addSupplier(SupplierModel(
            name: 'General Supplier',
            phone: '',
            createdAt: DateTime.now(),
          ));
          await supplierProv.loadSuppliers();
          fallbackSupplierId = supplierProv.suppliers.first.id;
        } catch (_) {}
      }
    }

    int count = 0;
    List<String> errors = [];

    for (final r in selected) {
      try {
        final finalSupplierId = r.supplierId ?? fallbackSupplierId ?? 1;

        final finalBrand = r.brand.text.trim().isEmpty ? 'General' : r.brand.text.trim();
        final finalCategory = r.category.text.trim().isEmpty ? 'General' : r.category.text.trim();
        final finalUpp = int.tryParse(r.upp.text) ?? 1;
        final finalCost = double.tryParse(r.costPack.text) ?? 0.0;
        final finalWhole = double.tryParse(r.wholePack.text) ?? 0.0;
        final finalRetail = double.tryParse(r.retailPiece.text) ?? 0.0;
        final finalReorder = int.tryParse(r.reorderLevel.text) ?? 5;
        final finalStock = double.tryParse(r.stockPacks.text) ?? 0.0;

        await prov.addProduct(ProductModel(
          code: r.code.toUpperCase(),
          name: r.name,
          brand: finalBrand,
          category: finalCategory,
          supplierId: finalSupplierId,
          unitsPerPack: finalUpp,
          costPricePerPack: finalCost,
          wholesalePricePerPack: finalWhole,
          retailPricePerPiece: finalRetail,
          reorderLevel: finalReorder,
          stockPacks: finalStock,
          avgCostPerPack: finalCost,
          createdAt: DateTime.now(),
        ));
        count++;
      } catch (e) {
        errors.add('${r.name}: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }

    if (mounted) {
      context.read<DashboardProvider>().loadStats();
      setState(() => _importing = false);
      
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count products imported successfully!')));
        Navigator.pop(context);
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Import Completed with Errors'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text('Successfully imported $count products.'),
                  const SizedBox(height: 12),
                  Text('Failed to import ${errors.length} products:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  const SizedBox(height: 8),
                  ...errors.map((e) => Text('• $e', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close import screen
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            // ── Header bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 18),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  const Icon(Icons.upload_file_rounded,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Import from Excel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text(
                          _pickedFileName != null
                              ? _pickedFileName!
                              : 'Browse to your Product Master Data Excel file',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Browse button
                  TextButton.icon(
                    onPressed: _loading == true ? null : _pickAndLoadExcel,
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: Text(_rows.isEmpty ? 'Browse File' : 'Change File'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            if (_loading == null)
              // Waiting for user to pick a file
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_rounded,
                          size: 72, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('No file selected',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Browse File" to choose your Excel file.\n'
                        'Products are read automatically — categories\n'
                        'are detected from the section headers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _pickAndLoadExcel,
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Browse File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loading == true)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent)))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 56, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Failed to read file',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _pickAndLoadExcel,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Try Another File'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // ── Global defaults toolbar ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apply to ALL rows:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _miniField(_globalBrand, 'Brand (all)')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _miniField(_globalCategory, 'Category (all)')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _miniField(_globalUpp, 'Units/Pack (all)',
                                numeric: true)),
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

              // ── Table column headers ─────────────────────────────────────
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
              Divider(height: 1, color: AppColors.border),

              // ── Product rows ─────────────────────────────────────────────
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.border),
                    itemBuilder: (ctx, i) =>
                        _buildRow(_rows[i], suppliers, i),
                  ),
                ),
              ),
            ],

            // ── Footer ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Text(
                    _rows.isEmpty
                        ? 'No file loaded'
                        : '${_rows.length} rows  •  $selectedCount selected',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        (_loading == true || _importing || _rows.isEmpty)
                            ? null
                            : _import,
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

  // ── Row widgets ───────────────────────────────────────────────────────────

  Widget _buildRow(_ImportRow r, List<SupplierModel> suppliers, int index) {
    final bg = index.isEven ? AppColors.card : AppColors.cardHover;
    return Container(
      color: r.selected ? bg : AppColors.surface,
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
          _uomBadge(r.unitOfMeasure, 50),
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
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<int>(
                    value: r.supplierId,
                    hint: Text('Select',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    dropdownColor: AppColors.card,
                    isExpanded: true,
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    items: suppliers
                        .map<DropdownMenuItem<int>>((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
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
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _staticCell(String text, double width, {bool mono = false}) =>
      SizedBox(
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

  Widget _uomBadge(String uom, double width) => SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: uom.toUpperCase().contains('PACK')
                  ? AppColors.infoBg
                  : AppColors.successBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              uom.toUpperCase().contains('PACK') ? 'PACK' : 'PCS',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: uom.toUpperCase().contains('PACK')
                      ? AppColors.info
                      : AppColors.success),
            ),
          ),
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
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
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
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.border),
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
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
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
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 12)),
            dropdownColor: AppColors.card,
            isExpanded: true,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            items: suppliers
                .map<DropdownMenuItem<int>>(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}
