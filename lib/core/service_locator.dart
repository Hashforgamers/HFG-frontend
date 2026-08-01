import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/device_identifier_service.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service/external_cafe_likes_service.dart';
import 'package:hash/core/service/firebase_in_app_messaging_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/funnel_notification_service.dart';
import 'package:hash/core/service/location_analytics_service.dart';
import 'package:hash/core/service/location_permission_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/global_bottom_sheet_service.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locator = GetIt.instance;

/// Call once at app start. If you really need to rewire (tests/flavors),
/// call `setupServiceLocator(reset: true)`.
Future<void> setupServiceLocator({bool reset = false}) async {
  if (reset) {
    // Clears previous registrations (also disposes where possible)
    await locator.reset(dispose: true);
  }

  if (!locator.isRegistered<SharedPreferences>()) {
    final sp = await SharedPreferences.getInstance();
    locator.registerSingleton<SharedPreferences>(sp);
  }

  if (!locator.isRegistered<FlutterSecureStorage>()) {
    locator.registerSingleton<FlutterSecureStorage>(
      const FlutterSecureStorage(),
    );
  }

  if (!locator.isRegistered<AuthDataRepository>()) {
    locator.registerSingleton<AuthDataRepository>(
      AuthDataRepository(storage: locator<FlutterSecureStorage>()),
    );
  }

  if (!locator.isRegistered<NetworkProvider>()) {
    locator.registerSingleton<NetworkProvider>(NetworkProvider());
  }

  if (!locator.isRegistered<DeviceIdentifierService>()) {
    locator.registerSingleton<DeviceIdentifierService>(
      DeviceIdentifierService(preferences: locator<SharedPreferences>()),
    );
  }

  // Register RemoteRepoInterface ONCE. Prefer lazy to allow late creation.
  if (locator.isRegistered<RemoteRepoInterface>()) {
    locator.unregister<RemoteRepoInterface>();
  }
  locator.registerLazySingleton<RemoteRepoInterface>(
    () => RemoteRepo(
      networkProvider: locator<NetworkProvider>(),
      deviceIdentifierService: locator<DeviceIdentifierService>(),
    ),
  );

  if (!locator.isRegistered<SegmentSdkService>()) {
    locator.registerSingleton<SegmentSdkService>(
      SegmentSdkService(
        deviceIdentifierService: locator<DeviceIdentifierService>(),
      ),
    );
  }

  if (!locator.isRegistered<FbEventsService>()) {
    locator.registerSingleton<FbEventsService>(
      FbEventsService(
        deviceIdentifierService: locator<DeviceIdentifierService>(),
      ),
    );
  }

  if (!locator.isRegistered<AnalyticsService>()) {
    locator.registerSingleton<AnalyticsService>(AnalyticsService());
  }

  if (!locator.isRegistered<FunnelNotificationService>()) {
    locator.registerSingleton<FunnelNotificationService>(
      FunnelNotificationService(),
    );
  }

  if (!locator.isRegistered<FirebaseInAppMessagingService>()) {
    locator.registerSingleton<FirebaseInAppMessagingService>(
      FirebaseInAppMessagingService(),
    );
  }

  if (!locator.isRegistered<GlobalBottomSheetService>()) {
    locator.registerSingleton<GlobalBottomSheetService>(
      GlobalBottomSheetService(),
    );
  }

  if (!locator.isRegistered<SquadMissionsService>()) {
    locator.registerSingleton<SquadMissionsService>(
      SquadMissionsService(preferences: locator<SharedPreferences>()),
    );
  }

  if (!locator.isRegistered<LocationPermissionService>()) {
    locator.registerSingleton<LocationPermissionService>(
      LocationPermissionService(),
    );
  }

  if (!locator.isRegistered<LocationAnalyticsService>()) {
    locator.registerSingleton<LocationAnalyticsService>(
      LocationAnalyticsService(
        preferences: locator<SharedPreferences>(),
        segmentService: locator<SegmentSdkService>(),
        fbEventsService: locator<FbEventsService>(),
        locationPermissionService: locator<LocationPermissionService>(),
      ),
    );
  }

  if (!locator.isRegistered<ExternalCafeLikesService>()) {
    locator.registerSingleton<ExternalCafeLikesService>(
      ExternalCafeLikesService(
        preferences: locator<SharedPreferences>(),
        deviceIdentifierService: locator<DeviceIdentifierService>(),
      ),
    );
  }
}
