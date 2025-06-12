import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hash/app/modules/shop/services/product_service.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/services/amplitude_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register FlutterSecureStorage
  locator.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // Register AuthDataRepository
  locator.registerSingleton<AuthDataRepository>(
    AuthDataRepository(storage: locator<FlutterSecureStorage>()),
  );

  // Register NetworkProvider after AuthDataRepository
  locator.registerSingleton<NetworkProvider>(NetworkProvider());

  // Register RemoteRepo last since it depends on NetworkProvider
  locator.registerSingleton<RemoteRepoInterface>(
    RemoteRepo(networkProvider: locator<NetworkProvider>()),
  );

  locator.registerSingleton<ProductService>(ProductService());

  locator.registerSingleton<AmplitudeService>(AmplitudeService());
}
