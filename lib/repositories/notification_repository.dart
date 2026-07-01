import 'package:ice_cream_pos/core/database.dart';
import 'package:ice_cream_pos/models/notification_settings.dart';

class NotificationRepository {
  Future<NotificationSettings> getSettings() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('settings', limit: 1);
    
    if (maps.isNotEmpty) {
      return NotificationSettings.fromMap(maps.first);
    }
    
    return NotificationSettings();
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('settings', limit: 1);
    
    if (maps.isNotEmpty) {
      final id = maps.first['id'] as int;
      await db.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [id]);
    } else {
      // In case settings is empty (should not happen due to default pin insert)
      final map = settings.toMap();
      map['owner_pin'] = '1978'; // fallback
      await db.insert('settings', map);
    }
  }
}
