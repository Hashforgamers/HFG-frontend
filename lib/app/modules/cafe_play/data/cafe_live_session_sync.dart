import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/app/modules/cafe_play/data/cafe_play_api.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers cafe session ids this user started or saw on this device, so the
/// home live-session card can show them. There is no "my cafe sessions" list
/// endpoint yet, so each remembered id is polled individually.
class CafeSessionStore {
  CafeSessionStore._();

  static const _maxIds = 5;

  static String? get _key {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : 'cafe_session_ids_$uid';
  }

  static Future<List<String>> ids() async {
    final key = _key;
    if (key == null) return const [];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const [];
  }

  static Future<void> remember(String sessionId) async {
    final key = _key;
    if (key == null || sessionId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = [
      sessionId,
      ...(prefs.getStringList(key) ?? const <String>[]).where(
        (id) => id != sessionId,
      ),
    ].take(_maxIds).toList();
    await prefs.setStringList(key, list);
    CafeLiveSessionSync.instance.refresh();
  }

  static Future<void> forget(Iterable<String> sessionIds) async {
    final key = _key;
    if (key == null) return;
    final drop = sessionIds.toSet();
    if (drop.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(key) ?? const <String>[])
        .where((id) => !drop.contains(id))
        .toList();
    await prefs.setStringList(key, list);
  }
}

/// Polls remembered cafe sessions and publishes the running ones.
class CafeLiveSessionSync {
  CafeLiveSessionSync._();

  static final CafeLiveSessionSync instance = CafeLiveSessionSync._();

  static const _pollEvery = Duration(seconds: 30);

  /// Sessions currently reserved or active, newest first.
  final ValueNotifier<List<CafeSession>> sessions = ValueNotifier(const []);

  Timer? _timer;
  bool _fetching = false;

  void start() {
    _timer ??= Timer.periodic(_pollEvery, (_) => refresh());
    refresh();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final ids = await CafeSessionStore.ids();
      final live = <CafeSession>[];
      final finished = <String>[];
      for (final id in ids) {
        try {
          final s = await CafePlayApi.instance.getSession(id);
          if (s.isTerminal) {
            finished.add(id);
          } else {
            live.add(s);
          }
        } on CafePlayException catch (e) {
          // Gone or not ours: stop polling it. Network blips keep the id.
          if (e.statusCode == 403 || e.statusCode == 404) finished.add(id);
        }
      }
      await CafeSessionStore.forget(finished);
      sessions.value = live;
    } catch (e) {
      debugPrint('Cafe live session sync failed: $e');
    } finally {
      _fetching = false;
    }
  }
}
