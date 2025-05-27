import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/amplitude_service.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  
  const OtpScreen({Key? key, required this.mobile}) : super(key: key);
  
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _amplitudeService = serviceLocator<AmplitudeService>();
  
  Future<void> _requestOtp() async {
    try {
      // Your existing OTP request logic here
      
      // Track OTP requested
      await _amplitudeService.trackOtpRequested(
        mobile: widget.mobile,
        method: 'sms', // or 'whatsapp' based on your implementation
      );
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _verifyOtp(String otp) async {
    try {
      // Your existing OTP verification logic here
      
      // Track OTP verified
      await _amplitudeService.trackOtpVerified(
        mobile: widget.mobile,
        verificationStatus: 'success', // or 'failed' based on result
      );
    } catch (e) {
      // Handle error
    }
  }
  
  // ... rest of your OTP screen code ...
} 