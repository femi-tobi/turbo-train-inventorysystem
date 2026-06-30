import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/product_model.dart';
import '../../core/models/sale_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/formatters.dart';

class ReceiptDialog extends StatefulWidget {
  final SaleModel sale;
  final ProductModel product;

  const ReceiptDialog({
    super.key,
    required this.sale,
    required this.product,
  });

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 420, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  const Text('Sale Receipt',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18)),
                ],
              ),
            ),

            // Receipt body
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Store name
                    const Text('LAGOS STORE',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(height: 2),
                    Text('Inventory Management System',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                    SizedBox(height: 16),
                    Text('Receipt #${widget.sale.receiptId}',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontFamily: 'monospace')),
                    SizedBox(height: 20),
                    Divider(color: AppColors.border),
                    const SizedBox(height: 16),

                    _row('Date', formatDateTime(widget.sale.saleDate)),
                    const SizedBox(height: 8),
                    _row('Customer', widget.sale.customerType),
                    const SizedBox(height: 8),
                    _row('Type', widget.sale.saleTypeLabel),
                    SizedBox(height: 16),
                    Divider(color: AppColors.border),
                    const SizedBox(height: 16),

                    // Product details
                    _row('Product', widget.sale.productName ?? widget.product.name),
                    const SizedBox(height: 8),
                    _row('Code', widget.product.code),
                    const SizedBox(height: 8),
                    _row('Brand', widget.product.brand),
                    const SizedBox(height: 8),
                    if (widget.sale.saleType == 'wholesale')
                      _row('Quantity',
                          '${formatNumber(widget.sale.qtyPacks)} Packs')
                    else
                      _row('Quantity',
                          '${formatNumber(widget.sale.qtyPieces)} Pieces'),
                    const SizedBox(height: 8),
                    _row(
                        'Unit Price',
                        '${formatNaira(widget.sale.unitPrice)} / '
                            '${widget.sale.saleType == "wholesale" ? "pack" : "piece"}'),

                    SizedBox(height: 16),
                    Divider(color: AppColors.border),
                    const SizedBox(height: 16),

                    // Totals
                    _row('Sub-total',
                        formatNaira(widget.sale.totalAmount),
                        bold: true),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentGlow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL PAID',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                          Text(formatNaira(widget.sale.totalAmount),
                              style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(color: AppColors.border),
                    SizedBox(height: 8),
                    Text('Thank you for your business!',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

            // Print button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border:
                      Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _printReceipt(context),
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print Receipt'),
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

  Widget _row(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w500)),
        ],
      );

  Future<void> _printReceipt(BuildContext context) async {
    final doc = pw.Document();
    final isWholesale = widget.sale.saleType == 'wholesale';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('LAGOS STORE',
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2)),
              pw.SizedBox(height: 4),
              pw.Text('Sales Receipt',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Text('Receipt #${widget.sale.receiptId}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _pdfRow('Date', formatDateTime(widget.sale.saleDate)),
              _pdfRow('Customer', widget.sale.customerType),
              _pdfRow('Type', widget.sale.saleTypeLabel),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _pdfRow('Product', widget.sale.productName ?? widget.product.name),
              _pdfRow('Code', widget.product.code),
              _pdfRow('Brand', widget.product.brand),
              _pdfRow(
                  'Quantity',
                  isWholesale
                      ? '${formatNumber(widget.sale.qtyPacks)} Packs'
                      : '${formatNumber(widget.sale.qtyPieces)} Pieces'),
              _pdfRow(
                  'Unit Price',
                  'NGN ${formatNaira(widget.sale.unitPrice).replaceAll('₦', '')} / '
                      '${isWholesale ? "pack" : "piece"}'),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL PAID',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(
                      'NGN ${formatNaira(widget.sale.totalAmount).replaceAll("₦", "")}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 18)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Thank you for your business!',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'Receipt_${widget.sale.receiptId}',
    );
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text(value,
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );
}
