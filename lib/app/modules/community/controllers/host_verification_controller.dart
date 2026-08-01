import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'verification_checkout_controller.dart';
import '../models/host_verification.dart';
import '../services/community_api.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';

/// Backs the host verification form (POST /hosts/verification).
class HostVerificationController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final upiId = TextEditingController();
  final address = TextEditingController();
  final govIdRef = TextEditingController();

  final RxBool submitting = false.obs;
  final RxnString error = RxnString();
  String? _paymentReference;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map) {
      final value = arguments['payment_reference']?.toString().trim();
      if (value != null && value.isNotEmpty) _paymentReference = value;
    }
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? validate() {
    final requiredError =
        _required(name.text, 'Name') ??
        _required(email.text, 'Email') ??
        _required(phone.text, 'Phone') ??
        _required(upiId.text, 'UPI ID') ??
        _required(address.text, 'Address');
    if (requiredError != null) return requiredError;

    if (name.text.trim().length > 160) {
      return 'Name must be 160 characters or fewer.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      return 'Enter a valid email address.';
    }
    final phoneValue = phone.text.trim();
    if (phoneValue.length < 8 || phoneValue.length > 32) {
      return 'Phone number must be between 8 and 32 characters.';
    }
    if (!RegExp(
      r'^[A-Za-z0-9._-]{2,256}@[A-Za-z][A-Za-z0-9.-]{1,63}$',
    ).hasMatch(upiId.text.trim())) {
      return 'Enter a valid UPI ID, such as name@bank.';
    }
    if (address.text.trim().length < 10) {
      return 'Address must be at least 10 characters.';
    }
    return null;
  }

  Future<void> submit() async {
    final v = validate();
    if (v != null) {
      error.value = v;
      return;
    }
    submitting.value = true;
    error.value = null;
    try {
      _paymentReference ??= await _loadPendingPaymentReference();
      if (_paymentReference == null) {
        error.value =
            'Payment confirmation is missing. Please return to checkout.';
        return;
      }
      final record = await _api.submitHostVerification(
        name: name.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        upiId: upiId.text.trim(),
        address: address.text.trim(),
        governmentId: govIdRef.text.trim().isEmpty
            ? null
            : govIdRef.text.trim(),
        paymentReference: _paymentReference,
      );
      await locator<AnalyticsService>().log(
        'host_verification_submitted',
        parameters: {
          'source_screen': 'host_verification',
          'host_verified': record.status == HostVerificationStatus.verified,
        },
      );
      await locator<AnalyticsService>().setUserProperties(
        userRole: record.status == HostVerificationStatus.verified
            ? 'host'
            : 'host_candidate',
      );
      await _clearPendingPaymentReference();
      Get.back(result: record.status);
      Get.snackbar(
        'Application submitted',
        record.status == HostVerificationStatus.verified
            ? 'You are verified!'
            : 'Your verification is now under review.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final localAuthFailure =
          code == null &&
          (e.error?.toString().contains('No access token') == true ||
              e.message?.contains('No access token') == true);
      if (code == 401 || localAuthFailure) {
        error.value = data is Map
            ? (data['message'] ?? 'Session expired').toString()
            : 'Session expired. Please login again.';
      } else if (code == 403) {
        error.value = 'You are not authorized.';
      } else if (data is Map &&
          (data['message'] != null || data['error'] != null)) {
        error.value = (data['message'] ?? data['error']).toString();
      } else {
        error.value = 'Could not submit. Please try again.';
      }
    } catch (_) {
      error.value = 'Could not submit. Please check your details and retry.';
    } finally {
      submitting.value = false;
    }
  }

  Future<String?> _loadPendingPaymentReference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs
        .getString(VerificationCheckoutController.pendingPaymentPreferenceKey)
        ?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _clearPendingPaymentReference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      VerificationCheckoutController.pendingPaymentPreferenceKey,
    );
  }

  @override
  void onClose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    upiId.dispose();
    address.dispose();
    govIdRef.dispose();
    super.onClose();
  }
}
