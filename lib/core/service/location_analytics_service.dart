import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/location_permission_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as loc;

class LocationAnalyticsService {
  LocationAnalyticsService({
    required SharedPreferences preferences,
    required SegmentSdkService segmentService,
    required FbEventsService fbEventsService,
    required LocationPermissionService locationPermissionService,
  }) : _prefs = preferences,
       _segmentService = segmentService,
       _fbEventsService = fbEventsService,
       _locationPermissionService = locationPermissionService;

  final SharedPreferences _prefs;
  final SegmentSdkService _segmentService;
  final FbEventsService _fbEventsService;
  final LocationPermissionService _locationPermissionService;
  loc.Location get _location => _locationPermissionService.location;
  Future<void>? _activeTrackingRequest;

  static const _lastLatKey = 'analytics_last_lat';
  static const _lastLngKey = 'analytics_last_lng';
  static const _lastTsKey = 'analytics_last_ts_ms';
  static const _minIntervalMs = 10 * 60 * 1000; // 10 min
  static const _minDistanceMeters = 150.0;

  Future<void> trackCurrentLocation({
    String source = 'app',
    bool promptForService = false,
    bool promptForPermission = false,
  }) {
    final active = _activeTrackingRequest;
    if (active != null) return active;

    final request = _trackCurrentLocationInternal(
      source: source,
      promptForService: promptForService,
      promptForPermission: promptForPermission,
    );
    _activeTrackingRequest = request;
    return request.whenComplete(() {
      if (identical(_activeTrackingRequest, request)) {
        _activeTrackingRequest = null;
      }
    });
  }

  Future<void> _trackCurrentLocationInternal({
    required String source,
    required bool promptForService,
    required bool promptForPermission,
  }) async {
    try {
      final serviceEnabled = await _locationPermissionService
          .ensureServiceEnabled(requestIfNeeded: promptForService);
      if (!serviceEnabled) {
        await _sendStatusEvent(
          source: source,
          status: 'service_disabled',
          permissionGranted: false,
        );
        return;
      }

      final permission = await _locationPermissionService.ensurePermission(
        requestIfNeeded: promptForPermission,
      );

      final granted =
          permission == loc.PermissionStatus.granted ||
          permission == loc.PermissionStatus.grantedLimited;
      if (!granted) {
        await _sendStatusEvent(
          source: source,
          status: 'permission_denied',
          permissionGranted: false,
        );
        return;
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final ld = await _location.getLocation();
      final lat = ld.latitude;
      final lng = ld.longitude;
      if (lat == null || lng == null) {
        await _sendStatusEvent(
          source: source,
          status: 'location_unavailable',
          permissionGranted: true,
        );
        return;
      }

      final shouldTrack = _shouldTrack(nowMs, lat, lng);
      if (!shouldTrack) {
        return;
      }

      String city = '';
      String state = '';
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          city = (placemarks.first.locality ?? '').trim();
          state = (placemarks.first.administrativeArea ?? '').trim();
        }
      } catch (_) {
        // Reverse geocoding is optional; coordinates are still tracked.
      }

      final payload = <String, dynamic>{
        'source': source,
        'latitude': lat,
        'longitude': lng,
        'city': city,
        'state': state,
        'permission_granted': true,
      };

      await _segmentService.onCustomEvent('Location Updated', payload);
      await _fbEventsService.onCustomEvent('Location Updated', payload);

      await _prefs.setDouble(_lastLatKey, lat);
      await _prefs.setDouble(_lastLngKey, lng);
      await _prefs.setInt(_lastTsKey, nowMs);
    } catch (_) {
      await _sendStatusEvent(
        source: source,
        status: 'location_tracking_error',
        permissionGranted: false,
      );
    }
  }

  Future<void> _sendStatusEvent({
    required String source,
    required String status,
    required bool permissionGranted,
  }) async {
    final payload = <String, dynamic>{
      'source': source,
      'status': status,
      'permission_granted': permissionGranted,
    };
    await _segmentService.onCustomEvent('Location Tracking', payload);
    await _fbEventsService.onCustomEvent('Location Tracking', payload);
  }

  bool _shouldTrack(int nowMs, double currentLat, double currentLng) {
    final lastTs = _prefs.getInt(_lastTsKey) ?? 0;
    if (lastTs == 0 || nowMs - lastTs >= _minIntervalMs) {
      return true;
    }

    final lastLat = _prefs.getDouble(_lastLatKey);
    final lastLng = _prefs.getDouble(_lastLngKey);
    if (lastLat == null || lastLng == null) {
      return true;
    }

    final movedMeters = _distanceMeters(
      lastLat,
      lastLng,
      currentLat,
      currentLng,
    );
    return movedMeters >= _minDistanceMeters;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degToRad(double degree) => degree * (math.pi / 180.0);
}
