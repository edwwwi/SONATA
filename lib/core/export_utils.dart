import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ice_cream_pos/models/sale.dart';
import 'package:ice_cream_pos/models/product.dart';
import 'package:intl/intl.dart';

class ExportUtils {
  static Future<void> exportSalesCsv(List<Sale> sales) async {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Bill Number", "Total Amount", "Date"]);
    for (var sale in sales) {
      rows.add([
        sale.id,
        sale.billNumber,
        sale.totalAmount,
        DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    await _saveFile(
      csvData,
      "Sales_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv",
    );
  }

  static Future<void> exportStockCsv(List<Product> products) async {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Name", "Category", "Price", "Current Stock"]);
    for (var p in products) {
      rows.add([p.id, p.name, p.category, p.price, p.stock]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    await _saveFile(
      csvData,
      "Stock_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv",
    );
  }

  static Future<void> exportDailyReportPdf(
    List<Sale> sales,
    List<Product> products,
  ) async {
    final pdf = pw.Document();

    final today = DateTime.now();
    final todaySales = sales
        .where(
          (s) =>
              s.createdAt.year == today.year &&
              s.createdAt.month == today.month &&
              s.createdAt.day == today.day,
        )
        .toList();

    double totalSales = todaySales.fold(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    /////l,l
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Ice Cream Shop - Daily Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(today)}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 24),

              pw.Text(
                'Sales Summary',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.Text(
                'Total Bills: ${todaySales.length}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                'Total Sales Amount: \$${totalSales.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 24),

              pw.Text(
                'Current Stock Summary',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Product', 'Category', 'Stock'],
                  ...products.map(
                    (p) => [p.name, p.category, p.stock.toString()],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await _saveFile(
      bytes,
      "Daily_Report_${DateFormat('yyyy_MM_dd').format(today)}.pdf",
      isBytes: true,
    );
  }

  static Future<void> _saveFile(
    dynamic data,
    String defaultName, {
    bool isBytes = false,
  }) async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Save Report',
      fileName: defaultName,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      if (isBytes) {
        await file.writeAsBytes(data as List<int>);
      } else {
        await file.writeAsString(data as String);
      }
    }
  }
}
