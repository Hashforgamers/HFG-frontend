import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

class NearbyPlayerLocationService {
  NearbyPlayerLocationService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
    SharedPreferences? preferences,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _preferences = preferences;

  static const String _collection = 'nearby_player_locations';
  static const String _visibilityPreference = 'nearby_location_sharing_enabled';
  static const double _cellSizeDegrees = 0.05;
  static const Duration _locationTtl = Duration(minutes: 15);

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<bool> isSharingEnabled() async {
    final preferences = await _prefs;
    return preferences.getBool(_visibilityPreference) ?? false;
  }

  Future<void> setSharingEnabled(bool enabled) async {
    final preferences = await _prefs;
    await preferences.setBool(_visibilityPreference, enabled);
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    if (!enabled) {
      await _firestore.collection(_collection).doc(uid).set({
        'visible': false,
        'location': FieldValue.delete(),
        'geo_cell': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> publishLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (!await isSharingEnabled()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final profile = await _firestore
        .collection('chat_users')
        .doc(user.uid)
        .get();
    final profileData = profile.data() ?? const <String, dynamic>{};
    final coarseLatitude = _coarseCoordinate(latitude);
    final coarseLongitude = _coarseCoordinate(longitude);

    await _firestore.collection(_collection).doc(user.uid).set({
      'uid': user.uid,
      'firebase_uid': user.uid,
      'user_id': profileData['backend_user_id'],
      'display_name':
          profileData['display_name'] ?? user.displayName ?? 'Player',
      'username': profileData['username'] ?? user.displayName ?? 'Player',
      'photo_url': profileData['photo_url'] ?? user.photoURL ?? '',
      'games': profileData['games'] ?? const <dynamic>[],
      'is_online': profileData['is_online'] ?? true,
      'visible': true,
      'location': GeoPoint(coarseLatitude, coarseLongitude),
      'geo_cell': _cellFor(coarseLatitude, coarseLongitude),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> fetchNearbyPlayers({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return const [];

    final cells = _neighborCells(latitude, longitude);
    final snapshot = await _firestore
        .collection(_collection)
        .where('geo_cell', whereIn: cells)
        .limit(200)
        .get();
    final staleBefore = DateTime.now().subtract(_locationTtl);
    final players = <Map<String, dynamic>>[];

    for (final document in snapshot.docs) {
      if (document.id == currentUid) continue;
      final data = document.data();
      if (data['visible'] != true || data['location'] is! GeoPoint) continue;
      final updatedAt = data['updated_at'];
      if (updatedAt is! Timestamp || updatedAt.toDate().isBefore(staleBefore)) {
        continue;
      }

      final point = data['location'] as GeoPoint;
      final distanceKm = _distanceKm(
        latitude,
        longitude,
        point.latitude,
        point.longitude,
      );
      if (distanceKm > radiusKm) continue;
      players.add({
        ...data,
        'firebase_uid': data['firebase_uid'] ?? document.id,
        'distance_km': double.parse(distanceKm.toStringAsFixed(1)),
        'approximate_location': {
          'latitude': point.latitude,
          'longitude': point.longitude,
        },
      });
    }

    players.sort(
      (a, b) =>
          (a['distance_km'] as double).compareTo(b['distance_km'] as double),
    );
    return players;
  }

  double _coarseCoordinate(double coordinate) =>
      (coordinate * 1000).roundToDouble() / 1000;

  String _cellFor(double latitude, double longitude) =>
      '${(latitude / _cellSizeDegrees).floor()}:${(longitude / _cellSizeDegrees).floor()}';

  List<String> _neighborCells(double latitude, double longitude) {
    final latitudeCell = (latitude / _cellSizeDegrees).floor();
    final longitudeCell = (longitude / _cellSizeDegrees).floor();
    return [
      for (var latitudeOffset = -2; latitudeOffset <= 2; latitudeOffset++)
        for (var longitudeOffset = -2; longitudeOffset <= 2; longitudeOffset++)
          '${latitudeCell + latitudeOffset}:${longitudeCell + longitudeOffset}',
    ];
  }

  double _distanceKm(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const earthRadiusKm = 6371.0;
    final latitudeDelta = _radians(latitudeB - latitudeA);
    final longitudeDelta = _radians(longitudeB - longitudeA);
    final value =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_radians(latitudeA)) *
            math.cos(_radians(latitudeB)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(value), math.sqrt(1 - value));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
