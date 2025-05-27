import 'package:amplitude_flutter/amplitude.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class AmplitudeService {
  static final AmplitudeService _instance = AmplitudeService._internal();
  late final Amplitude _amplitude;
  late final DeviceInfoPlugin _deviceInfo;
  late final PackageInfo _packageInfo;

  // Private constructor
  AmplitudeService._internal();

  // Factory constructor
  factory AmplitudeService() {
    return _instance;
  }

  // Initialize Amplitude
  Future<void> initialize() async {
    _amplitude = Amplitude.getInstance();
    _deviceInfo = DeviceInfoPlugin();
    _packageInfo = await PackageInfo.fromPlatform();

    await _amplitude.init('31a5448c4f706f201b4ed08d522783fe');
    await _amplitude.enableCoppaControl();
  }

  // Get device type
  Future<String> _getDeviceType() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return 'Android ${androidInfo.version.release}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return 'iOS ${iosInfo.systemVersion}';
    }
    return 'Unknown';
  }

  // Track App Opened
  Future<void> trackAppOpened() async {
    final deviceType = await _getDeviceType();
    await _amplitude.logEvent(
      'App Opened',
      eventProperties: {
        'device_type': deviceType,
        'app_version': _packageInfo.version,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track OTP Requested
  Future<void> trackOtpRequested({
    required String mobile,
    required String method,
  }) async {
    await _amplitude.logEvent(
      'OTP Requested',
      eventProperties: {
        'mobile': mobile,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track OTP Verified
  Future<void> trackOtpVerified({
    required String mobile,
    required String verificationStatus,
  }) async {
    await _amplitude.logEvent(
      'OTP Verified',
      eventProperties: {
        'mobile': mobile,
        'verification_status': verificationStatus,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Signup Started
  Future<void> trackSignupStarted({String? referralCode}) async {
    await _amplitude.logEvent(
      'Signup Started',
      eventProperties: {
        'referral_code': referralCode,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Signed Up
  Future<void> trackSignedUp({
    required String userId,
    required String source,
    String? referredBy,
  }) async {
    await _amplitude.logEvent(
      'Signed Up',
      eventProperties: {
        'user_id': userId,
        'source': source,
        'referred_by': referredBy,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Login Successful
  Future<void> trackLoginSuccessful({
    required String userId,
    required String deviceId,
    required String loginMethod,
  }) async {
    await _amplitude.logEvent(
      'Login Successful',
      eventProperties: {
        'user_id': userId,
        'device_id': deviceId,
        'login_method': loginMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Permissions Granted
  Future<void> trackPermissionsGranted({
    required bool location,
    required bool notification,
    required bool contacts,
  }) async {
    await _amplitude.logEvent(
      'Permissions Granted',
      eventProperties: {
        'location': location,
        'notification': notification,
        'contacts': contacts,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Profile Updated
  Future<void> trackProfileUpdated({
    required List<String> updatedFields,
  }) async {
    await _amplitude.logEvent(
      'Profile Updated',
      eventProperties: {
        'updated_fields': updatedFields,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Game Preferences Set
  Future<void> trackGamePreferencesSet({
    required List<String> selectedGames,
  }) async {
    await _amplitude.logEvent(
      'Game Preferences Set',
      eventProperties: {
        'selected_games': selectedGames,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Referral Sent
  Future<void> trackReferralSent({
    required String referralCode,
    required String channel,
  }) async {
    await _amplitude.logEvent(
      'Referral Sent',
      eventProperties: {
        'referral_code': referralCode,
        'channel': channel,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Referral Joined
  Future<void> trackReferralJoined({
    required String referredBy,
    required double referralBonusEarned,
  }) async {
    await _amplitude.logEvent(
      'Referral Joined',
      eventProperties: {
        'referred_by': referredBy,
        'referral_bonus_earned': referralBonusEarned,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Home Screen Viewed
  Future<void> trackHomeScreenViewed({
    required String userId,
  }) async {
    await _amplitude.logEvent(
      'Home Screen Viewed',
      eventProperties: {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Cafe List Viewed
  Future<void> trackCafeListViewed({
    required String sortType,
    required String filterType,
  }) async {
    await _amplitude.logEvent(
      'Cafe List Viewed',
      eventProperties: {
        'sort_type': sortType,
        'filter_type': filterType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Gaming Cafe Viewed
  Future<void> trackGamingCafeViewed({
    required String cafeId,
    required String location,
    required List<String> availableGames,
  }) async {
    await _amplitude.logEvent(
      'Gaming Cafe Viewed',
      eventProperties: {
        'cafe_id': cafeId,
        'location': location,
        'available_games': availableGames,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Cafe Images Viewed
  Future<void> trackCafeImagesViewed({
    required String cafeId,
  }) async {
    await _amplitude.logEvent(
      'Cafe Images Viewed',
      eventProperties: {
        'cafe_id': cafeId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Game Details Viewed
  Future<void> trackGameDetailsViewed({
    required String gameId,
    required String cafeId,
  }) async {
    await _amplitude.logEvent(
      'Game Details Viewed',
      eventProperties: {
        'game_id': gameId,
        'cafe_id': cafeId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Booking Started
  Future<void> trackBookingStarted({
    required String cafeId,
    required String gameId,
    required String slotTime,
  }) async {
    await _amplitude.logEvent(
      'Booking Started',
      eventProperties: {
        'cafe_id': cafeId,
        'game_id': gameId,
        'slot_time': slotTime,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Booking Summary Viewed
  Future<void> trackBookingSummaryViewed({
    required String bookingId,
    required String cafeId,
    required double amount,
  }) async {
    await _amplitude.logEvent(
      'Booking Summary Viewed',
      eventProperties: {
        'booking_id': bookingId,
        'cafe_id': cafeId,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Payment Initiated
  Future<void> trackPaymentInitiated({
    required String bookingId,
    required double amount,
    required String paymentMethodSelected,
  }) async {
    await _amplitude.logEvent(
      'Payment Initiated',
      eventProperties: {
        'booking_id': bookingId,
        'amount': amount,
        'payment_method_selected': paymentMethodSelected,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Payment Success
  Future<void> trackPaymentSuccess({
    required String transactionId,
    required String bookingId,
    required String paymentGateway,
  }) async {
    await _amplitude.logEvent(
      'Payment Success',
      eventProperties: {
        'transaction_id': transactionId,
        'booking_id': bookingId,
        'payment_gateway': paymentGateway,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Payment Failed
  Future<void> trackPaymentFailed({
    required String reason,
    required String paymentGateway,
  }) async {
    await _amplitude.logEvent(
      'Payment Failed',
      eventProperties: {
        'reason': reason,
        'payment_gateway': paymentGateway,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Booking Confirmed
  Future<void> trackBookingConfirmed({
    required String bookingId,
    required String startTime,
    required String duration,
  }) async {
    await _amplitude.logEvent(
      'Booking Confirmed',
      eventProperties: {
        'booking_id': bookingId,
        'start_time': startTime,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Game Started
  Future<void> trackGameStarted({
    required String gameId,
    required String mode,
    required double entryFee,
  }) async {
    await _amplitude.logEvent(
      'Game Started',
      eventProperties: {
        'game_id': gameId,
        'mode': mode,
        'entry_fee': entryFee,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Game Abandoned
  Future<void> trackGameAbandoned({
    required String gameId,
    required String reason,
  }) async {
    await _amplitude.logEvent(
      'Game Abandoned',
      eventProperties: {
        'game_id': gameId,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Game Completed
  Future<void> trackGameCompleted({
    required String gameId,
    required String result,
    required String duration,
    required double pointsEarned,
  }) async {
    await _amplitude.logEvent(
      'Game Completed',
      eventProperties: {
        'game_id': gameId,
        'result': result,
        'duration': duration,
        'points_earned': pointsEarned,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Wallet Viewed
  Future<void> trackWalletViewed({
    required String userId,
  }) async {
    await _amplitude.logEvent(
      'Wallet Viewed',
      eventProperties: {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Add Money Initiated
  Future<void> trackAddMoneyInitiated({
    required double amountEntered,
  }) async {
    await _amplitude.logEvent(
      'Add Money Initiated',
      eventProperties: {
        'amount_entered': amountEntered,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Add Money Success
  Future<void> trackAddMoneySuccess({
    required double amountAdded,
    required String txnId,
  }) async {
    await _amplitude.logEvent(
      'Add Money Success',
      eventProperties: {
        'amount_added': amountAdded,
        'txn_id': txnId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Withdrawal Initiated
  Future<void> trackWithdrawalInitiated({
    required double amount,
    required String bankAccount,
  }) async {
    await _amplitude.logEvent(
      'Withdrawal Initiated',
      eventProperties: {
        'amount': amount,
        'bank_account': bankAccount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Withdrawal Success
  Future<void> trackWithdrawalSuccess({
    required String payoutId,
    required double amount,
  }) async {
    await _amplitude.logEvent(
      'Withdrawal Success',
      eventProperties: {
        'payout_id': payoutId,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Push Notification Received
  Future<void> trackPushNotificationReceived({
    required String title,
    required String campaignId,
  }) async {
    await _amplitude.logEvent(
      'Push Notification Received',
      eventProperties: {
        'title': title,
        'campaign_id': campaignId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Push Notification Clicked
  Future<void> trackPushNotificationClicked({
    required String campaignId,
    required String screenTarget,
  }) async {
    await _amplitude.logEvent(
      'Push Notification Clicked',
      eventProperties: {
        'campaign_id': campaignId,
        'screen_target': screenTarget,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Campaign Viewed
  Future<void> trackCampaignViewed({
    required String source,
    required String campaignId,
  }) async {
    await _amplitude.logEvent(
      'Campaign Viewed',
      eventProperties: {
        'source': source,
        'campaign_id': campaignId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Campaign Conversion
  Future<void> trackCampaignConversion({
    required String campaignId,
    required String action,
  }) async {
    await _amplitude.logEvent(
      'Campaign Conversion',
      eventProperties: {
        'campaign_id': campaignId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track API Error
  Future<void> trackApiError({
    required String endpoint,
    required String errorMessage,
  }) async {
    await _amplitude.logEvent(
      'API Error',
      eventProperties: {
        'endpoint': endpoint,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track App Crash
  Future<void> trackAppCrash({
    required String stacktrace,
    required String screen,
  }) async {
    await _amplitude.logEvent(
      'App Crash Logged',
      eventProperties: {
        'stacktrace': stacktrace,
        'screen': screen,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Unexpected Logout
  Future<void> trackUnexpectedLogout({
    required String reason,
  }) async {
    await _amplitude.logEvent(
      'Unexpected Logout',
      eventProperties: {
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Set User ID
  Future<void> setUserId(String userId) async {
    await _amplitude.setUserId(userId);
  }

  // Reset User ID
  Future<void> resetUserId() async {
    await _amplitude.setUserId(null);
  }

  // Track Game Action
  Future<void> trackGameAction({
    required String action,
    String? gameId,
    String? gameType,
    String? gameName,
    double? gameRating,
    int? gameCount,
    String? error,
  }) async {
    await _amplitude.logEvent(
      'Game Action',
      eventProperties: {
        'action': action,
        'game_id': gameId,
        'game_type': gameType,
        'game_name': gameName,
        'game_rating': gameRating,
        'game_count': gameCount,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Payment Error
  Future<void> trackPaymentError({
    required String error,
    String? orderId,
  }) async {
    await _amplitude.logEvent(
      'Payment Error',
      eventProperties: {
        'error': error,
        'order_id': orderId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Wallet Action
  Future<void> trackWalletAction({
    required String action,
    double? amount,
    String? transactionId,
    String? status,
  }) async {
    await _amplitude.logEvent(
      'Wallet Action',
      eventProperties: {
        'action': action,
        'amount': amount,
        'transaction_id': transactionId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Screen View
  Future<void> trackScreenView({
    required String screenName,
  }) async {
    await _amplitude.logEvent(
      'Screen View',
      eventProperties: {
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Track Navigation
  Future<void> trackNavigation({
    required String fromScreen,
    required String toScreen,
  }) async {
    await _amplitude.logEvent(
      'Navigation',
      eventProperties: {
        'from_screen': fromScreen,
        'to_screen': toScreen,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}