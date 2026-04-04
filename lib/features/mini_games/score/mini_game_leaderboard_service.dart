import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/html_games/services/html_mini_game_catalog_service.dart';

class ScoreSubmissionResult {
  final bool synced;
  final bool storedNewBest;
  final bool isNewGlobalLeader;
  final int previousBest;
  final int newBest;
  final int newTotalScore;
  final int previousTopScore;
  final String previousLeaderName;
  final int? currentRank;

  const ScoreSubmissionResult({
    required this.synced,
    required this.storedNewBest,
    required this.isNewGlobalLeader,
    required this.previousBest,
    required this.newBest,
    required this.newTotalScore,
    required this.previousTopScore,
    required this.previousLeaderName,
    required this.currentRank,
  });
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalScore;
  final Map<String, int> scores;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalScore,
    required this.scores,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final scores = Map<String, int>.from(data['scores'] ?? {});
    return LeaderboardEntry(
      userId: data['userId'] ?? doc.id,
      displayName: data['displayName'] ?? 'Player',
      avatarUrl: data['avatarUrl'],
      totalScore: data['totalScore'] ?? 0,
      scores: scores,
    );
  }
}

class MiniGameLeaderboardService {
  final _db = FirebaseFirestore.instance;
  static const _collection = 'mini_game_leaderboard';
  static const _chatRoomsCollection = 'chat_rooms';
  static const _chatUsersCollection = 'chat_users';
  static const overallGameId = 'overall';
  static const supportedGameIds = <String>[
    'fruit_cutting',
    'plant_vs_zombie',
    'pac_man',
    'laggy_bird',
    ...HtmlMiniGameCatalogService.supportedGameIds,
  ];

