import 'package:hash/config/flavor_config.dart';

class ApiEndpoints {
  // User Onboard Service
  static String get userOnboardBaseUrl =>
      FlavorConfig.getBaseUrl('userOnboard');
  static String get baseUrl => '$userOnboardBaseUrl/api/users';
  static String get checkUserExistsInAPI =>
      '$userOnboardBaseUrl/api/users/fid/';
  static String get signUp => '$userOnboardBaseUrl/api/users';
  static String get registeredPhoneStatus =>
      '$userOnboardBaseUrl/api/users/phone/registered';
  static String get registeredPhone => '$userOnboardBaseUrl/api/users/phone';

  // Booking Service
  static String get bookingBaseUrl => FlavorConfig.getBaseUrl('booking');
  static String get slotsBaseUrl => '$bookingBaseUrl/api';
  static String get bookingsBaseUrl => '$bookingBaseUrl/api';
  static String get confirmBooking => '$bookingBaseUrl/api/bookings/confirm';
  static String get bookingPricingEstimate =>
      '$bookingBaseUrl/api/bookings/pricing-estimate';
  static String get vendorGames => '$bookingBaseUrl/api/games/vendor';
  static String vendorGamesByVendorId(String vendorId) =>
      '$dashboardBaseUrl/vendor/$vendorId/vendor-games';
  static String get createOffer => '$bookingBaseUrl/api/redeem-voucher';

  static String get capturePayment => '$bookingBaseUrl/api/capture_payment';
  static String get createPaymentOrder => '$bookingBaseUrl/api/create_order';
  static String addMealsToBooking(String bookingId) =>
      '$bookingBaseUrl/api/booking/$bookingId/add-meals';

  // Pass Purchase (HMNX Booking API)
  static const String passBaseUrl = 'https://hfg-booking-hmnx.onrender.com/api';
  static String getAllAvailablePasses(
    String vendorId, {
    bool includeInactive = false,
  }) =>
      '$dashboardBaseUrl/api/vendor/$vendorId/passes'
      '?include_inactive=$includeInactive';

  // Purchase Pass Endpoint
  static String get purchasePassNew => '$bookingBaseUrl/api/passes/purchase';

  // Vendor Service
  static String get vendorBaseUrl => FlavorConfig.getBaseUrl('vendor');
  static String get getAllVendorsList =>
      '$vendorBaseUrl/api/vendor/getAllGamingCafe';
  static String get scanQrCode => '$vendorBaseUrl/api/bookingQueue';

  // Dashboard Service
  static String get dashboardBaseUrl => FlavorConfig.getBaseUrl('dashboard');
  // Add dashboard endpoints as needed, e.g.:
  // static String get dashboardStats => '$dashboardBaseUrl/api/stats';

  // News related endpoints (external, not flavored)
  static const String gameSpotBaseUrl = 'https://www.gamespot.com/api';
  static const String gameSpotArticles = '$gameSpotBaseUrl/articles';

  // Payment related constants
  // TODO:- Remove this and use the new API to get the Order ID and then use that Order ID to create the payment order
  static String get razorpayKeyWallet => FlavorConfig.isProduction()
      ? 'rzp_live_RmxaTWJdsdl8yy'
      // ?'rzp_test_viVAhwtbVdu1X4'
      : 'rzp_test_viVAhwtbVdu1X4';

  // Address related endpoints (userOnboard)
  static String get addresses =>
      '$userOnboardBaseUrl/api/users/checkout/addresses';
  static String get activeAddress =>
      '$userOnboardBaseUrl/api/users/checkout/address/active';
  static String get addAddress =>
      '$userOnboardBaseUrl/api/users/checkout/address';

  // Cart related endpoints (userOnboard)
  static String get cartBaseUrl => '$userOnboardBaseUrl/api/users/cart';
  static String get cartItem => '$userOnboardBaseUrl/api/users/cart/item';

  // Checkout related endpoints (userOnboard)
  static String get checkoutOther =>
      '$userOnboardBaseUrl/api/users/checkout/other';
  static String get validatePayment =>
      '$userOnboardBaseUrl/api/users/checkout/pay/validate';

  // Products related endpoints (userOnboard)
  static String get products => '$userOnboardBaseUrl/api/users/products';
  static String get productById => '$userOnboardBaseUrl/api/users/product';

