import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/core/database.dart';
import 'package:ice_cream_pos/core/import_utils.dart' as import_utils;
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'dart:io';
/////settings screen 
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isImporting = false;

  Future<void> _backupDatabase() async {
    final result = await FilePicker.getDirectoryPath();
    if (result != null) {
      final success = await DatabaseHelper.instance.backupDatabase(result);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup Completed Successfully'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup Failed'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _restoreDatabase() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text('Restoring the database will overwrite all current data.\nProceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null && result.files.single.path != null) {
        final success = await DatabaseHelper.instance.restoreDatabase(result.files.single.path!);
        if (mounted) {
          if (success) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Database Restored Successfully'),
                  content: const Text('The application must be restarted to apply changes.'),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        // Exit the application
                        exit(0);
                      },
                      child: const Text('Restart'),
                    ),
                  ],
                );
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restore Failed'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('Product Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download, color: Colors.blue),
                      title: const Text('Download CSV Template'),
                      subtitle: const Text('Get the template for bulk product import'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await import_utils.ImportUtils.generateCsvTemplate();
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        },
                        child: const Text('Download'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.upload_file, color: Colors.green),
                      title: const Text('Import Products'),
                      subtitle: const Text('Import products from a CSV file'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, foregroundColor: Colors.green),
                        onPressed: _isImporting ? null : () async {
                          setState(() => _isImporting = true);
                          try {
                            final count = await import_utils.ImportUtils.importProductsFromCsv();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported $count products'), backgroundColor: Colors.green));
                              ref.invalidate(productProvider);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
                            }
                          } finally {
                            if (mounted) setState(() => _isImporting = false);
                          }
                        },
                        child: _isImporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Import'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Factory Reset / Clear All Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Wipe all products, bills, and stock history'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Column(
                                  children: const [
                                    Icon(Icons.warning_amber_rounded, size: 64, color: Colors.red),
                                    SizedBox(height: 16),
                                    Text('CLEAR ALL DATA?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: const Text('This will permanently delete all products, bills, stock history, and all other data. It cannot be undone. Are you absolutely sure?', textAlign: TextAlign.center),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('ERASE EVERYTHING'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true) {
                            try {
                              final db = await DatabaseHelper.instance.database;
                              await db.transaction((txn) async {
                                await txn.delete('sale_items');
                                await txn.delete('sales');
                                await txn.delete('stock_movements');
                                await txn.delete('products');
                              });
                              if (mounted) {
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Data Cleared Successfully'),
                                      content: const Text('The application must be restarted to apply changes.'),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            exit(0);
                                          },
                                          child: const Text('Restart'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                              }
                            }
                          }
                        },
                        child: const Text('Clear Data'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Database Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download, color: Colors.blue),
                      title: const Text('Backup Database'),
                      subtitle: const Text('Save a copy of your database to a folder'),
                      trailing: ElevatedButton(
                        onPressed: _backupDatabase,
                        child: const Text('Backup'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.red),
                      title: const Text('Restore Database'),
                      subtitle: const Text('Replace current database from a backup file'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red),
                        onPressed: _restoreDatabase,
                        child: const Text('Restore'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Cloud Backup (Coming Soon)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud, color: Colors.grey),
                      title: const Text('Google Drive Backup', style: TextStyle(color: Colors.grey)),
                      trailing: ElevatedButton(
                        onPressed: null,
                        child: const Text('Connect'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.cloud_upload, color: Colors.grey),
                      title: const Text('OneDrive Backup', style: TextStyle(color: Colors.grey)),
                      trailing: ElevatedButton(
                        onPressed: null,
                        child: const Text('Connect'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.save_alt, color: Colors.grey),
                      title: const Text('External Hard Disk Backup', style: TextStyle(color: Colors.grey)),
                      trailing: ElevatedButton(
                        onPressed: null,
                        child: const Text('Configure'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
