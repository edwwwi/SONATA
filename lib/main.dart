import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/core/database.dart';
import 'package:ice_cream_pos/core/theme.dart';
import 'package:ice_cream_pos/screens/shell_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'dart:io';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(args, "ice_cream_pos_sonata", onSecondWindow: (args) {
      // Logic when user tries to open a second instance
    });
  }
  
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  
  // Ensure DB is initialized before starting
  await DatabaseHelper.instance.database;

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ice Cream POS',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const ShellScreen(),
    );
  }
}
