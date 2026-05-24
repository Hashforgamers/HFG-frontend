import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hash/app/modules/arena/models/nearby_teammate.dart';

class NearbyTeammatesFirebaseService {
  NearbyTeammatesFirebaseService({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = firebaseAuth ?? auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('chat_users');

  Future<void> upsertCurrentUserLocation({
    required LatLng userLocation,
    required bool shareLocation,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) return;

    final payload = <String, dynamic>{
      'location_visibility': shareLocation,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (shareLocation) {
      payload['location'] = <String, dynamic>{
        'latitude': userLocation.latitude,
        'longitude': userLocation.longitude,
        'updated_at': FieldValue.serverTimestamp(),
      };
    } else {
      payload['location'] = <String, dynamic>{
        'latitude': null,
        'longitude': null,
        'updated_at': FieldValue.serverTimestamp(),
      };
    }

    // TODO: Move this write to a dedicated backend endpoint when available.
    await _usersRef.doc(uid).set(payload, SetOptions(merge: true));
  }

  Future<List<NearbyTeammate>> fetchNearbyTeammates({
    required LatLng userLocation,
    required double radiusKm,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    // TODO: Replace this broad fetch with geo-indexed Firestore query if scale grows.
    final snapshot = await _usersRef.limit(300).get();
    final teammates = <NearbyTeammate>[];

    for (final doc in snapshot.docs) {
      if (doc.id == uid) continue;
      final data = doc.data();
      final locationVisibility = _toBool(data['location_visibility']) ?? true;
      if (!locationVisibility) continue;

      final location = _asMap(data['location']);
      final latitude = _toDouble(location?['latitude']);
      final longitude = _toDouble(location?['longitude']);
      if (latitude == null || longitude == null) continue;

      final distance = _distanceInKm(
        userLocation.latitude,
        userLocation.longitude,
        latitude,
        longitude,
      );
      if (distance > radiusKm) continue;

      teammates.add(
        NearbyTeammate(
          id: doc.id,
          username: _firstNonEmpty([
            data['username'],
            data['display_name'],
            data['name'],
            'Player',
          ]),
          avatar: _firstNonEmpty([
            data['photo_url'],
            data['avatar'],
            data['photoUrl'],
            'https://api.dicebear.com/9.x/bottts/png?seed=${doc.id}',
          ]),
          latitude: latitude,
          longitude: longitude,
          games: _stringList(data['games'], fallback: const ['BGMI']),
          rank: _firstNonEmpty([data['rank'], data['tier'], 'Unranked']),
          languages: _stringList(
            data['languages'],
            fallback: const ['English'],
          ),
          micEnabled: _toBool(data['mic_enabled']) ?? true,
          compatibilityScore: _compatibilityFromData(data, distance),
          playStyle: _firstNonEmpty([
            data['play_style'],
            data['playStyle'],
            'Casual',
          ]),
          online: _toBool(data['is_online']) ?? false,
        ),
      );
    }

    teammates.sort(
      (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
    );
    return teammates;
  }

  double _compatibilityFromData(Map<String, dynamic> data, double distanceKm) {
    final stored = _toDouble(data['compatibility_score']);
    if (stored != null) return stored.clamp(0, 100).toDouble();
    final onlineBoost = (_toBool(data['is_online']) ?? false) ? 12 : 0;
    final micBoost = (_toBool(data['mic_enabled']) ?? true) ? 7 : 0;
    final distancePenalty = min(distanceKm * 4.5, 32);
    return (86 + onlineBoost + micBoost - distancePenalty)
        .clamp(40, 99)
        .toDouble();
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  List<String> _stringList(dynamic value, {required List<String> fallback}) {
    if (value is List) {
      final parsed = value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return List<String>.from(fallback);
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return 'Player';
  }

  double _distanceInKm(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(toLat - fromLat);
    final dLng = _toRadians(toLng - fromLng);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(fromLat)) *
            cos(_toRadians(toLat)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * (pi / 180);
}
