import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/app/modules/rewards/models/squad_weekly_progress.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SquadMissionAction {
  static const playSession = 'play_session';
  static const watchLive = 'watch_live';
  static const joinTournament = 'join_tournament';
  static const referFriend = 'refer_friend';
}

class SquadMissionsService {
  SquadMissionsService({
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _preferences = preferences ?? locator<SharedPreferences>();

  static const String _collection = 'squad_weekly_missions_v1';
  static const String _activeSquadKey = 'active_squad_key';
  static const String _activeSquadName = 'active_squad_name';
  static const String _activeSquadSetAt = 'active_squad_set_at';

  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;

  static const Map<String, Map<String, dynamic>> _defaultMissionDefs = {
    'join_tournament': {
      'title': 'Join 1 Tournament',
      'target': 1,
      'reward': 30,
    },
    'play_sessions': {'title': 'Play 3 Sessions', 'target': 3, 'reward': 25},
    'refer_friends': {'title': 'Refer 1 Friend', 'target': 1, 'reward': 20},
    'watch_live_minutes': {
      'title': 'Watch Live 30 Mins',
      'target': 30,
      'reward': 15,
    },
  };

  Future<void> setActiveSquad({
    required String squadKey,
    String? squadName,
  }) async {
    final safeKey = squadKey.trim();
    if (safeKey.isEmpty) return;
    await _preferences.setString(_activeSquadKey, safeKey);
    await _preferences.setString(
      _activeSquadSetAt,
      DateTime.now().toIso8601String(),
    );
    if ((squadName ?? '').trim().isNotEmpty) {
      await _preferences.setString(_activeSquadName, squadName!.trim());
    }
  }

  Future<void> clearActiveSquad() async {
    await _preferences.remove(_activeSquadKey);
    await _preferences.remove(_activeSquadName);
    await _preferences.remove(_activeSquadSetAt);
  }

  Future<void> trackAction({
    required String action,
    int increment = 1,
    String? squadKey,
    String? squadName,
  }) async {
    final uid = _resolveUid();
    if (uid.isEmpty) return;

    final effectiveSquadKey = _resolveSquadKey(uid: uid, input: squadKey);
    final effectiveSquadName = _resolveSquadName(input: squadName);
    final now = DateTime.now();
    final today = _dateKey(now);
    final weekInfo = _weekInfo(now);
    final docRef = _docRef(
      squadKey: effectiveSquadKey,
      weekId: weekInfo.weekId,
    );

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final existing = snap.data();
        final payload = _buildOrMergePayload(
          existing: existing,
          squadKey: effectiveSquadKey,
          squadName: effectiveSquadName,
          uid: uid,
          weekId: weekInfo.weekId,
          weekStartIso: weekInfo.startIso,
          weekEndIso: weekInfo.endIso,
          action: action,
          increment: increment <= 0 ? 1 : increment,
          today: today,
        );
        tx.set(docRef, payload, SetOptions(merge: true));
      });
    } catch (e, st) {
      AppLogger.e('SquadMissions trackAction failed', error: e, stackTrace: st);
    }
  }

  Future<bool> claimMission(String missionKey) async {
    final uid = _resolveUid();
    if (uid.isEmpty) return false;
    final squadKey = _resolveSquadKey(uid: uid);
    final weekInfo = _weekInfo(DateTime.now());
    final docRef = _docRef(squadKey: squadKey, weekId: weekInfo.weekId);

    try {
      return await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists || snap.data() == null) return false;

        final data = Map<String, dynamic>.from(snap.data()!);
        final missions = Map<String, dynamic>.from(
          data['missions'] as Map? ?? const {},
        );
        final missionRaw = missions[missionKey];
        if (missionRaw is! Map) return false;
        final mission = Map<String, dynamic>.from(missionRaw);

        final progress = (mission['progress'] as num? ?? 0).toInt();
        final target = (mission['target'] as num? ?? 0).toInt();
        final claimed = mission['claimed'] == true;
        if (claimed || progress < target) return false;

        mission['claimed'] = true;
        mission['claimed_at'] = DateTime.now().toIso8601String();
        missions[missionKey] = mission;

        tx.set(docRef, {
          'missions': missions,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      });
    } catch (e, st) {
      AppLogger.e(
        'SquadMissions claimMission failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Stream<SquadWeeklyProgress?> watchCurrentWeekProgress() {
    final uid = _resolveUid();
    if (uid.isEmpty) return const Stream<SquadWeeklyProgress?>.empty();
    final squadKey = _resolveSquadKey(uid: uid);
    final weekInfo = _weekInfo(DateTime.now());
    return _docRef(squadKey: squadKey, weekId: weekInfo.weekId).snapshots().map(
      (snap) {
        final data = snap.data();
        if (data == null) return null;
        return SquadWeeklyProgress.fromMap(data);
      },
    );
  }

  Stream<SquadWeeklyProgress?> watchWeekProgressForSquad({
    required String squadKey,
  }) {
    final safeKey = squadKey.trim();
    if (safeKey.isEmpty) return const Stream<SquadWeeklyProgress?>.empty();
    final weekInfo = _weekInfo(DateTime.now());
    return _docRef(squadKey: safeKey, weekId: weekInfo.weekId).snapshots().map((
      snap,
    ) {
      final data = snap.data();
      if (data == null) return null;
      return SquadWeeklyProgress.fromMap(data);
    });
  }

  Stream<int> watchCurrentStreakForSquad({required String squadKey}) {
    return watchWeekProgressForSquad(
      squadKey: squadKey,
    ).map((data) => data?.currentStreak ?? 0);
  }

  Future<SquadWeeklyProgress?> ensureAndFetchCurrentWeek() async {
    final uid = _resolveUid();
    if (uid.isEmpty) return null;
    final squadKey = _resolveSquadKey(uid: uid);
    final squadName = _resolveSquadName();
    final now = DateTime.now();
    final today = _dateKey(now);
    final weekInfo = _weekInfo(now);
    final docRef = _docRef(squadKey: squadKey, weekId: weekInfo.weekId);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (snap.exists && snap.data() != null) return;
        final payload = _buildOrMergePayload(
          existing: null,
          squadKey: squadKey,
          squadName: squadName,
          uid: uid,
          weekId: weekInfo.weekId,
          weekStartIso: weekInfo.startIso,
          weekEndIso: weekInfo.endIso,
          action: null,
          increment: 0,
          today: today,
        );
        tx.set(docRef, payload, SetOptions(merge: true));
      });

      final fresh = await docRef.get();
      final data = fresh.data();
      return data == null ? null : SquadWeeklyProgress.fromMap(data);
    } catch (e, st) {
      AppLogger.e(
        'SquadMissions ensureAndFetch failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>> _docRef({
    required String squadKey,
    required String weekId,
  }) {
    return _firestore.collection(_collection).doc('${squadKey}_$weekId');
  }

  String _resolveUid() {
    final firebaseUid =
        firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (firebaseUid.isNotEmpty) return firebaseUid;
    final fallback = (_preferences.getString('uid') ?? '').trim();
    if (fallback.isNotEmpty) return fallback;
    final userId = (_preferences.getString('user_id') ?? '').trim();
    return userId;
  }

  String _resolveSquadKey({required String uid, String? input}) {
    final key = (input ?? _preferences.getString(_activeSquadKey) ?? '').trim();
    if (key.isNotEmpty) return key;
    final fromUser = (_preferences.getString('user_id') ?? '').trim();
    if (fromUser.isNotEmpty) return 'solo_$fromUser';
    return 'solo_$uid';
  }

  String _resolveSquadName({String? input}) {
    final name = (input ?? _preferences.getString(_activeSquadName) ?? '')
        .trim();
    if (name.isNotEmpty) return name;
    return 'Your Squad';
  }

  _WeekInfo _weekInfo(DateTime now) {
    final local = DateTime(now.year, now.month, now.day);
    final start = local.subtract(
      Duration(days: local.weekday - DateTime.monday),
    );
    final end = start.add(const Duration(days: 6));
    final weekId =
        '${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}';
    return _WeekInfo(
      weekId: weekId,
      startIso: start.toIso8601String(),
      endIso: end.toIso8601String(),
    );
  }

  String _dateKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _buildOrMergePayload({
    required Map<String, dynamic>? existing,
    required String squadKey,
    required String squadName,
    required String uid,
    required String weekId,
    required String weekStartIso,
    required String weekEndIso,
    required String? action,
    required int increment,
    required String today,
  }) {
    final payload = <String, dynamic>{
      'squad_key': squadKey,
      'squad_name': squadName,
      'week_id': weekId,
      'week_start': weekStartIso,
      'week_end': weekEndIso,
      'updated_at': FieldValue.serverTimestamp(),
      'participants': {uid: true},
    };

    final missions = <String, dynamic>{};
    for (final entry in _defaultMissionDefs.entries) {
      missions[entry.key] = {
        'title': entry.value['title'],
        'target': entry.value['target'],
        'reward': entry.value['reward'],
        'progress': 0,
        'claimed': false,
      };
    }

    if (existing != null && existing.isNotEmpty) {
      final existingMissions = Map<String, dynamic>.from(
        existing['missions'] as Map? ?? const {},
      );
      for (final key in missions.keys) {
        if (existingMissions[key] is Map) {
          missions[key] = {
            ...Map<String, dynamic>.from(missions[key] as Map),
            ...Map<String, dynamic>.from(existingMissions[key] as Map),
          };
        }
      }
      final existingParticipants = Map<String, dynamic>.from(
        existing['participants'] as Map? ?? const {},
      );
      existingParticipants[uid] = true;
      payload['participants'] = existingParticipants;
    }

    payload['missions'] = missions;

    var streakCurrent = (existing?['streak_current'] as num? ?? 0).toInt();
    var streakBest = (existing?['streak_best'] as num? ?? 0).toInt();
    final lastDay = (existing?['last_activity_day'] ?? '').toString();

    if (action != null && action.trim().isNotEmpty) {
      final missionKey = _mapActionToMissionKey(action.trim());
      if (missionKey != null && missions[missionKey] is Map) {
        final missionMap = Map<String, dynamic>.from(
          missions[missionKey] as Map,
        );
        final previous = (missionMap['progress'] as num? ?? 0).toInt();
        missionMap['progress'] = previous + increment;
        missions[missionKey] = missionMap;
      }

      final todayDate = DateTime.parse('${today}T00:00:00');
      final yesterday = todayDate.subtract(const Duration(days: 1));
      final yesterdayKey = _dateKey(yesterday);

      if (lastDay == today) {
        // same day action, do not change streak
      } else if (lastDay == yesterdayKey) {
        streakCurrent = streakCurrent + 1;
      } else {
        streakCurrent = 1;
      }
      if (streakCurrent > streakBest) {
        streakBest = streakCurrent;
      }
      payload['last_activity_day'] = today;
    } else if ((existing?['last_activity_day'] ?? '').toString().isNotEmpty) {
      payload['last_activity_day'] = existing!['last_activity_day'];
    } else {
      payload['last_activity_day'] = '';
    }

    payload['streak_current'] = streakCurrent;
    payload['streak_best'] = streakBest;

    return payload;
  }

  String? _mapActionToMissionKey(String action) {
    switch (action) {
      case SquadMissionAction.playSession:
        return 'play_sessions';
      case SquadMissionAction.watchLive:
        return 'watch_live_minutes';
      case SquadMissionAction.joinTournament:
        return 'join_tournament';
      case SquadMissionAction.referFriend:
        return 'refer_friends';
      default:
        return null;
    }
  }
}

class _WeekInfo {
  const _WeekInfo({
    required this.weekId,
    required this.startIso,
    required this.endIso,
  });

  final String weekId;
  final String startIso;
  final String endIso;
}
