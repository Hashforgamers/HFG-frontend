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

  // Event 1 - On App Launch
  Future<void> onAppLaunch() async {
    await logEvent('App Launched', {
      'device_type': '', // Platform info should be passed from caller
      'app_version': '', // App version should be passed from caller
    });
  }

  // Event 2 - OTP Requested
  Future<void> onOtpRequested({required String mobile}) async {
    await logEvent('OTP Requested', {
      'mobile': mobile,
      'method': 'sms',
    });
  }

  // Event 3 - OTP Verified
  Future<void> onOtpVerified({required String mobile}) async {
    await logEvent('OTP Verified', {
      'mobile': mobile,
      'verification_status': 'success',
    });
  }

  // Event 4 - Signup Started
  Future<void> onSignupStarted({required String referralCode}) async {
    await logEvent('Signup Started', {
      'referral_code': referralCode,
    });
  }

  // Event 5 - Signup Completed
  Future<void> onSignupCompleted({required String referralBy, required String userId}) async {
    await logEvent('Signup Completed', {
      'user_id': userId,
      'referred_by': referralBy,
      'source': '',
    });
  }

  // Event 6 - Login Success
  Future<void> onLoginSuccess({required String userId, required String loginMethod, required String deviceId}) async {
    await logEvent('Login Successful', {
      'user_id': userId,
      'device_id': deviceId,
      'login_method': loginMethod,
    });
  }

  // Permissions Granted
  Future<void> onPermissionsGranted({required bool location, required bool notification, required bool contacts}) async {
    await logEvent('Permissions Granted', {
      'location': location,
      'notification': notification,
      'contacts': contacts,
    });
  }

  // Profile Updated
  Future<void> onProfileUpdated({required List<String> updatedFields}) async {
    await logEvent('Profile Updated', {
      'updated_fields': updatedFields.join(','),
    });
  }

  // Game Preferences Set
  Future<void> onGamePreferencesSet({required List<String> selectedGames}) async {
    await logEvent('Console Selected', {
      'selected_consoles': selectedGames.join(','),
    });
  }

  // Referral Sent
  Future<void> onReferralSent({required String referralCode, required String channel}) async {
    await logEvent('Referral Sent', {
      'referral_code': referralCode,
      'channel': channel,
    });
  }

  // Referral Joined
  Future<void> onReferralJoined({required String referredBy, required bool referralBonusEarned}) async {
    await logEvent('Referral Joined', {
      'referred_by': referredBy,
      'referral_bonus_earned': referralBonusEarned,
    });
  }

  // Home Screen Viewed
  Future<void> onHomeScreenViewed({required String userId}) async {
    await logEvent('Home Screen Viewed', {
      'user_id': userId,
    });
  }

  // Cafe List Viewed
  Future<void> onCafeListViewed({required String sortType, required String filterType}) async {
    await logEvent('Cafe List Viewed', {
      'sort_type': sortType,
      'filter_type': filterType,
    });
  }

  // Gaming Cafe Viewed
  Future<void> onGamingCafeViewed({required String cafeId, required String location, required List<String> availableGames}) async {
    await logEvent('Gaming Cafe Viewed', {
      'cafe_id': cafeId,
      'location': location,
      'available_games': availableGames.join(','),
    });
  }

  // Cafe Images Viewed
  Future<void> onCafeImagesViewed({required String cafeId}) async {
    await logEvent('Cafe Images Viewed', {
      'cafe_id': cafeId,
    });
  }

  // Game Details Viewed
  Future<void> onGameDetailsViewed({required String gameId, required String cafeId}) async {
    await logEvent('Game Details Viewed', {
      'game_id': gameId,
      'cafe_id': cafeId,
    });
  }

  // Booking Started
  Future<void> onBookingStarted({required String cafeId, required String gameId, required String slotTime}) async {
    await logEvent('Booking Started', {
      'cafe_id': cafeId,
      'game_id': gameId,
      'slot_time': slotTime,
    });
  }

  // Booking Summary Viewed
  Future<void> onBookingSummaryViewed({required String bookingId, required String cafeId, required double amount}) async {
    await logEvent('Booking Summary Viewed', {
      'booking_id': bookingId,
      'cafe_id': cafeId,
      'amount': amount,
    });
  }

  // Payment Initiated
  Future<void> onPaymentInitiated({required String bookingId, required double amount, required String paymentMethodSelected}) async {
    await logEvent('Payment Initiated', {
      'booking_id': bookingId,
      'amount': amount,
      'payment_method_selected': paymentMethodSelected,
    });
  }

  // Payment Success
  Future<void> onPaymentSuccess({required String transactionId, required String bookingId, required String paymentGateway}) async {
    await logEvent('Payment Success', {
      'transaction_id': transactionId,
      'booking_id': bookingId,
      'payment_gateway': paymentGateway,
    });
  }

  // Payment Failed
  Future<void> onPaymentFailed({required String reason, required String paymentGateway}) async {
    await logEvent('Payment Failed', {
      'reason': reason,
      'payment_gateway': paymentGateway,
    });
  }

  // Booking Confirmed
  Future<void> onBookingConfirmed({required String bookingId, required String startTime, required String duration}) async {
    await logEvent('Booking Confirmed', {
      'booking_id': bookingId,
      'start_time': startTime,
      'duration': duration,
    });
  }

  // Game Started
  Future<void> onGameStarted({required String gameId, required String mode, required double entryFee}) async {
    await logEvent('Game Started', {
      'game_id': gameId,
      'mode': mode,
      'entry_fee': entryFee,
    });
  }

  // Game Abandoned
  Future<void> onGameAbandoned({required String gameId, required String reason}) async {
    await logEvent('Game Abandoned', {
      'game_id': gameId,
      'reason': reason,
    });
  }

  // Game Completed
  Future<void> onGameCompleted({required String gameId, required String result, required String duration, required int pointsEarned}) async {
    await logEvent('Game Completed', {
      'game_id': gameId,
      'result': result,
      'duration': duration,
      'points_earned': pointsEarned,
    });
  }

  // Wallet Viewed
  Future<void> onWalletViewed({required String userId}) async {
    await logEvent('Wallet Viewed', {
      'user_id': userId,
    });
  }

  // Add Money Initiated
  Future<void> onAddMoneyInitiated({required double amountEntered}) async {
    await logEvent('Add Money Initiated', {
      'amount_entered': amountEntered,
    });
  }

  // Add Money Success
  Future<void> onAddMoneySuccess({required double amountAdded, required String txnId}) async {
    await logEvent('Add Money Success', {
      'amount_added': amountAdded,
      'txn_id': txnId,
    });
  }

  // Withdrawal Initiated
  Future<void> onWithdrawalInitiated({required double amount, required String bankAccount}) async {
    await logEvent('Withdrawal Initiated', {
      'amount': amount,
      'bank_account': bankAccount,
    });
  }

  // Withdrawal Success
  Future<void> onWithdrawalSuccess({required String payoutId, required double amount}) async {
    await logEvent('Withdrawal Success', {
      'payout_id': payoutId,
      'amount': amount,
    });
  }

  // Push Notification Received
  Future<void> onPushNotificationReceived({required String title, required String campaignId}) async {
    await logEvent('Push Notification Received', {
      'title': title,
      'campaign_id': campaignId,
    });
  }

  // Push Notification Clicked
  Future<void> onPushNotificationClicked({required String campaignId, required String screenTarget}) async {
    await logEvent('Push Notification Clicked', {
      'campaign_id': campaignId,
      'screen_target': screenTarget,
    });
  }

  // Campaign Viewed
  Future<void> onCampaignViewed({required String source, required String campaignId}) async {
    await logEvent('Campaign Viewed', {
      'source': source,
      'campaign_id': campaignId,
    });
  }

  // Campaign Conversion
  Future<void> onCampaignConversion({required String campaignId, required String action}) async {
    await logEvent('Campaign Conversion', {
      'campaign_id': campaignId,
      'action': action,
    });
  }

  // API Error
  Future<void> onApiError({required String endpoint, required String errorMessage}) async {
    await logEvent('API Error', {
      'endpoint': endpoint,
      'error_message': errorMessage,
    });
  }

  // App Crash Logged
  Future<void> onAppCrashLogged({required String stacktrace, required String screen}) async {
    await logEvent('App Crash Logged', {
      'stacktrace': stacktrace,
      'screen': screen,
    });
  }

  // Unexpected Logout
  Future<void> onUnexpectedLogout({required String reason}) async {
    await logEvent('Unexpected Logout', {
      'reason': reason,
    });
  }
}
