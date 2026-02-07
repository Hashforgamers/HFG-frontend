import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  /// Returns true on success, false on failure (or no user).
  Future<bool> submitScore({required String gameId, required int score}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = _db.collection(_collection).doc(user.uid);

    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(doc);
        final data = snap.data() as Map<String, dynamic>? ?? {};
        final scores = Map<String, int>.from(data['scores'] ?? {});
        final current = scores[gameId] ?? 0;
        if (score <= current) return; // only store best

        scores[gameId] = score;
        final total = scores.values.fold<int>(0, (prev, val) => prev + val);

        txn.set(doc, {
          'userId': user.uid,
          'displayName': user.displayName ?? user.email ?? 'Player',
          'avatarUrl': user.photoURL,
          'scores': scores,
          'totalScore': total,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      return true;
    } catch (e, st) {
      debugPrint('⛔ leaderboard submit failed: $e\n$st');
      return false;
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
}