  // Wallet related endpoints (userOnboard)
  static String wallet() => '$userOnboardBaseUrl/api/users/wallet';
  static String addFunds(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/wallet/add-funds';
  static String get validateFunds =>
      '$userOnboardBaseUrl/api/users/wallet/validate-funds';

  // Creating voucher (userOnboard)
  static String get createVoucher =>
      '$userOnboardBaseUrl/api/users/create-voucher';

  static String get registerFCMToken =>
      '$userOnboardBaseUrl/api/users/register-fcm-token';

  // Get Voucher (userOnboard)
  static String get getVoucher => '$userOnboardBaseUrl/api/users/voucher';

  // Get HashCoin For a User By User ID (userOnboard)
  static String get getHashCoin => '$userOnboardBaseUrl/api/users/hash-coins';

  // Wallet core endpoints (dynamic by userId)
  static String walletByUserId(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/wallet';

  static String addFundsByUserId(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/wallet';

  static String validateFundsByUserId(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/wallet/validate';

  static String get releaseBooking => '$bookingBaseUrl/api/release_slot';

  // HFG Game Pass
  static String get gamePass => '$userOnboardBaseUrl/api/user/available_passes';
  // Get PAss Details
  static String getGamePassDetails(String cafeId) =>
      '$userOnboardBaseUrl/api/passes/$cafeId';

  // Purchase Pass Endpoint
  static String get purchasePass =>
      '$userOnboardBaseUrl/api/user/purchase_pass';

  // Get Active passes for the user
  static String get getActivePasses => '$userOnboardBaseUrl/api/user/passes';

  // Get Food Categories
  static String getFoodCategories(String vendorId) =>
      '$userOnboardBaseUrl/api/vendor/$vendorId/extras/categories';

  // Get Food Items
  static String getFoodItems(String vendorId, String categoryId) =>
      '$userOnboardBaseUrl/api/vendor/$vendorId/extras/category/$categoryId/menus';

  // Get Extra Service
  static String getExtraService(String vendorId) =>
      '$userOnboardBaseUrl/api/vendor/$vendorId/extraService';

  // Reviews
  static String get createReview => '$userOnboardBaseUrl/api/reviews';
  static String updateReview(String reviewId) =>
      '$userOnboardBaseUrl/api/reviews/$reviewId';
  static String vendorReviews(
    String vendorId, {
    int limit = 20,
    int offset = 0,
    int? rating,
    String sort = 'recent',
  }) {
    final ratingQuery = rating == null ? '' : '&rating=$rating';
    return '$userOnboardBaseUrl/api/vendors/$vendorId/reviews?limit=$limit&offset=$offset&sort=$sort$ratingQuery';
  }

  static String vendorReviewsSummary(String vendorId) =>
      '$userOnboardBaseUrl/api/vendors/$vendorId/reviews/summary';

  // Get Transaction History
  static String get getTransactionHistory =>
      '$userOnboardBaseUrl/api/users/transactions';

  // Tournament / Events
  static String get eventsPublic => '$userOnboardBaseUrl/api/events/public';
  static String eventById(String eventId) =>
      '$userOnboardBaseUrl/api/events/$eventId';
  static String eventTeams(String eventId) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams';
  static String eventRegister(String eventId) =>
      '$userOnboardBaseUrl/api/events/$eventId/register';
  static String eventTeamJoin(String eventId, String teamId) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams/$teamId/join';
  static String eventTeamLeave(String eventId, String teamId) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams/$teamId/leave';
  static String eventTeamMembers(String eventId, String teamId) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams/$teamId/members';
  static String eventTeamForceRemoveMember(
    String eventId,
    String teamId,
    int targetUserId,
  ) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams/$teamId/members/$targetUserId/force-remove';
  static String eventTeamInvite(String eventId, String teamId) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams/$teamId/invite';
  static String eventTeamInviteRespond(
    String eventId,
    String teamId,
    String inviteId,
  ) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams/$teamId/invites/$inviteId/respond';
  static String eventTeam(String eventId, String teamId) =>
      '$userOnboardBaseUrl/api/events/$eventId/teams/$teamId';
  static String eventLeaderboard(String eventId) =>
      '$userOnboardBaseUrl/api/events/$eventId/leaderboard';
  static String userNotifications({int limit = 50, bool unreadOnly = false}) =>
      '$userOnboardBaseUrl/api/users/notifications?limit=$limit&unread_only=$unreadOnly';
  static String markNotificationRead(String notificationId) =>
      '$userOnboardBaseUrl/api/users/notifications/$notificationId/read';
  static String userTeams(int userId) =>
      '$userOnboardBaseUrl/api/users/$userId/teams';
  static String userJoinedTournaments(int userId) =>
      '$userOnboardBaseUrl/api/users/$userId/tournaments/joined';
  static String get userSearch => '$userOnboardBaseUrl/api/users/search';
}
