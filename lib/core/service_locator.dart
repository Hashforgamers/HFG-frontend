import 'services/amplitude_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  late final AmplitudeService amplitude;

  // Private constructor
  ServiceLocator._internal() {
    amplitude = AmplitudeService();
  }

  // Factory constructor
  factory ServiceLocator() {
    return _instance;
  }

  // Initialize services
  Future<void> initialize() async {
    await amplitude.initialize();
  }
}

// Global instance
final serviceLocator = ServiceLocator(); 