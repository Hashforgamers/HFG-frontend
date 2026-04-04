import 'package:location/location.dart' as loc;

class LocationPermissionService {
  final loc.Location _location = loc.Location();
  Future<bool>? _activeServiceRequest;
  Future<loc.PermissionStatus>? _activePermissionRequest;

  loc.Location get location => _location;

  Future<bool> ensureServiceEnabled({bool requestIfNeeded = true}) {
    final active = _activeServiceRequest;
    if (active != null) return active;

    final request = _ensureServiceEnabledInternal(
      requestIfNeeded: requestIfNeeded,
    );
    _activeServiceRequest = request;
    return request.whenComplete(() {
      if (identical(_activeServiceRequest, request)) {
        _activeServiceRequest = null;
      }
    });
  }

  Future<loc.PermissionStatus> ensurePermission({bool requestIfNeeded = true}) {
    final active = _activePermissionRequest;
    if (active != null) return active;

    final request = _ensurePermissionInternal(requestIfNeeded: requestIfNeeded);
    _activePermissionRequest = request;
    return request.whenComplete(() {
      if (identical(_activePermissionRequest, request)) {
        _activePermissionRequest = null;
      }
    });
  }

  Future<bool> _ensureServiceEnabledInternal({
    required bool requestIfNeeded,
  }) async {
    var serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled && requestIfNeeded) {
      serviceEnabled = await _location.requestService();
    }
    return serviceEnabled;
  }

  Future<loc.PermissionStatus> _ensurePermissionInternal({
    required bool requestIfNeeded,
  }) async {
    var permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied && requestIfNeeded) {
      permission = await _location.requestPermission();
    }
    return permission;
  }
}
