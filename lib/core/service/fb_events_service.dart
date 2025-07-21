import 'package:facebook_app_events/facebook_app_events.dart';

class FbEventsService {
  static final fbAppEvents = FacebookAppEvents();

  Future<void> logEvent(
      String eventName, Map<String, dynamic> parameters) async {
    await fbAppEvents.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }
}
