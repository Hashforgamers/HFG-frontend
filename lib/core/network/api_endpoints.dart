import 'package:hash/config/flavor_config.dart';

class ApiEndpoints {
  // User Onboard Service
  static String get userOnboardBaseUrl =>
      FlavorConfig.getBaseUrl('userOnboard');
  static String get baseUrl => '$userOnboardBaseUrl/api/users';
  static String get checkUserExistsInAPI =>
      '$userOnboardBaseUrl/api/users/fid/';
  static String get signUp => '$userOnboardBaseUrl/api/users';

  // Booking Service
  static String get bookingBaseUrl => FlavorConfig.getBaseUrl('booking');
  static String get slotsBaseUrl => '$bookingBaseUrl/api';
  static String get bookingsBaseUrl => '$bookingBaseUrl/api';
  static String get confirmBooking => '$bookingBaseUrl/api/bookings/confirm';
  static String get vendorGames => '$bookingBaseUrl/api/games/vendor';
  static String get createOffer => '$bookingBaseUrl/api/redeem-voucher';

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
      ? 'rzp_live_RmxaTWJdsdl8yy' // Replace with your live key
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
  static String get wallet => '$userOnboardBaseUrl/api/users/wallet';
  static String get addFunds =>
      '$userOnboardBaseUrl/api/users/wallet/add-funds';
  static String get validateFunds =>
      '$userOnboardBaseUrl/api/users/wallet/validate-funds';

  // Creating voucher (userOnboard)
  static String get createVoucher =>
      '$userOnboardBaseUrl/api/users/{userId}/create-voucher';

  static String registerFCMToken(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/register-fcm-token';

  // Get Voucher (userOnboard)
  static String get getVoucher =>
      '$userOnboardBaseUrl/api/users/{userId}/voucher';

  // Get HashCoin For a User By User ID (userOnboard)
  static String get getHashCoin =>
      '$userOnboardBaseUrl/api/users/{userId}/hash-coins';

  // Wallet core endpoints (dynamic by userId)
  static String walletByUserId(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/wallet';

  static String addFundsByUserId(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/wallet';

  static String validateFundsByUserId(String userId) =>
      '$userOnboardBaseUrl/api/users/$userId/wallet/validate';

  static String get releaseBooking => '$bookingBaseUrl/api/release_slot';

  // HFG Game Pass
  static String gamePass(String userId) =>
      '$userOnboardBaseUrl/api/user/$userId/available_passes';
  // Get PAss Details
  static String getGamePassDetails(String cafeId) =>
      '$userOnboardBaseUrl/api/passes/$cafeId';

  // Get Active passes for the user
  static String getActivePasses(String userId) =>
      '$userOnboardBaseUrl/api/user/$userId/passes';

  // Get Food Categories
  static String getFoodCategories(String vendorId) =>
      '$userOnboardBaseUrl/api/vendor/$vendorId/extras/categories';

  // Get Food Items
  static String getFoodItems(String vendorId, String categoryId) =>
      '$userOnboardBaseUrl/api/vendor/$vendorId/extras/category/$categoryId/menus';

  // Get Extra Service
  static String getExtraService(String vendorId) =>
      '$userOnboardBaseUrl/api/vendor/$vendorId/extraService';
}
