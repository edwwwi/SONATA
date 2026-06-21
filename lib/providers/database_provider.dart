import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/core/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseHelper.instance.database;
});