  Future<ScoreSubmissionResult> submitScore({
    required String gameId,
    required int score,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const ScoreSubmissionResult(
        synced: false,
        storedNewBest: false,
        isNewGlobalLeader: false,
        previousBest: 0,
        newBest: 0,
        newTotalScore: 0,
        previousTopScore: 0,
        previousLeaderName: '',
        currentRank: null,
      );
    }

    final doc = _db.collection(_collection).doc(user.uid);
    final topSnap = await _db
        .collection(_collection)
        .orderBy('totalScore', descending: true)
        .limit(1)
        .get();
    final topData = topSnap.docs.isEmpty ? null : topSnap.docs.first.data();
    final previousTopScore = _readInt(topData?['totalScore']);
    final previousLeaderName = (topData?['displayName'] ?? 'Top Player')
        .toString();

    var storedNewBest = false;
    var previousBest = 0;
    var newBest = 0;
    var newTotalScore = 0;

    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(doc);
        final data = snap.data() ?? <String, dynamic>{};
        final scores = Map<String, int>.from(data['scores'] ?? {});
        final current = scores[gameId] ?? 0;
        previousBest = current;
        newBest = current;
        newTotalScore = _readInt(data['totalScore']);
        if (score <= current) return;

        storedNewBest = true;
        scores[gameId] = score;
        final total = scores.values.fold<int>(0, (prev, val) => prev + val);
        newBest = score;
        newTotalScore = total;

        txn.set(doc, {
          'userId': user.uid,
          'displayName': user.displayName ?? user.email ?? 'Player',
          'avatarUrl': user.photoURL,
          'scores': scores,
          'totalScore': total,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      final isNewGlobalLeader =
          storedNewBest && newTotalScore > previousTopScore;
      int? currentRank;
      if (storedNewBest) {
        final rankedEntries = await _db
            .collection(_collection)
            .orderBy('totalScore', descending: true)
            .get();
        final rankedIndex = rankedEntries.docs.indexWhere(
          (entry) => entry.id == user.uid,
        );
        currentRank = rankedIndex >= 0 ? rankedIndex + 1 : null;
      }
      return ScoreSubmissionResult(
        synced: true,
        storedNewBest: storedNewBest,
        isNewGlobalLeader: isNewGlobalLeader,
        previousBest: previousBest,
        newBest: newBest,
        newTotalScore: newTotalScore,
        previousTopScore: previousTopScore,
        previousLeaderName: previousLeaderName,
        currentRank: currentRank,
      );
    } catch (e, st) {
      debugPrint('⛔ leaderboard submit failed: $e\n$st');
      return ScoreSubmissionResult(
        synced: false,
        storedNewBest: false,
        isNewGlobalLeader: false,
        previousBest: previousBest,
        newBest: newBest,
        newTotalScore: newTotalScore,
        previousTopScore: previousTopScore,
        previousLeaderName: previousLeaderName,
        currentRank: null,
      );
    }
  }

  Stream<List<LeaderboardEntry>> leaderboardStream({int limit = 50}) {
    return _db
        .collection(_collection)
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => LeaderboardEntry.fromDoc(d)).toList(),
        );
  }

  List<LeaderboardEntry> rankEntriesForGame(
    List<LeaderboardEntry> entries, {
    required String gameId,
  }) {
    if (gameId == overallGameId) {
      return List<LeaderboardEntry>.from(entries)
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    }

    final filtered = entries
        .where((entry) => (entry.scores[gameId] ?? 0) > 0)
        .toList();
    filtered.sort((a, b) {
      final scoreDiff = (b.scores[gameId] ?? 0).compareTo(
        a.scores[gameId] ?? 0,
      );
      if (scoreDiff != 0) return scoreDiff;
      return b.totalScore.compareTo(a.totalScore);
    });
    return filtered;
  }

  Future<String> ensureLeaderboardChatRoom({String? gameId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please sign in to join leaderboard chat.');
    }

    final safeGameId = (gameId ?? '').trim();
    final roomId = safeGameId.isEmpty
        ? 'mini_games_lounge'
        : 'mini_games_$safeGameId';
    final roomName = safeGameId.isEmpty
        ? 'Mini Games Lounge'
        : '${readableGameName(safeGameId)} Arena';
    final displayName = user.displayName ?? user.email ?? 'Player';

    await _db.collection(_chatUsersCollection).doc(user.uid).set({
      'uid': user.uid,
      'display_name': displayName,
      'username': '',
      'email': user.email ?? '',
      'photo_url': user.photoURL ?? '',
      'is_online': true,
      'last_seen_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final roomRef = _db.collection(_chatRoomsCollection).doc(roomId);
    final snapshot = await roomRef.get();
    final payload = {
      'id': roomId,
      'type': 'group',
      'name': roomName,
      'image_url': '',
      'members': FieldValue.arrayUnion([user.uid]),
      'admins': FieldValue.arrayUnion([user.uid]),
      'member_names': {user.uid: displayName},
      'muted_uids': const <String>[],
      'archived_uids': const <String>[],
      'deleted_for_uids': FieldValue.arrayRemove([user.uid]),
      'updated_at': FieldValue.serverTimestamp(),
      'client_updated_at': DateTime.now().toIso8601String(),
    };

    if (!snapshot.exists) {
      await roomRef.set({
        ...payload,
        'created_by': user.uid,
        'created_at': FieldValue.serverTimestamp(),
        'client_created_at': DateTime.now().toIso8601String(),
        'last_message': '',
        'last_message_sender_id': '',
        'last_message_at': null,
      }, SetOptions(merge: true));
    } else {
      await roomRef.set(payload, SetOptions(merge: true));
    }

    return roomId;
  }

  static String readableGameName(String key) {
    final value = key.replaceAll('_', ' ').trim();
    if (value.isEmpty) return 'Arcade';
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  static int hashCoinRewardForRank(int rank) {
    if (rank == 1) return 100;
    if (rank == 2) return 75;
    if (rank == 3) return 50;
    if (rank >= 4 && rank <= 100) return 1;
    return 0;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
