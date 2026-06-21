import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/supplier_model.dart';
import '../../core/providers/supplier_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_text_field.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SupplierProvider>();
    final suppliers = prov.suppliers;

    return Column(
      children: [
        PageHeader(
          title: 'Suppliers',
          subtitle: '${suppliers.length} suppliers registered',
          actions: [
            HeaderButton(
              label: 'Add Supplier',
              icon: Icons.add,
              isPrimary: true,
              onPressed: () => _showForm(context),
            ),
          ],
        ),
        Expanded(
          child: prov.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : suppliers.isEmpty
                  ? const Center(
                      child: Text('No suppliers yet',
                          style: TextStyle(color: AppColors.textMuted)))
                  : Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
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
                                0: FixedColumnWidth(60),
                                1: FlexColumnWidth(3),
                                2: FlexColumnWidth(2),
                                3: FlexColumnWidth(2),
                                4: FixedColumnWidth(120),
                              },
                              children: [
                                _header(),
                                ...suppliers.asMap().entries.map(
                                    (e) => _row(context, e.value, e.key)),
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
        children: ['#', 'Supplier Name', 'Phone', 'Joined', 'Actions']
            .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(c,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ))
            .toList(),
      );

  TableRow _row(
      BuildContext context, SupplierModel s, int index) {
    final bg = index.isEven ? AppColors.card : AppColors.cardHover;
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _cell('${index + 1}', muted: true),
        _cell(s.name, bold: true),
        _cell(s.phone ?? '—', muted: s.phone == null),
        _cell(formatDate(s.createdAt)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _iconBtn(Icons.edit_outlined, AppColors.info,
                  () => _showForm(context, supplier: s)),
              const SizedBox(width: 6),
              _iconBtn(Icons.delete_outline, AppColors.error,
                  () => _confirmDelete(context, s)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, bool muted = false}) =>
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text,
            style: TextStyle(
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            )),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 15, color: color),
        ),
      );

  void _showForm(BuildContext context, {SupplierModel? supplier}) {
    showDialog(
      context: context,
      builder: (_) => _SupplierFormDialog(supplier: supplier),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SupplierModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Delete "${s.name}"? This cannot be undone.'),
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
      context.read<SupplierProvider>().deleteSupplier(s.id!);
    }
  }
}

class _SupplierFormDialog extends StatefulWidget {
  final SupplierModel? supplier;
  const _SupplierFormDialog({this.supplier});

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.supplier?.name ?? '');
    _phone = TextEditingController(text: widget.supplier?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final s = SupplierModel(
      id: widget.supplier?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      createdAt: widget.supplier?.createdAt ?? DateTime.now(),
    );
    try {
      final prov = context.read<SupplierProvider>();
      if (widget.supplier != null) {
        await prov.updateSupplier(s);
      } else {
        await prov.addSupplier(s);
      }
      if (mounted) Navigator.pop(context);
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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.supplier != null
                        ? 'Edit Supplier'
                        : 'Add Supplier',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _name,
                  label: 'Supplier Name *',
                  autofocus: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phone,
                  label: 'Phone Number (optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : Text(widget.supplier != null ? 'Save' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
