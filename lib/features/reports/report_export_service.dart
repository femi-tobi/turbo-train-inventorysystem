import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../shared/utils/formatters.dart';

class ReportExportService {
  final DatabaseHelper _db = DatabaseHelper();

  // ── Helper: write header + data rows ──
  Excel _buildExcel(String sheetName, List<String> headers,
      List<List<dynamic>> rows) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Header row
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#10B981'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
      );
    }

    // Data rows
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final v = rows[r][c];
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        if (v is double || v is int) {
          cell.value = DoubleCellValue((v as num).toDouble());
        } else {
          cell.value = TextCellValue(v?.toString() ?? '');
        }
      }
    }

    // Auto column width
    for (int c = 0; c < headers.length; c++) {
      sheet.setColumnWidth(c, 20);
    }

    return excel;
  }

  Future<void> _save(BuildContext context, Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) return;

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (path != null) {
      await File(path).writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved: $path'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    }
  }

  // ── REPORT 1: Inventory by Brand ──
  Future<void> exportInventoryByBrand(BuildContext context) async {
    final data = await _db.reportInventoryByBrand();
    final excel = _buildExcel(
      'Inventory by Brand',
      ['Brand', 'Product Name', 'Stock (Packs)', 'Stock (Pieces)', 'Inventory Value (NGN)'],
      data.map((r) => [
        r['brand'],
        r['product_name'],
        r['stock_packs'],
        r['stock_pieces'],
        r['inventory_value'],
      ]).toList(),
    );
    if (context.mounted) await _save(context, excel, 'Inventory_by_Brand.xlsx');
  }

  // ── REPORT 2: Sales Report ──
  Future<void> exportSalesReport(BuildContext context,
      {String? dateFrom, String? dateTo, int? productId, String? saleType}) async {
    final data = await _db.getSales(
        dateFrom: dateFrom, dateTo: dateTo, productId: productId, saleType: saleType);
    final excel = _buildExcel(
      'Sales Report',
      ['Date', 'Product', 'Sale Type', 'Qty Sold', 'Sales Amount (NGN)', 'COGS (NGN)', 'Profit (NGN)'],
      data.map((s) => [
        formatDate(s.saleDate),
        s.productName ?? '—',
        s.saleTypeLabel,
        s.saleType == 'wholesale'
            ? '${formatNumber(s.qtyPacks)} packs'
            : '${formatNumber(s.qtyPieces)} pieces',
        s.totalAmount,
        s.cogs,
        s.grossProfit,
      ]).toList(),
    );
    if (context.mounted) await _save(context, excel, 'Sales_Report.xlsx');
  }

  // ── REPORT 3: Daily Sales ──
  Future<void> exportDailySales(BuildContext context) async {
    final data = await _db.reportDailySales();
    final excel = _buildExcel(
      'Daily Sales',
      ['Date', 'Wholesale (NGN)', 'Retail (NGN)', 'Total (NGN)'],
      data.map((r) => [
        r['sale_day'],
        r['wholesale_amount'],
        r['retail_amount'],
        r['total_amount'],
      ]).toList(),
    );
    if (context.mounted) await _save(context, excel, 'Daily_Sales_Report.xlsx');
  }

  // ── REPORT 4: Monthly Sales ──
  Future<void> exportMonthlySales(BuildContext context) async {
    final data = await _db.reportMonthlySales();
    final excel = _buildExcel(
      'Monthly Sales',
      ['Month', 'Wholesale (NGN)', 'Retail (NGN)', 'Total (NGN)'],
      data.map((r) => [
        formatMonth(r['sale_month'] as String),
        r['wholesale_amount'],
        r['retail_amount'],
        r['total_amount'],
      ]).toList(),
    );
    if (context.mounted) await _save(context, excel, 'Monthly_Sales_Report.xlsx');
  }

  // ── REPORT 5: Purchase Report ──
  Future<void> exportPurchaseReport(BuildContext context,
      {String? dateFrom, String? dateTo}) async {
    final data = await _db.getPurchases(dateFrom: dateFrom, dateTo: dateTo);
    final excel = _buildExcel(
      'Purchase Report',
      ['Date', 'Supplier', 'Product', 'Qty (Packs)', 'Cost Amount (NGN)'],
      data.map((p) => [
        formatDate(p.purchaseDate),
        p.supplierName ?? '—',
        p.productName ?? '—',
        p.qtyPacks,
        p.totalCost,
      ]).toList(),
    );
    if (context.mounted) await _save(context, excel, 'Purchase_Report.xlsx');
  }

  // ── REPORT 6: Profit Report ──
  Future<void> exportProfitReport(BuildContext context) async {
    final data = await _db.reportProfit();
    final excel = _buildExcel(
      'Profit Report',
      ['Product', 'Sales Revenue (NGN)', 'COGS (NGN)', 'Gross Profit (NGN)'],
      data.map((r) => [
        r['product_name'],
        r['sales_revenue'],
        r['total_cogs'],
        r['gross_profit'],
      ]).toList(),
    );
    if (context.mounted) await _save(context, excel, 'Profit_Report.xlsx');
  }

  // ── REPORT 7: Brand Performance ──
  Future<void> exportBrandPerformance(BuildContext context) async {
    final data = await _db.reportBrandPerformance();
    final excel = _buildExcel(
      'Brand Performance',
      ['Brand', 'Qty Sold', 'Sales Amount (NGN)', 'Profit (NGN)'],
      data.map((r) => [
        r['brand'],
        r['qty_sold'],
        r['sales_amount'],
        r['profit'],
      ]).toList(),
    );
    if (context.mounted) await _save(context, excel, 'Brand_Performance.xlsx');
  }
}
