import 'package:get_it/get_it.dart';
import 'amplitude_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register AmplitudeService as a singleton
  serviceLocator.registerSingleton<AmplitudeService>(AmplitudeService());
  
  // Initialize AmplitudeService
  await serviceLocator<AmplitudeService>().initialize();
} 