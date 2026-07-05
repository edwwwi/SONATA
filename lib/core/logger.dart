import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class AppLogger {
  static Future<File> get _logFile async {
    final appDocDir = await getApplicationSupportDirectory();
    final logsDir = Directory(join(appDocDir.path, 'logs'));
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    return File(join(logsDir.path, 'application.log'));
  }

  static Future<void> log(String screen, String message, {dynamic exception, StackTrace? stackTrace}) async {
    try {
      final file = await _logFile;
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      final buffer = StringBuffer();
      buffer.writeln('[$timestamp] [$screen] $message');
      
      if (exception != null) {
        buffer.writeln('Exception: $exception');
      }
      if (stackTrace != null) {
        buffer.writeln('StackTrace:\n$stackTrace');
      }
      
      buffer.writeln('----------------------------------------');
      
      await file.writeAsString(buffer.toString(), mode: FileMode.append);
      
      // Also print to console during development
      print(buffer.toString());
    } catch (e) {
      print('Failed to write to log file: $e');
    }
  }
}
