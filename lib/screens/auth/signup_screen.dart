import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/amplitude_service.dart';

class SignupScreen extends StatefulWidget {
  final String? referralCode;
  
  const SignupScreen({Key? key, this.referralCode}) : super(key: key);
  
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _amplitudeService = serviceLocator<AmplitudeService>();
  
  @override
  void initState() {
    super.initState();
    _trackSignupStarted();
  }
  
  Future<void> _trackSignupStarted() async {
    await _amplitudeService.trackSignupStarted(
      referralCode: widget.referralCode,
    );
  }
  
  Future<void> _completeSignup({
    required String userId,
    required String source,
    String? referredBy,
  }) async {
    try {
      // Your existing signup logic here
      
      // Track signup completed
      await _amplitudeService.trackSignedUp(
        userId: userId,
        source: source,
        referredBy: referredBy,
      );
    } catch (e) {
      // Handle error
    }
  }
  
  // ... rest of your signup screen code ...
} 