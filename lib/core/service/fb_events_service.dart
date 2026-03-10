import 'dart:io';
import 'dart:convert';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/service/device_identifier_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FbEventsService {
  FbEventsService({required DeviceIdentifierService deviceIdentifierService})
    : _deviceIdentifierService = deviceIdentifierService;

  static final fbAppEvents = FacebookAppEvents();
  static final FirebaseAnalytics _firebaseAnalytics =
      FirebaseAnalytics.instance;
  final DeviceIdentifierService _deviceIdentifierService;

  String _toFirebaseKey(String raw, {required String fallback}) {
    final normalized = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isEmpty) return fallback;
    final startsWithLetter = RegExp(r'^[a-z]').hasMatch(normalized);
    final safe = startsWithLetter ? normalized : 'e_$normalized';
    return safe.length > 40 ? safe.substring(0, 40) : safe;
  }

  Map<String, Object> _toFirebaseParams(Map<String, dynamic> input) {
    final result = <String, Object>{};
    input.forEach((key, value) {
      final safeKey = _toFirebaseKey(key, fallback: 'param');
      if (value == null) return;
      if (value is String || value is num) {
        result[safeKey] = value;
        return;
      }
      if (value is bool) {
        result[safeKey] = value ? 1 : 0;
        return;
      }
      if (value is List || value is Map) {
        result[safeKey] = value.toString();
        return;
      }
      result[safeKey] = '$value';
    });
    return result;
  }

  Future<void> _logFirebaseEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    final safeName = _toFirebaseKey(eventName, fallback: 'custom_event');
    await _firebaseAnalytics.logEvent(
      name: safeName,
      parameters: _toFirebaseParams(parameters),
    );
  }

  Future<void> _logBoth(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    final payload = <String, dynamic>{...parameters};
    payload.addAll(await _identityPayload());
    await Future.wait([
      fbAppEvents.logEvent(name: eventName, parameters: payload),
      _logFirebaseEvent(eventName, payload),
    ]);
  }

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

  // NEW: generic custom event (parity with Segment)
  Future<void> onCustomEvent(
    String name,
    Map<String, dynamic> properties,
  ) async {
    await _logBoth(name, properties);
  }

  Future<void> logEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    await _logBoth(eventName, parameters);
  }

  /// iOS only: sync ATT status to Facebook SDK.
  /// When ATT is authorized, advertiser tracking + ID collection are enabled.
  Future<void> configureAdvertiserTrackingForIos({
    bool promptIfNeeded = true,
  }) async {
    if (!Platform.isIOS) return;
    try {
      var status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined && promptIfNeeded) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }

      final enabled = status == TrackingStatus.authorized;
      await fbAppEvents.setAdvertiserTracking(
        enabled: enabled,
        collectId: enabled,
      );

      await _logFirebaseEvent('ATT Status Updated', {
        'att_status': status.name,
        'advertiser_tracking_enabled': enabled,
      });
    } catch (_) {
      // Do not block app startup because of ATT/SDK errors.
    }
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
    await logEvent('OTP Requested', {'mobile': mobile, 'method': 'sms'});
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
    await logEvent('Signup Started', {'referral_code': referralCode});
  }

  // Event 5 - Signup Completed
  Future<void> onSignupCompleted({
    required String referralBy,
    required String userId,
  }) async {
    await logEvent('Signup Completed', {
      'user_id': userId,
      'referred_by': referralBy,
      'source': '',
    });
  }

  // Event 6 - Login Success
  Future<void> onLoginSuccess({
    required String userId,
    required String loginMethod,
    required String deviceId,
  }) async {
    await logEvent('Login Successful', {
      'user_id': userId,
      'device_id': deviceId,
      'login_method': loginMethod,
    });
  }

  // Permissions Granted
  Future<void> onPermissionsGranted({
    required bool location,
    required bool notification,
    required bool contacts,
  }) async {
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
  Future<void> onGamePreferencesSet({
    required List<String> selectedGames,
  }) async {
    await logEvent('Console Selected', {
      'selected_consoles': selectedGames.join(','),
    });
  }

  // Referral Sent
  Future<void> onReferralSent({
    required String referralCode,
    required String channel,
  }) async {
    await logEvent('Referral Sent', {
      'referral_code': referralCode,
      'channel': channel,
    });
  }

  // Referral Joined
  Future<void> onReferralJoined({
    required String referredBy,
    required bool referralBonusEarned,
  }) async {
    await logEvent('Referral Joined', {
      'referred_by': referredBy,
      'referral_bonus_earned': referralBonusEarned,
    });
  }

  // Home Screen Viewed
  Future<void> onHomeScreenViewed({required String userId}) async {
    await logEvent('Home Screen Viewed', {'user_id': userId});
  }

  // Cafe List Viewed
  Future<void> onCafeListViewed({
    required String sortType,
    required String filterType,
  }) async {
    await logEvent('Cafe List Viewed', {
      'sort_type': sortType,
      'filter_type': filterType,
    });
  }

  // Gaming Cafe Viewed
  Future<void> onGamingCafeViewed({
    required String cafeId,
    required String location,
    required List<String> availableGames,
  }) async {
    await logEvent('Gaming Cafe Viewed', {
      'cafe_id': cafeId,
      'location': location,
      'available_games': availableGames.join(','),
    });
  }

  // Cafe Images Viewed
  Future<void> onCafeImagesViewed({required String cafeId}) async {
    await logEvent('Cafe Images Viewed', {'cafe_id': cafeId});
  }

  // Game Details Viewed
  Future<void> onGameDetailsViewed({
    required String gameId,
    required String cafeId,
  }) async {
    await logEvent('Game Details Viewed', {
      'game_id': gameId,
      'cafe_id': cafeId,
    });
  }

  // Booking Started
  Future<void> onBookingStarted({
    required String cafeId,
    required String gameId,
    required String slotTime,
  }) async {
    await logEvent('Booking Started', {
      'cafe_id': cafeId,
      'game_id': gameId,
      'slot_time': slotTime,
    });
  }

  // Booking Summary Viewed
  Future<void> onBookingSummaryViewed({
    required String bookingId,
    required String cafeId,
    required double amount,
  }) async {
    await logEvent('Booking Summary Viewed', {
      'booking_id': bookingId,
      'cafe_id': cafeId,
      'amount': amount,
    });
  }

  // Payment Initiated
  Future<void> onPaymentInitiated({
    required String bookingId,
    required double amount,
    required String paymentMethodSelected,
  }) async {
    await logEvent('Payment Initiated', {
      'booking_id': bookingId,
      'amount': amount,
      'payment_method_selected': paymentMethodSelected,
    });
  }

  // Payment Success
  Future<void> onPaymentSuccess({
    required String transactionId,
    required String bookingId,
    required String paymentGateway,
  }) async {
    await logEvent('Payment Success', {
      'transaction_id': transactionId,
      'booking_id': bookingId,
      'payment_gateway': paymentGateway,
    });
  }

  // Payment Failed
  Future<void> onPaymentFailed({
    required String reason,
    required String paymentGateway,
  }) async {
    await logEvent('Payment Failed', {
      'reason': reason,
      'payment_gateway': paymentGateway,
    });
  }

  // Booking Confirmed
  Future<void> onBookingConfirmed({
    required String bookingId,
    required String startTime,
    required String duration,
  }) async {
    await logEvent('Booking Confirmed', {
      'booking_id': bookingId,
      'start_time': startTime,
      'duration': duration,
    });
  }

  // Game Started
  Future<void> onGameStarted({
    required String gameId,
    required String mode,
    required double entryFee,
  }) async {
    await logEvent('Game Started', {
      'game_id': gameId,
      'mode': mode,
      'entry_fee': entryFee,
    });
  }

  // Game Abandoned
  Future<void> onGameAbandoned({
    required String gameId,
    required String reason,
  }) async {
    await logEvent('Game Abandoned', {'game_id': gameId, 'reason': reason});
  }

  // Game Completed
  Future<void> onGameCompleted({
    required String gameId,
    required String result,
    required String duration,
    required int pointsEarned,
  }) async {
    await logEvent('Game Completed', {
      'game_id': gameId,
      'result': result,
      'duration': duration,
      'points_earned': pointsEarned,
    });
  }

  // Wallet Viewed
  Future<void> onWalletViewed({required String userId}) async {
    await logEvent('Wallet Viewed', {'user_id': userId});
  }

  // Add Money Initiated
  Future<void> onAddMoneyInitiated({required double amountEntered}) async {
    await logEvent('Add Money Initiated', {'amount_entered': amountEntered});
  }

  // Add Money Success
  Future<void> onAddMoneySuccess({
    required double amountAdded,
    required String txnId,
  }) async {
    await logEvent('Add Money Success', {
      'amount_added': amountAdded,
      'txn_id': txnId,
    });
  }

  // Withdrawal Initiated
  Future<void> onWithdrawalInitiated({
    required double amount,
    required String bankAccount,
  }) async {
    await logEvent('Withdrawal Initiated', {
      'amount': amount,
      'bank_account': bankAccount,
    });
  }

  // Withdrawal Success
  Future<void> onWithdrawalSuccess({
    required String payoutId,
    required double amount,
  }) async {
    await logEvent('Withdrawal Success', {
      'payout_id': payoutId,
      'amount': amount,
    });
  }

  // Push Notification Received
  Future<void> onPushNotificationReceived({
    required String title,
    required String campaignId,
  }) async {
    await logEvent('Push Notification Received', {
      'title': title,
      'campaign_id': campaignId,
    });
  }

  // Push Notification Clicked
  Future<void> onPushNotificationClicked({
    required String campaignId,
    required String screenTarget,
  }) async {
    await logEvent('Push Notification Clicked', {
      'campaign_id': campaignId,
      'screen_target': screenTarget,
    });
  }

  // Campaign Viewed
  Future<void> onCampaignViewed({
    required String source,
    required String campaignId,
  }) async {
    await logEvent('Campaign Viewed', {
      'source': source,
      'campaign_id': campaignId,
    });
  }

  // Campaign Conversion
  Future<void> onCampaignConversion({
    required String campaignId,
    required String action,
  }) async {
    await logEvent('Campaign Conversion', {
      'campaign_id': campaignId,
      'action': action,
    });
  }

  // API Error
  Future<void> onApiError({
    required String endpoint,
    required String errorMessage,
  }) async {
    await logEvent('API Error', {
      'endpoint': endpoint,
      'error_message': errorMessage,
    });
  }

  // App Crash Logged
  Future<void> onAppCrashLogged({
    required String stacktrace,
    required String screen,
  }) async {
    await logEvent('App Crash Logged', {
      'stacktrace': stacktrace,
      'screen': screen,
    });
  }

  // Unexpected Logout
  Future<void> onUnexpectedLogout({required String reason}) async {
    await logEvent('Unexpected Logout', {'reason': reason});
  }

  // Search + discovery
  Future<void> onSearchPerformed({
    required String query,
    required String source,
  }) async => logEvent('Search Performed', {'query': query, 'source': source});

  Future<void> onFiltersApplied({
    required String screen,
    required List<String> filters,
  }) async => logEvent('Filters Applied', {
    'screen': screen,
    'filters': filters.join(','),
  });

  Future<void> onSortChanged({
    required String screen,
    required String sortBy,
  }) async => logEvent('Sort Changed', {'screen': screen, 'sort_by': sortBy});

  Future<void> onCityChanged({
    required String fromCity,
    required String toCity,
  }) async =>
      logEvent('City Changed', {'from_city': fromCity, 'to_city': toCity});

  Future<void> onNearbyCafesViewed({required String city}) async =>
      logEvent('Nearby Cafes Viewed', {'city': city});

  Future<void> onCafeReviewsViewed({required String cafeId}) async =>
      logEvent('Cafe Reviews Viewed', {'cafe_id': cafeId});

  Future<void> onCafeAmenitiesViewed({required String cafeId}) async =>
      logEvent('Cafe Amenities Viewed', {'cafe_id': cafeId});

  Future<void> onCafeTimingsViewed({required String cafeId}) async =>
      logEvent('Cafe Timings Viewed', {'cafe_id': cafeId});

  Future<void> onCafeLocationViewed({required String cafeId}) async =>
      logEvent('Cafe Location Viewed', {'cafe_id': cafeId});

  Future<void> onCafeShared({
    required String cafeId,
    required String channel,
  }) async => logEvent('Cafe Shared', {'cafe_id': cafeId, 'channel': channel});

  // Booking + payment
  Future<void> onBookingCancelled({
    required String bookingId,
    required String reason,
  }) async => logEvent('Booking Cancelled', {
    'booking_id': bookingId,
    'reason': reason,
  });

  Future<void> onSlotUnavailable({
    required String cafeId,
    required String slotTime,
  }) async =>
      logEvent('Slot Unavailable', {'cafe_id': cafeId, 'slot_time': slotTime});

  Future<void> onPaymentAbandoned({
    required String bookingId,
    required String step,
  }) async =>
      logEvent('Payment Abandoned', {'booking_id': bookingId, 'step': step});

  Future<void> onPaymentRetry({
    required String bookingId,
    required String paymentMethod,
  }) async => logEvent('Payment Retry', {
    'booking_id': bookingId,
    'payment_method': paymentMethod,
  });

  Future<void> onCouponApplied({
    required String couponCode,
    required double discountAmount,
  }) async => logEvent('Coupon Applied', {
    'coupon_code': couponCode,
    'discount_amount': discountAmount,
  });

  Future<void> onCouponFailed({
    required String couponCode,
    required String reason,
  }) async =>
      logEvent('Coupon Failed', {'coupon_code': couponCode, 'reason': reason});

  // Match + tournament
  Future<void> onGameLobbyJoined({
    required String gameId,
    required String lobbyId,
  }) async =>
      logEvent('Game Lobby Joined', {'game_id': gameId, 'lobby_id': lobbyId});

  Future<void> onMatchStarted({
    required String gameId,
    required String matchId,
  }) async =>
      logEvent('Match Started', {'game_id': gameId, 'match_id': matchId});

  Future<void> onMatchCompleted({
    required String gameId,
    required String matchId,
  }) async =>
      logEvent('Match Completed', {'game_id': gameId, 'match_id': matchId});

  Future<void> onMatchResult({
    required String gameId,
    required String matchId,
    required String result,
  }) async => logEvent('Match Result', {
    'game_id': gameId,
    'match_id': matchId,
    'result': result,
  });

  Future<void> onLeaderboardViewed({
    required String leaderboardType,
    String eventId = '',
  }) async => logEvent('Leaderboard Viewed', {
    'leaderboard_type': leaderboardType,
    'event_id': eventId,
  });

  Future<void> onTournamentViewed({required String eventId}) async =>
      logEvent('Tournament Viewed', {'event_id': eventId});

  Future<void> onTournamentJoined({
    required String eventId,
    required String teamId,
  }) async =>
      logEvent('Tournament Joined', {'event_id': eventId, 'team_id': teamId});

  Future<void> onFriendInvited({
    required String targetUserId,
    required String source,
  }) async => logEvent('Friend Invited', {
    'target_user_id': targetUserId,
    'source': source,
  });

  // Chat + party
  Future<void> onFriendOnline({required String friendUserId}) async =>
      logEvent('Friend Online', {'friend_user_id': friendUserId});

  Future<void> onChatStarted({
    required String chatType,
    required String roomId,
  }) async =>
      logEvent('Chat Started', {'chat_type': chatType, 'room_id': roomId});

  Future<void> onChatMessageSent({
    required String roomId,
    required String messageType,
  }) async => logEvent('Chat Message Sent', {
    'room_id': roomId,
    'message_type': messageType,
  });

  Future<void> onPartyCreated({
    required String partyId,
    required String gameId,
  }) async =>
      logEvent('Party Created', {'party_id': partyId, 'game_id': gameId});

  Future<void> onPartyJoined({
    required String partyId,
    required String gameId,
  }) async =>
      logEvent('Party Joined', {'party_id': partyId, 'game_id': gameId});

  // App lifecycle + retention
  Future<void> onAppBackgrounded({required String currentScreen}) async =>
      logEvent('App Backgrounded', {'current_screen': currentScreen});

  Future<void> onSessionEnded({
    required String userId,
    required String source,
  }) async => logEvent('Session Ended', {'user_id': userId, 'source': source});

  Future<void> onSessionDuration({
    required String userId,
    required int durationSeconds,
  }) async => logEvent('Session Duration', {
    'user_id': userId,
    'duration_seconds': durationSeconds,
  });

  Future<void> onUserInactive24h({required String userId}) async =>
      logEvent('User Inactive 24h', {'user_id': userId});

  Future<void> onUserInactive3d({required String userId}) async =>
      logEvent('User Inactive 3d', {'user_id': userId});

  Future<void> onUserInactive7d({required String userId}) async =>
      logEvent('User Inactive 7d', {'user_id': userId});

  // Cafe capacity/slot states
  Future<void> onCafeSlotViewed({
    required String cafeId,
    required String slotTime,
  }) async =>
      logEvent('Cafe Slot Viewed', {'cafe_id': cafeId, 'slot_time': slotTime});

  Future<void> onCafeSlotSelected({
    required String cafeId,
    required String slotTime,
  }) async => logEvent('Cafe Slot Selected', {
    'cafe_id': cafeId,
    'slot_time': slotTime,
  });

  Future<void> onCafeSlotSoldOut({
    required String cafeId,
    required String slotTime,
  }) async => logEvent('Cafe Slot Sold Out', {
    'cafe_id': cafeId,
    'slot_time': slotTime,
  });

  Future<void> onCafeAlmostFull({
    required String cafeId,
    required int availableSlots,
  }) async => logEvent('Cafe Almost Full', {
    'cafe_id': cafeId,
    'available_slots': availableSlots,
  });

  Future<void> onCafeFullyBooked({required String cafeId}) async =>
      logEvent('Cafe Fully Booked', {'cafe_id': cafeId});

  // Campaign + notification actions
  Future<void> onCampaignClicked({
    required String campaignId,
    required String source,
  }) async => logEvent('Campaign Clicked', {
    'campaign_id': campaignId,
    'source': source,
  });

  Future<void> onCampaignDismissed({required String campaignId}) async =>
      logEvent('Campaign Dismissed', {'campaign_id': campaignId});

  Future<void> onCampaignExpired({required String campaignId}) async =>
      logEvent('Campaign Expired', {'campaign_id': campaignId});

  Future<void> onNotificationDismissed({
    required String notificationId,
  }) async =>
      logEvent('Notification Dismissed', {'notification_id': notificationId});

  Future<void> onNotificationIgnored({required String notificationId}) async =>
      logEvent('Notification Ignored', {'notification_id': notificationId});

  Future<void> onNotificationActionTaken({
    required String notificationId,
    required String action,
  }) async => logEvent('Notification Action Taken', {
    'notification_id': notificationId,
    'action': action,
  });
}
