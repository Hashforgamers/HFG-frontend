import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/service/device_identifier_service.dart';
import 'package:intl/intl.dart';
import 'package:segment_analytics/client.dart';
import 'package:segment_analytics/event.dart';
import 'package:segment_analytics/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SegmentSdkService {
  SegmentSdkService({required DeviceIdentifierService deviceIdentifierService})
    : _deviceIdentifierService = deviceIdentifierService;

  static const writeKey = 'boSN3P9nWQGYQHyM7dK26w2Ef8p621uY';
  static final analytics = createClient(Configuration(writeKey, debug: true));
  final DeviceIdentifierService _deviceIdentifierService;
  String _lastIdentityFingerprint = '';

  Future<Map<String, dynamic>> _identityPayload() async {
    String userId = '';
    String email = '';
    String fid = '';
    String phoneNumber = '';
    String username = '';

    try {
      if (Get.isRegistered<UserController>()) {
        final uc = Get.find<UserController>();
        userId = uc.id.value.trim();
        email = (uc.user.value.contact?.electronicAddress?.emailId ?? '')
            .toString()
            .trim();
        phoneNumber = (uc.user.value.contact?.electronicAddress?.mobileNo ?? '')
            .toString()
            .trim();
        username = (uc.user.value.gameUserName ?? '').toString().trim();
      }
    } catch (_) {}

    final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
    fid = (authUser?.uid ?? '').trim();
    email = email.isNotEmpty ? email : (authUser?.email ?? '').trim();
    phoneNumber = phoneNumber.isNotEmpty
        ? phoneNumber
        : (authUser?.phoneNumber ?? '').trim();
    username = username.isNotEmpty
        ? username
        : (authUser?.displayName ?? '').trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = (prefs.getString('user_id') ?? '').trim();
      if (storedUserId.isNotEmpty) userId = storedUserId;

      final raw = prefs.getString('user_data');
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw);
        if (map is Map) {
          userId = userId.isNotEmpty
              ? userId
              : (map['id'] ?? map['user_id'] ?? '').toString().trim();
          fid = fid.isNotEmpty ? fid : (map['fid'] ?? '').toString().trim();
          email = email.isNotEmpty
              ? email
              : (map['email'] ?? map['emailId'] ?? '').toString().trim();
          phoneNumber = phoneNumber.isNotEmpty
              ? phoneNumber
              : (map['phoneNumber'] ??
                        map['mobileNo'] ??
                        map['mobile_number'] ??
                        '')
                    .toString()
                    .trim();
          username = username.isNotEmpty
              ? username
              : (map['gameUserName'] ?? map['username'] ?? '')
                    .toString()
                    .trim();
        }
      }
    } catch (_) {}

    final identifiers = await _deviceIdentifierService.getIdentifiers();

    return {
      'user_id': userId,
      'email': email,
      'fid': fid,
      'phone_number': phoneNumber,
      'username': username,
      'advertising_id': identifiers['advertising_id'],
      'gaid': identifiers['gaid'],
      'idfa': identifiers['idfa'],
      'ad_tracking_status': identifiers['ad_tracking_status'],
      'limit_ad_tracking': identifiers['limit_ad_tracking'],
    };
  }

  Future<void> _track(String name, {Map<String, dynamic>? properties}) async {
    final payload = <String, dynamic>{...(properties ?? <String, dynamic>{})};
    final identity = await _identityPayload();
    payload.addAll(identity);
    await _identifyIfNeeded(identity);
    await analytics.track(name, properties: payload);
  }

  Future<void> _identifyIfNeeded(Map<String, dynamic> identity) async {
    final userId = (identity['user_id'] ?? '').toString().trim();
    final email = (identity['email'] ?? '').toString().trim();
    final fid = (identity['fid'] ?? '').toString().trim();
    final phone = (identity['phone_number'] ?? '').toString().trim();
    final username = (identity['username'] ?? '').toString().trim();

    final fingerprint = '$userId|$email|$fid|$phone|$username';
    if (fingerprint == _lastIdentityFingerprint) return;

    final traits = UserTraits(
      id: userId.isEmpty ? null : userId,
      email: email.isEmpty ? null : email,
      phone: phone.isEmpty ? null : phone,
      username: username.isEmpty ? null : username,
      name: username.isEmpty ? null : username,
      custom: {'fid': fid, 'phone_number': phone, 'user_id': userId},
    );

    await analytics.identify(
      userId: userId.isEmpty ? null : userId,
      userTraits: traits,
    );
    _lastIdentityFingerprint = fingerprint;
  }

  // Generic custom event helper
  Future<void> onCustomEvent(
    String name,
    Map<String, dynamic> properties,
  ) async {
    await _track(name, properties: properties);
  }

  // Event 1 - On App Launch
  Future<void> onAppLaunch() async {
    await _track(
      'App Launched',
      properties: {
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'app_version': '1.0.0',
      },
    );
  }

  // Event 2 - OTP Requested
  Future<void> onOtpRequested({required String mobile}) async {
    await _track(
      'OTP Requested',
      properties: {'mobile': mobile, 'method': 'sms'},
    );
  }

  // Event 3 - OTP Verified
  Future<void> onOtpVerified({required String mobile}) async {
    await _track(
      'OTP Verified',
      properties: {'mobile': mobile, 'verification_status': 'success'},
    );
  }

  // Event 4 - Signup Started
  Future<void> onSignupStarted({
    required String referralCode,
    required String email,
  }) async {
    await _track(
      'Signup Started',
      properties: {'referral_code': referralCode, 'email': email},
    );
  }

  // Event 5 - Signup Completed
  Future<void> onSignupCompleted({
    required String referralBy,
    required String userId,
    required String email,
  }) async {
    await _track(
      'Signup Completed',
      properties: {
        'user_id': userId,
        'referred_by': referralBy,
        'source': '',
        'email': email,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      },
    );
  }

  // Event 6 - Login Success
  Future<void> onLoginSuccess({
    required String userId,
    required String loginMethod,
    required String deviceId,
  }) async {
    await _track(
      'Login Successful',
      properties: {
        'user_id': userId,
        'device_id': deviceId,
        'login_method': loginMethod,
      },
    );
  }

  // Permissions Granted
  Future<void> onPermissionsGranted({
    required bool location,
    required bool notification,
    required bool contacts,
  }) async {
    await _track(
      'Permissions Granted',
      properties: {
        'location': location,
        'notification': notification,
        'contacts': contacts,
      },
    );
  }

  // Profile Updated
  Future<void> onProfileUpdated({required List<String> updatedFields}) async {
    await _track(
      'Profile Updated',
      properties: {'updated_fields': updatedFields},
    );
  }

  // Ticket Viewed
  Future<void> onTicketViewed({required String email}) async {
    await _track(
      'Ticket Viewed',
      properties: {
        'email': email,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Shop Viewed
  Future<void> onShowViewed({required String email}) async {
    await _track(
      'Show Viewed',
      properties: {
        'email': email,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Product Viewed
  Future<void> onProductViewed({
    required String email,
    required String name,
  }) async {
    await _track(
      'Product Viewed',
      properties: {
        'email': email,
        'product_name': name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Product Pre-Registered
  Future<void> onProductPreRegistered({
    required String email,
    required String productName,
  }) async {
    await _track(
      'Product Pre-Registered',
      properties: {
        'email': email,
        'product_name': productName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Help Requested
  Future<void> onHelpRequested({required String email}) async {
    await _track(
      'Help Requested',
      properties: {
        'email': email,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Account Deleted Requested
  Future<void> onAccountDeletedRequested({required String email}) async {
    await _track(
      'Account Deleted Requested',
      properties: {
        'email': email,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Hash Pass Checked
  Future<void> onHashPassChecked({required String email}) async {
    await _track(
      'Hash Pass Checked',
      properties: {
        'email': email,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      },
    );
  }

  // Hash Pass Initiated
  Future<void> onHashPassInitiated({
    required String email,
    required double amount,
  }) async {
    await _track(
      'Hash Pass Initiated',
      properties: {
        'email': email,
        'amount': amount,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      },
    );
  }

  // Hash Pass Purchased
  Future<void> onHashPassPurchased({
    required String email,
    // required double amount,
  }) async {
    await _track(
      'Hash Pass Purchased',
      properties: {
        'email': email,
        // 'amount': amount,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      },
    );
  }

  // Game Preferences Set
  Future<void> onGamePreferencesSet({
    required List<String> selectedGames,
  }) async {
    await _track(
      'Console Selected',
      properties: {'selected_consoles': selectedGames},
    );
  }

  // Referral Sent
  Future<void> onReferralSent({
    required String referralCode,
    required String channel,
  }) async {
    await _track(
      'Referral Sent',
      properties: {'referral_code': referralCode, 'channel': channel},
    );
  }

  // Referral Viewed
  Future<void> onReferralViewed({required String email}) async {
    await _track('Referral Viewed', properties: {'email': email});
  }

  // Referral Initiated
  Future<void> onReferralInitiated({required String email}) async {
    await _track(
      'Referral Initiated',
      properties: {
        'email': email,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Referral Joined
  Future<void> onReferralJoined({
    required String referredBy,
    required bool referralBonusEarned,
    required String email,
    required String referraCode,
  }) async {
    await _track(
      'Referral Joined',
      properties: {
        'referred_by': referredBy,
        'referral_bonus_earned': referralBonusEarned,
        'email': email,
        'referral_code': referraCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Home Screen Viewed
  Future<void> onHomeScreenViewed({required String userId}) async {
    await _track('Home Screen Viewed', properties: {'user_id': userId});
  }

  // Nearby Cafe Viewed
  Future<void> onNearbyCafeViewed({required String email}) async {
    await _track(
      'Nearby Cafe Viewed',
      properties: {
        'email': '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Cafe List Viewed
  Future<void> onCafeListViewed({
    required String sortType,
    required String filterType,
  }) async {
    await _track(
      'Cafe List Viewed',
      properties: {'sort_type': sortType, 'filter_type': filterType},
    );
  }

  // Gaming Cafe Viewed
  Future<void> onGamingCafeViewed({
    required String cafeId,
    required String cafeName,
    required String location,
    required List<String> availableGames,
    required email,
  }) async {
    await _track(
      'Gaming Cafe Viewed',
      properties: {
        'cafe_id': cafeId,
        'cafe_name': cafeName,
        'location': location,
        'available_games': availableGames,
        'email': email,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      },
    );
  }

  // Cafe Console Selected
  Future<void> onCafeConsoleSelected({
    required String email,
    required String consoleType,
    required int consoleAmount,
  }) async {
    await _track(
      'Cafe Console Selected',
      properties: {
        'email': '',
        'console_type': consoleType,
        'console_amount': consoleAmount,
      },
    );
  }

  // Cafe Images Viewed
  Future<void> onCafeImagesViewed({required String cafeId}) async {
    await _track('Cafe Images Viewed', properties: {'cafe_id': cafeId});
  }

  // Game Details Viewed
  Future<void> onGameDetailsViewed({
    required String gameId,
    required String cafeId,
  }) async {
    await _track(
      'Game Details Viewed',
      properties: {'game_id': gameId, 'cafe_id': cafeId},
    );
  }

  // Meal Selected
  Future<void> onMealSelected({
    required String email,
    required List<Map<String, dynamic>> selectedMeal,
  }) async {
    await _track(
      'Meal Selected',
      properties: {'email': email, 'selected_meal': selectedMeal},
    );
  }

  // Booking Started
  Future<void> onBookingStarted({
    required String cafeId,
    required String gameId,
    required String slotTime,
    required String email,
    required String consoleType,
    required int consoleAmount,
  }) async {
    await _track(
      'Booking Started',
      properties: {
        'cafe_id': cafeId,
        'game_id': gameId,
        'slot_time': slotTime,
        'email': email,
        'console_type': consoleType,
        'console_amount': consoleAmount,
      },
    );
  }

  // Booking Summary Viewed
  Future<void> onBookingSummaryViewed({
    required String bookingId,
    required String cafeId,
    required double amount,
  }) async {
    await _track(
      'Booking Summary Viewed',
      properties: {
        'booking_id': bookingId,
        'cafe_id': cafeId,
        'amount': amount,
      },
    );
  }

  // Payment Initiated
  Future<void> onPaymentInitiated({
    required String bookingId,
    required double amount,
    required String paymentMethodSelected,
  }) async {
    await _track(
      'Payment Initiated',
      properties: {
        'booking_id': bookingId,
        'amount': amount,
        'payment_method_selected': paymentMethodSelected,
      },
    );
  }

  // Vouncher Redeemed
  Future<void> onVouncherRedeemed({
    required String email,
    required String consoleType,
    required int consoleAmount,
    required String slotTime,
    required String mealType,
  }) async {
    await _track(
      'Vouncher Redeemed',
      properties: {
        'email': email,
        'console_type': consoleType,
        'console_amount': consoleAmount,
        'slotTime': slotTime,
        'meal_type': mealType,
      },
    );
  }

  // Payment Success
  Future<void> onPaymentSuccess({
    required String transactionId,
    required String bookingId,
    required String paymentGateway,
  }) async {
    await _track(
      'Payment Success',
      properties: {
        'transaction_id': transactionId,
        'booking_id': bookingId,
        'payment_gateway': paymentGateway,
      },
    );
  }

  // Payment Failed
  Future<void> onPaymentFailed({
    required String reason,
    required String paymentGateway,
  }) async {
    await _track(
      'Payment Failed',
      properties: {'reason': reason, 'payment_gateway': paymentGateway},
    );
  }

  // Booking Confirmed
  Future<void> onBookingConfirmed({
    required String bookingId,
    required String startTime,
    required String duration,
    required String slotTime,
    required String email,
    required String consoleType,
    required int consoleAmount,
    required String paymentMethod,
  }) async {
    await _track(
      'Booking Confirmed',
      properties: {
        'booking_id': bookingId,
        'start_time': startTime,
        'duration': duration,
        'slot_time': slotTime,
        'email': email,
        'console_type': consoleType,
        'console_amount': consoleAmount,
        'payment_method_opted': paymentMethod,
      },
    );
  }

  // Game Started
  Future<void> onGameStarted({
    required String gameId,
    required String mode,
    required double entryFee,
  }) async {
    await _track(
      'Game Started',
      properties: {'game_id': gameId, 'mode': mode, 'entry_fee': entryFee},
    );
  }

  // Game Abandoned
  Future<void> onGameAbandoned({
    required String gameId,
    required String reason,
  }) async {
    await _track(
      'Game Abandoned',
      properties: {'game_id': gameId, 'reason': reason},
    );
  }

  // Game Completed
  Future<void> onGameCompleted({
    required String gameId,
    required String result,
    required String duration,
    required int pointsEarned,
  }) async {
    await _track(
      'Game Completed',
      properties: {
        'game_id': gameId,
        'result': result,
        'duration': duration,
        'points_earned': pointsEarned,
      },
    );
  }

  // Wallet Viewed
  Future<void> onWalletViewed({required String userId}) async {
    await _track('Wallet Viewed', properties: {'user_id': userId});
  }

  // Add Money Initiated
  Future<void> onAddMoneyInitiated({required double amountEntered}) async {
    await _track(
      'Add Money Initiated',
      properties: {'amount_entered': amountEntered},
    );
  }

  // Add Money Success
  Future<void> onAddMoneySuccess({
    required double amountAdded,
    required String txnId,
  }) async {
    await _track(
      'Add Money Success',
      properties: {'amount_added': amountAdded, 'txn_id': txnId},
    );
  }

  // Withdrawal Initiated
  Future<void> onWithdrawalInitiated({
    required double amount,
    required String bankAccount,
  }) async {
    await _track(
      'Withdrawal Initiated',
      properties: {'amount': amount, 'bank_account': bankAccount},
    );
  }

  // Withdrawal Success
  Future<void> onWithdrawalSuccess({
    required String payoutId,
    required double amount,
  }) async {
    await _track(
      'Withdrawal Success',
      properties: {'payout_id': payoutId, 'amount': amount},
    );
  }

  // Push Notification Received
  Future<void> onPushNotificationReceived({
    required String title,
    required String campaignId,
  }) async {
    await _track(
      'Push Notification Received',
      properties: {'title': title, 'campaign_id': campaignId},
    );
  }

  // Push Notification Clicked
  Future<void> onPushNotificationClicked({
    required String campaignId,
    required String screenTarget,
  }) async {
    await _track(
      'Push Notification Clicked',
      properties: {'campaign_id': campaignId, 'screen_target': screenTarget},
    );
  }

  // Campaign Viewed
  Future<void> onCampaignViewed({
    required String source,
    required String campaignId,
  }) async {
    await _track(
      'Campaign Viewed',
      properties: {'source': source, 'campaign_id': campaignId},
    );
  }

  // Campaign Conversion
  Future<void> onCampaignConversion({
    required String campaignId,
    required String action,
  }) async {
    await _track(
      'Campaign Conversion',
      properties: {'campaign_id': campaignId, 'action': action},
    );
  }

  // API Error
  Future<void> onApiError({
    required String endpoint,
    required String errorMessage,
  }) async {
    await _track(
      'API Error',
      properties: {'endpoint': endpoint, 'error_message': errorMessage},
    );
  }

  // App Crash Logged
  Future<void> onAppCrashLogged({
    required String stacktrace,
    required String screen,
  }) async {
    await _track(
      'App Crash Logged',
      properties: {'stacktrace': stacktrace, 'screen': screen},
    );
  }

  // Unexpected Logout
  Future<void> onUnexpectedLogout({required String reason}) async {
    await _track('Unexpected Logout', properties: {'reason': reason});
  }
}
