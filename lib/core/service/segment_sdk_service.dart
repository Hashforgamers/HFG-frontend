import 'dart:io';
import 'package:segment_analytics/client.dart';
import 'package:segment_analytics/state.dart';

class SegmentSdkService {
  static const writeKey = 'YasInkE3rAxlBFGID1yUeFaxtCWvWuz0';
  static final analytics = createClient(Configuration(writeKey, debug: true));

  // Event 1 - On App Launch
  Future<void> onAppLaunch() async {
    await analytics.track(
      'App Launched',
      properties: {
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'app_version': '1.0.0',
      },
    );
  }

  // Event 2 - OTP Requested
  Future<void> onOtpRequested({required String mobile}) async {
    await analytics.track(
      'OTP Requested',
      properties: {
        'mobile': mobile,
      },
    );
  }

  // Event 3 - OTP Verified
  Future<void> onOtpVerified({required String mobile}) async {
    await analytics.track(
      'OTP Verified',
      properties: {
        'mobile': mobile,
        'verification_status': 'success',
      },
    );
  }

  // Event 4 - Signup Started
  Future<void> onSignupStarted({required String referralCode}) async {
    await analytics.track(
      'Signup Started',
      properties: {
        'referral_code': referralCode,
      },
    );
  }

  // Event 5 - Signup Completed
  Future<void> onSignupCompleted(
      {required String referralBy, required String userId}) async {
    await analytics.track(
      'Signup Completed',
      properties: {
        'user_id': userId,
        'referred_by': referralBy,
        'source': '',
      },
    );
  }

  // Event 6 - Login Success
  Future<void> onLoginSuccess(
      {required String userId,
      required String loginMethod,
      required String deviceId}) async {
    await analytics.track(
      'Login Successful',
      properties: {
        'user_id': userId,
        'device_id': '',
        'login_method': '',
      },
    );
  }

  // Permissions Granted
  Future<void> onPermissionsGranted({
    required bool location,
    required bool notification,
    required bool contacts,
  }) async {
    await analytics.track(
      'Permissions Granted',
      properties: {
        'location': location,
        'notification': notification,
        'contacts': contacts,
      },
    );
  }

  // Profile Updated
  Future<void> onProfileUpdated({
    required List<String> updatedFields,
  }) async {
    await analytics.track(
      'Profile Updated',
      properties: {
        'updated_fields': updatedFields,
      },
    );
  }

  // Game Preferences Set
  Future<void> onGamePreferencesSet({
    required List<String> selectedGames,
  }) async {
    await analytics.track(
      'Console Selected',
      properties: {
        'selected_consoles': selectedGames,
      },
    );
  }

  // Referral Sent
  Future<void> onReferralSent({
    required String referralCode,
    required String channel,
  }) async {
    await analytics.track(
      'Referral Sent',
      properties: {
        'referral_code': referralCode,
        'channel': channel,
      },
    );
  }

  // Referral Joined
  Future<void> onReferralJoined({
    required String referredBy,
    required bool referralBonusEarned,
  }) async {
    await analytics.track(
      'Referral Joined',
      properties: {
        'referred_by': referredBy,
        'referral_bonus_earned': referralBonusEarned,
      },
    );
  }

  // Home Screen Viewed
  Future<void> onHomeScreenViewed({
    required String userId,
  }) async {
    await analytics.track(
      'Home Screen Viewed',
      properties: {
        'user_id': userId,
      },
    );
  }

  // Cafe List Viewed
  Future<void> onCafeListViewed({
    required String sortType,
    required String filterType,
  }) async {
    await analytics.track(
      'Cafe List Viewed',
      properties: {
        'sort_type': sortType,
        'filter_type': filterType,
      },
    );
  }

  // Gaming Cafe Viewed
  Future<void> onGamingCafeViewed({
    required String cafeId,
    required String location,
    required List<String> availableGames,
  }) async {
    await analytics.track(
      'Gaming Cafe Viewed',
      properties: {
        'cafe_id': cafeId,
        'location': location,
        'available_games': availableGames,
      },
    );
  }

  // Cafe Images Viewed
  Future<void> onCafeImagesViewed({
    required String cafeId,
  }) async {
    await analytics.track(
      'Cafe Images Viewed',
      properties: {
        'cafe_id': cafeId,
      },
    );
  }

  // Game Details Viewed
  Future<void> onGameDetailsViewed({
    required String gameId,
    required String cafeId,
  }) async {
    await analytics.track(
      'Game Details Viewed',
      properties: {
        'game_id': gameId,
        'cafe_id': cafeId,
      },
    );
  }

  // Booking Started
  Future<void> onBookingStarted({
    required String cafeId,
    required String gameId,
    required String slotTime,
  }) async {
    await analytics.track(
      'Booking Started',
      properties: {
        'cafe_id': cafeId,
        'game_id': gameId,
        'slot_time': slotTime,
      },
    );
  }

