import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ice_cream_pos/core/database.dart';
import 'package:ice_cream_pos/core/logger.dart';
import 'package:ice_cream_pos/models/product.dart';

class ImportUtils {
  static const List<String> csvHeaders = [
    'Name',
    'Barcode',
    'Category',
    'Company',
    'Type',
    'Price',
    'MRP',
    'Discount',
    'Stock',
    'Minimum Stock',
    'Is Box Piece (Yes/No)',
    'Pieces Per Box',
    'Box Barcode',
    'Box Price',
    'Box MRP',
    'Box Discount'
  ];

  /// Generates and saves a blank CSV template
  static Future<void> generateCsvTemplate() async {
    try {
      List<List<dynamic>> rows = [csvHeaders];
      // Add a dummy row to help user understand the format
      rows.add([
        'Sample Vanilla 500ml',
        '123456789',
        'Ice Creams',
        'Company A',
        'Ice Cream',
        '100.0',
        '120.0',
        '20.0',
        '0', // Initial stock 0 as requested
        '10',
        'No',
        '1',
        '',
        '0.0',
        '0.0',
        '0.0'
      ]);

      String csvData = const ListToCsvConverter().convert(rows);

      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save CSV Template',
        fileName: 'Product_Import_Template.csv',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csvData);
      }
    } catch (e, st) {
      await AppLogger.log('ImportUtils', 'Failed to generate CSV template', exception: e, stackTrace: st);
      rethrow;
    }
  }

  /// Imports products from a CSV file using a strict transaction
  static Future<int> importProductsFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        throw Exception("No file selected");
      }

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter(shouldParseNumbers: false).convert(csvString);

      if (rows.isEmpty) {
        throw Exception("CSV file is empty");
      }

      // Check Headers (basic validation)
      final headers = rows.first.map((e) => e.toString().trim()).toList();
      if (!headers.contains('Name') || !headers.contains('Price')) {
        throw Exception("Invalid CSV format. Missing required columns 'Name' or 'Price'. Please use the template.");
      }

      List<Product> parsedProducts = [];
      Set<String> seenBarcodesInCsv = {};

      // Parse Rows
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.join('').trim().isEmpty) continue; // Skip empty rows

        Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length; j++) {
          if (j < row.length) {
            rowData[headers[j]] = row[j].toString().trim();
          } else {
            rowData[headers[j]] = '';
          }
        }

        final name = rowData['Name'] ?? '';
        if (name.isEmpty) throw Exception("Row ${i + 1}: Name cannot be empty.");

        final priceStr = rowData['Price'] ?? '0';
        final price = double.tryParse(priceStr) ?? 0.0;
        if (price < 0) throw Exception("Row ${i + 1}: Price cannot be negative.");

        final barcode = rowData['Barcode']?.toString().trim();
        final boxBarcode = rowData['Box Barcode']?.toString().trim();

        // Check for duplicates within the CSV itself
        if (barcode != null && barcode.isNotEmpty) {
          if (seenBarcodesInCsv.contains(barcode)) {
            throw Exception("Row ${i + 1}: Duplicate barcode '$barcode' found in the CSV.");
          }
          seenBarcodesInCsv.add(barcode);
        }
        if (boxBarcode != null && boxBarcode.isNotEmpty) {
          if (seenBarcodesInCsv.contains(boxBarcode)) {
            throw Exception("Row ${i + 1}: Duplicate box barcode '$boxBarcode' found in the CSV.");
          }
          seenBarcodesInCsv.add(boxBarcode);
        }

        final isBoxPieceStr = rowData['Is Box Piece (Yes/No)']?.toString().toLowerCase() ?? 'no';
        final isBoxPiece = isBoxPieceStr == 'yes' || isBoxPieceStr == 'true' || isBoxPieceStr == '1';

        parsedProducts.add(Product(
          name: name,
          barcode: barcode!.isEmpty ? null : barcode,
          category: rowData['Category']?.toString().isEmpty ?? true ? 'Uncategorized' : rowData['Category'],
          company: rowData['Company']?.toString().isEmpty ?? true ? 'Other' : rowData['Company'],
          type: rowData['Type']?.toString().isEmpty ?? true ? 'Ice Cream' : rowData['Type'],
          price: price,
          mrp: double.tryParse(rowData['MRP'] ?? '0') ?? price,
          discount: double.tryParse(rowData['Discount'] ?? '0') ?? 0.0,
          stock: int.tryParse(rowData['Stock'] ?? '0') ?? 0,
          minimumStock: int.tryParse(rowData['Minimum Stock'] ?? '10') ?? 10,
          isBoxPiece: isBoxPiece,
          piecesPerBox: int.tryParse(rowData['Pieces Per Box'] ?? '1') ?? 1,
          boxBarcode: boxBarcode == null || boxBarcode.isEmpty ? null : boxBarcode,
          boxPrice: double.tryParse(rowData['Box Price'] ?? '0') ?? 0.0,
          boxMrp: double.tryParse(rowData['Box MRP'] ?? '0') ?? 0.0,
          boxDiscount: double.tryParse(rowData['Box Discount'] ?? '0') ?? 0.0,
          isActive: true, // Always active on import
        ));
      }

      if (parsedProducts.isEmpty) {
        throw Exception("No valid product data found in the CSV.");
      }

      // Perform Batch Insert in Transaction
      final db = await DatabaseHelper.instance.database;
      
      await db.transaction((txn) async {
        // Fetch all existing barcodes to check for duplicates
        final existingProducts = await txn.query('products', columns: ['barcode', 'box_barcode', 'is_active']);
        Set<String> existingActiveBarcodes = {};
        for (var p in existingProducts) {
          if (p['is_active'] == 1) {
             if (p['barcode'] != null && p['barcode'].toString().isNotEmpty) existingActiveBarcodes.add(p['barcode'].toString());
             if (p['box_barcode'] != null && p['box_barcode'].toString().isNotEmpty) existingActiveBarcodes.add(p['box_barcode'].toString());
          }
        }

        for (var product in parsedProducts) {
          // Validate against DB duplicates
          if (product.barcode != null && existingActiveBarcodes.contains(product.barcode)) {
            throw Exception("Barcode '${product.barcode}' already exists in the database. Import rejected.");
          }
          if (product.boxBarcode != null && existingActiveBarcodes.contains(product.boxBarcode)) {
            throw Exception("Box Barcode '${product.boxBarcode}' already exists in the database. Import rejected.");
          }
          
          await txn.insert('products', product.toMap());
        }
      });

      return parsedProducts.length;

    } catch (e, st) {
      await AppLogger.log('ImportUtils', 'Failed to import products from CSV', exception: e, stackTrace: st);
      rethrow;
    }
  }
}
