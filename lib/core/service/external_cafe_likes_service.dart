import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/service/device_identifier_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExternalCafeLikesService {
  ExternalCafeLikesService({
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
    DeviceIdentifierService? deviceIdentifierService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _preferences = preferences ?? locator<SharedPreferences>(),
       _deviceIdentifierService =
           deviceIdentifierService ?? locator<DeviceIdentifierService>();

  static const String _collection = 'cafes_external';
  static const String _fallbackDeviceIdKey =
      'cafes_external_fallback_device_id';

  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;
  final DeviceIdentifierService _deviceIdentifierService;

  CollectionReference<Map<String, dynamic>> get _cafesRef =>
      _firestore.collection(_collection);

  String cafeDocIdFromPlace(Map<String, dynamic> place) {
    final placeId = (place['place_id'] ?? '').toString().trim();
    if (placeId.isNotEmpty) return placeId;

    final name = (place['name'] ?? '').toString().trim().toLowerCase();
    final geometry = place['geometry'];
    final location = geometry is Map ? geometry['location'] : null;
    final lat = location is Map ? (location['lat'] ?? '').toString() : '';
    final lng = location is Map ? (location['lng'] ?? '').toString() : '';
    final base = '${name.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${lat}_$lng';
    return base.isEmpty ? 'external_unknown' : base;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCafe(String cafeId) {
    return _cafesRef.doc(cafeId).snapshots();
  }

  Stream<bool> watchIsLiked(String cafeId) async* {
    final identity = await _resolveIdentity();
    final userKey = identity.userKey;
    if (userKey.isEmpty) {
      yield false;
      return;
    }

    yield* _cafesRef
        .doc(cafeId)
        .collection('likes')
        .doc(userKey)
        .snapshots()
        .map((snap) => snap.exists);
  }

  Future<bool> likeCafe({
    required String cafeId,
    required Map<String, dynamic> place,
  }) async {
    final identity = await _resolveIdentity();
    if (identity.userKey.isEmpty) return false;

    final cafeRef = _cafesRef.doc(cafeId);
    final likeRef = cafeRef.collection('likes').doc(identity.userKey);
    final nowIso = DateTime.now().toIso8601String();

    return _firestore.runTransaction((tx) async {
      final existingLike = await tx.get(likeRef);
      if (existingLike.exists) return false;

      tx.set(cafeRef, {
        'place_id': (place['place_id'] ?? '').toString(),
        'name': (place['name'] ?? '').toString(),
        'vicinity': (place['vicinity'] ?? '').toString(),
        'rating': place['rating'],
        'total_likes': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'last_liked_at': nowIso,
      }, SetOptions(merge: true));

      tx.set(likeRef, {
        'user_id': identity.userId,
        'firebase_uid': identity.firebaseUid,
        'device_id': identity.deviceId,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    });
  }

  Future<_CafeLikeIdentity> _resolveIdentity() async {
    final prefsUserId = (_preferences.getString('user_id') ?? '').trim();
    String userId = prefsUserId;

    if (userId.isEmpty) {
      final rawUserData = _preferences.getString('user_data');
      if ((rawUserData ?? '').isNotEmpty) {
        try {
          final source = jsonDecode(rawUserData!) as Map<String, dynamic>;
          userId = (source['id'] ?? source['user_id'] ?? '').toString().trim();
        } catch (_) {
          // ignore malformed cached user data
        }
      }
    }

    final firebaseUid =
        (firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '').trim();

    final identifiers = await _deviceIdentifierService.getIdentifiers();
    var deviceId = (identifiers['advertising_id'] ?? '').toString().trim();
    if (deviceId.isEmpty) {
      deviceId = (_preferences.getString(_fallbackDeviceIdKey) ?? '').trim();
      if (deviceId.isEmpty) {
        deviceId = _generateFallbackDeviceId();
        await _preferences.setString(_fallbackDeviceIdKey, deviceId);
      }
    }

    final userKey = userId.isNotEmpty
        ? 'user_$userId'
        : firebaseUid.isNotEmpty
        ? 'fid_$firebaseUid'
        : deviceId.isNotEmpty
        ? 'device_$deviceId'
        : '';

    return _CafeLikeIdentity(
      userId: userId,
      firebaseUid: firebaseUid,
      deviceId: deviceId,
      userKey: userKey,
    );
  }

  String _generateFallbackDeviceId() {
    final random = Random.secure();
    final millis = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final nonce = List.generate(
      12,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'local_${millis}_$nonce';
  }
}

class _CafeLikeIdentity {
  const _CafeLikeIdentity({
    required this.userId,
    required this.firebaseUid,
    required this.deviceId,
    required this.userKey,
  });

  final String userId;
  final String firebaseUid;
  final String deviceId;
  final String userKey;
}
