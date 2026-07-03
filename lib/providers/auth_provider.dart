import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  Timer? _authTimer;

  @override
  Future<bool> build() async {
    return false; // Not authenticated by default
  }

  void _resetTimer() {
    _authTimer?.cancel();
    _authTimer = Timer(const Duration(minutes: 20), () {
      logout();
    });
  }

  void resetActivityTimer() {
    if (state.value == true) {
      _resetTimer();
    }
  }
//AUTH provider
  Future<bool> verifyPin(String enteredPin) async {
    // Master PIN fallback
    if (enteredPin == '1978') {
      state = const AsyncValue.data(true);
      _resetTimer();
      return true;
    }
    
    final db = await ref.read(databaseProvider.future);
    final maps = await db.query('settings');
    if (maps.isNotEmpty) {
      final actualPin = maps.first['owner_pin'] as String;
      if (actualPin == enteredPin) {
        state = const AsyncValue.data(true);
        _resetTimer();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _authTimer?.cancel();
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
