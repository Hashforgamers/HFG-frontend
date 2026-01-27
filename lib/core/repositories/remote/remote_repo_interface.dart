import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';
import 'package:hash/app/modules/user_pass/model/redeem_pass_request_model.dart';
import 'package:hash/app/modules/user_pass/model/redeem_pass_response_model.dart';
import 'package:hash/app/modules/user_pass/model/user_gaming_pass_model.dart';
import 'package:hash/app/modules/user_pass/model/validate_pass_request_model.dart';
import 'package:hash/app/modules/user_pass/model/validate_pass_response_model.dart';
import 'package:hash/core/repositories/model/booking_model.dart';
import 'package:hash/core/repositories/model/capture_payment_model.dart';
import 'package:hash/core/repositories/model/create_voucher_response.dart';
import 'package:hash/core/repositories/model/extra_services_model.dart';
import 'package:hash/core/repositories/model/get_food_menu_model.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';
import 'package:hash/core/repositories/model/purchase_pass_model.dart';
import 'package:hash/core/repositories/model/transaction_history_model.dart';

abstract class RemoteRepoInterface {
  Future<Map<String, dynamic>?> checkUserExistsInAPI(String fid);
  Future<void> saveUserToPreferences(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserFromPreferences();
  Future<void> clearUserFromPreferences();
  Future<void> saveJwtToPreferences(String jwt);
  Future<String?> getJwtFromPreferences();
  Future<Map<String, dynamic>> signUp(Map<String, dynamic> userData);

  // Booking related methods
  Future<List<Map<String, dynamic>>> fetchSlots({required int vendorId, required int gameId, required String date});

  Future<Map<String, dynamic>> createBooking({required int slotId, required int gameId});
  Future<Map<String, dynamic>> deleteUser();

  Future<List<Map<String, dynamic>>> fetchUserBookings();

  // Vendor related methods
  Future<List<Map<String, dynamic>>> fetchCybercafes();
  Future<Map<String, dynamic>> fetchVendorGames(int vendorId);

  // News related methods
  Future<List<Map<String, dynamic>>> fetchGameNews({int limit = 10});

  // Payment related methods
  Future<Map<String, dynamic>> confirmBooking({
    required List<int> bookingIds,
    required String paymentId,
    required String bookDate,
    String? voucherCode,
    required String paymentMode,
    bool isGamePass = false,
    List<ExtraServiceItem>? extraServices,
    String? userPassId,
  });

  // Address related methods
  Future<List<Map<String, dynamic>>> fetchAddresses();
  Future<Map<String, dynamic>> fetchActiveAddress();
  Future<void> addAddress(Map<String, dynamic> address);

  // Cart related methods
  Future<Map<String, dynamic>> addToCart({required String productId, required int quantity});

  Future<List<Map<String, dynamic>>> fetchCart();

  Future<void> deleteCartItem(String productId);

  // Checkout related methods
  Future<Map<String, dynamic>> initiateCheckout();
  Future<Map<String, dynamic>> validateTransaction(String paymentLinkId);

  // Products related methods
  Future<List<Map<String, dynamic>>> fetchProducts();
  Future<Map<String, dynamic>> fetchProductById(String productId);

  // Wallet related methods
  Future<Map<String, dynamic>> fetchWallet({required String userId});
  Future<Map<String, dynamic>> addFunds({required String userId, required int amount, required String paymentId});
  Future<void> claimDropCrateBonus({required String userId, int amount});

  Future<Map<String, dynamic>> validateFunds(String paymentLinkId);
  Future<void> saveReferralCodeToPreferences(String referralCode);

  Future<void> createVoucher({required String userId});
  Future<List<GetVoucherModel>> getVoucher({required String userId});

  Future<int> getHashCoin();

  Future<CreateVoucherResponse> createOffer({required int discountPercentage});

  Future<String> scanQrCode({required String consoleId, required String gameId, required String vendorId, required String bookingId});

  Future<String> registerFCMToken({required String userId, required String token});

  Future<String> releaseBooking({required BookingModel bookings});

  Future<List<GetPassModel>> getGamePass({required String userId, required String type});

  Future<List<GetPassModel>> getUserActiveGamePass({required String userId});

  Future<GetFoodMenuModel> getFoodMenu({required String vendorId});

  Future<String> purchasePass({required String userId, required PurchasePassModel passModel});

  Future<List<TransactionHistoryModel>> getTransactionHistory({required String userId});

  Future<void> capturePayment({required CapturePaymentModel capturePaymentModel});

  Future<void> saveUIDToPreferences(String uid);
  Future<String> getUIDFromPreferences();

  Future<List<GetVendorPassesModel>> getAllAvailablePasses({required String vendorId});
  Future<String> makePurchasePassPayment({required PurchasePassModel purchasePassModel});

  //User Pass Management
  Future<List<UserGamingPassModel>> getUserActiveGamePasses(String? vendorId);
  // Pass Validate
  Future<ValidatePassResponseModel> validateUserPass({required ValidatePassRequest validatePassRequest});
  // Pass Redeem
  Future<RedeemPassResponseModel> redeemUserPass({required RedeemPassRequestModel redeemPassRequestModel});
}
