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
  static String get bookingsBaseUrl => '$bookingBaseUrl/api/bookings';
  static String get confirmBooking => '$bookingBaseUrl/api/bookings/confirm';
  static String get vendorGames => '$bookingBaseUrl/api/games/vendor';
  static String get createOffer => '$bookingBaseUrl/api/redeem-voucher';

  // Vendor Service
  static String get vendorBaseUrl => FlavorConfig.getBaseUrl('vendor');
  static String get getAllVendorsList =>
      '$vendorBaseUrl/api/vendor/getAllGamingCafe';

  // Dashboard Service
  static String get dashboardBaseUrl => FlavorConfig.getBaseUrl('dashboard');
  // Add dashboard endpoints as needed, e.g.:
  // static String get dashboardStats => '$dashboardBaseUrl/api/stats';

  // News related endpoints (external, not flavored)
  static const String gameSpotBaseUrl = 'https://www.gamespot.com/api';
  static const String gameSpotArticles = '$gameSpotBaseUrl/articles';

  // Payment related constants
  static String get razorpayKey => FlavorConfig.isProduction()
      ? 'rzp_test_viVAhwtbVdu1X4:PsxakTrbRvfQCbZ1vj2lQ1i5' // Replace with your live key
      : 'rzp_test_viVAhwtbVdu1X4:PsxakTrbRvfQCbZ1vj2lQ1i5';

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
  // Get Voucher (userOnboard)
  static String get getVoucher =>
      '$userOnboardBaseUrl/api/users/{userId}/voucher';

  // Get HashCoin For a User By User ID (userOnboard)
  static String get getHashCoin =>
      '$userOnboardBaseUrl/api/users/{userId}/hash-coins';
}