  // Booking Summary Viewed
  Future<void> onBookingSummaryViewed({
    required String bookingId,
    required String cafeId,
    required double amount,
  }) async {
    await analytics.track(
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
    await analytics.track(
      'Payment Initiated',
      properties: {
        'booking_id': bookingId,
        'amount': amount,
        'payment_method_selected': paymentMethodSelected,
      },
    );
  }

  // Payment Success
  Future<void> onPaymentSuccess({
    required String transactionId,
    required String bookingId,
    required String paymentGateway,
  }) async {
    await analytics.track(
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
    await analytics.track(
      'Payment Failed',
      properties: {
        'reason': reason,
        'payment_gateway': paymentGateway,
      },
    );
  }

  // Booking Confirmed
  Future<void> onBookingConfirmed({
    required String bookingId,
    required String startTime,
    required String duration,
  }) async {
    await analytics.track(
      'Booking Confirmed',
      properties: {
        'booking_id': bookingId,
        'start_time': startTime,
        'duration': duration,
      },
    );
  }

  // Game Started
  Future<void> onGameStarted({
    required String gameId,
    required String mode,
    required double entryFee,
  }) async {
    await analytics.track(
      'Game Started',
      properties: {
        'game_id': gameId,
        'mode': mode,
        'entry_fee': entryFee,
      },
    );
  }

  // Game Abandoned
  Future<void> onGameAbandoned({
    required String gameId,
    required String reason,
  }) async {
    await analytics.track(
      'Game Abandoned',
      properties: {
        'game_id': gameId,
        'reason': reason,
      },
    );
  }

  // Game Completed
  Future<void> onGameCompleted({
    required String gameId,
    required String result,
    required String duration,
    required int pointsEarned,
  }) async {
    await analytics.track(
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
  Future<void> onWalletViewed({
    required String userId,
  }) async {
    await analytics.track(
      'Wallet Viewed',
      properties: {
        'user_id': userId,
      },
    );
  }

  // Add Money Initiated
  Future<void> onAddMoneyInitiated({
    required double amountEntered,
  }) async {
    await analytics.track(
      'Add Money Initiated',
      properties: {
        'amount_entered': amountEntered,
      },
    );
  }

  // Add Money Success
  Future<void> onAddMoneySuccess({
    required double amountAdded,
    required String txnId,
  }) async {
    await analytics.track(
      'Add Money Success',
      properties: {
        'amount_added': amountAdded,
        'txn_id': txnId,
      },
    );
  }

  // Withdrawal Initiated
  Future<void> onWithdrawalInitiated({
    required double amount,
    required String bankAccount,
  }) async {
    await analytics.track(
      'Withdrawal Initiated',
      properties: {
        'amount': amount,
        'bank_account': bankAccount,
      },
    );
  }

  // Withdrawal Success
  Future<void> onWithdrawalSuccess({
    required String payoutId,
    required double amount,
  }) async {
    await analytics.track(
      'Withdrawal Success',
      properties: {
        'payout_id': payoutId,
        'amount': amount,
      },
    );
  }

  // Push Notification Received
  Future<void> onPushNotificationReceived({
    required String title,
    required String campaignId,
  }) async {
    await analytics.track(
      'Push Notification Received',
      properties: {
        'title': title,
        'campaign_id': campaignId,
      },
    );
  }

  // Push Notification Clicked
  Future<void> onPushNotificationClicked({
    required String campaignId,
    required String screenTarget,
  }) async {
    await analytics.track(
      'Push Notification Clicked',
      properties: {
        'campaign_id': campaignId,
        'screen_target': screenTarget,
      },
    );
  }

  // Campaign Viewed
  Future<void> onCampaignViewed({
    required String source,
    required String campaignId,
  }) async {
    await analytics.track(
      'Campaign Viewed',
      properties: {
        'source': source,
        'campaign_id': campaignId,
      },
    );
  }

  // Campaign Conversion
  Future<void> onCampaignConversion({
    required String campaignId,
    required String action,
  }) async {
    await analytics.track(
      'Campaign Conversion',
      properties: {
        'campaign_id': campaignId,
        'action': action,
      },
    );
  }

  // API Error
  Future<void> onApiError({
    required String endpoint,
    required String errorMessage,
  }) async {
    await analytics.track(
      'API Error',
      properties: {
        'endpoint': endpoint,
        'error_message': errorMessage,
      },
    );
  }

  // App Crash Logged
  Future<void> onAppCrashLogged({
    required String stacktrace,
    required String screen,
  }) async {
    await analytics.track(
      'App Crash Logged',
      properties: {
        'stacktrace': stacktrace,
        'screen': screen,
      },
    );
  }

  // Unexpected Logout
  Future<void> onUnexpectedLogout({
    required String reason,
  }) async {
    await analytics.track(
      'Unexpected Logout',
      properties: {
        'reason': reason,
      },
    );
  }
}
