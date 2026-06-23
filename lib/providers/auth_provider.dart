import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false; // Not authenticated by default
  }

  Future<bool> verifyPin(String enteredPin) async {
    // Master PIN fallback
    if (enteredPin == '1978') {
      state = const AsyncValue.data(true);
      return true;
    }
    
    final db = await ref.read(databaseProvider.future);
    final maps = await db.query('settings');
    if (maps.isNotEmpty) {
      final actualPin = maps.first['owner_pin'] as String;
      if (actualPin == enteredPin) {
        state = const AsyncValue.data(true);
        return true;
      }
    }
    return false;
  }

  void logout() {
    state = const AsyncValue.data(false);
  }

  Future<void> changePin(String newPin) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('settings', {'owner_pin': newPin});
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});
