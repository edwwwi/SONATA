import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ice_cream_pos/core/database.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    );
  }
}
