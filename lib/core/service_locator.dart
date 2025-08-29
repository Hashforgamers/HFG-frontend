import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/global_bottom_sheet_service.dart';
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
    locator.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  }

  if (!locator.isRegistered<AuthDataRepository>()) {
    locator.registerSingleton<AuthDataRepository>(
      AuthDataRepository(storage: locator<FlutterSecureStorage>()),
    );
  }

  if (!locator.isRegistered<NetworkProvider>()) {
    locator.registerSingleton<NetworkProvider>(NetworkProvider());
  }

  // Register RemoteRepoInterface ONCE. Prefer lazy to allow late creation.
  if (locator.isRegistered<RemoteRepoInterface>()) {
    locator.unregister<RemoteRepoInterface>();
  }
  locator.registerLazySingleton<RemoteRepoInterface>(
        () => RemoteRepo(networkProvider: locator<NetworkProvider>()),
  );

  if (!locator.isRegistered<SegmentSdkService>()) {
    locator.registerSingleton<SegmentSdkService>(SegmentSdkService());
  }

  if (!locator.isRegistered<FbEventsService>()) {
    locator.registerSingleton<FbEventsService>(FbEventsService());
  }

  if (!locator.isRegistered<GlobalBottomSheetService>()) {
    locator.registerSingleton<GlobalBottomSheetService>(GlobalBottomSheetService());
  }
}
