class ApiEndpoints {
  static const String baseUrl =
      'https://hfg-user-onboard-3nzn.onrender.com/api/users';

  static const String checkUserExistsInAPI =
      'https://hfg-user-onboard-3nzn.onrender.com/api/users/fid/';

  static const String signUp =
      'https://hfg-user-onboard-3nzn.onrender.com/api/users';

  // Booking related endpoints
  static const String slotsBaseUrl =
      'https://hfg-booking-hmnx.onrender.com/api';
  static const String bookingsBaseUrl =
      'https://hfg-booking-hmnx.onrender.com/api';
  static const String confirmBooking =
      'https://hfg-booking-hmnx.onrender.com/api/bookings/confirm';

  // Vendor related endpoints
  static const String getAllVendorsList =
      'https://hfg-onboard-hqqb.onrender.com/api/vendor/getAllGamingCafe';
  static const String vendorGames =
      'https://hfg-booking-hmnx.onrender.com/api/games/vendor';

  // News related endpoints
  static const String gameSpotBaseUrl = 'https://www.gamespot.com/api';
  static const String gameSpotArticles = '$gameSpotBaseUrl/articles';

  // Payment related constants
  static const String razorpayKey = 'rzp_test_viVAhwtbVdu1X4';

  // Address related endpoints
  static const String addresses = '$baseUrl/checkout/addresses';
  static const String activeAddress = '$baseUrl/checkout/address/active';
  static const String addAddress = '$baseUrl/checkout/address';

  // Cart related endpoints
  static const String cartBaseUrl = '$baseUrl/cart';
  static const String cartItem = '$cartBaseUrl/item';

  // Checkout related endpoints
  static const String checkoutOther = '$baseUrl/checkout/other';
  static const String validatePayment = '$baseUrl/checkout/pay/validate';

  // Products related endpoints
  static const String products = '$baseUrl/products';
  static const String productById = '$baseUrl/product';

  // Wallet related endpoints
  static const String wallet = '$baseUrl/wallet';
  static const String addFunds = '$wallet/add-funds';
  static const String validateFunds = '$wallet/validate-funds';

  // Creating voucher
  static const String createVoucher = '$baseUrl/{userId}/create-voucher';
  // Get Voucher
  static const String getVoucher = '$baseUrl/{userId}/voucher';

  // Get HashCoin For a User By User ID
  static const String getHashCoin = '$baseUrl/{userId}/hash-coins';

  // Create offer using HashCoins
  static const String createOffer = 'https://hfg-booking-hmnx.onrender.com/api/redeem-voucher';

}
