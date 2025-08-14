import 'package:hash/core/repositories/model/booking_model.dart';
import 'package:hash/core/repositories/model/create_voucher_response.dart';
import 'package:hash/core/repositories/model/extra_services_model.dart';
import 'package:hash/core/repositories/model/get_food_menu_model.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';
import 'package:hash/core/repositories/model/purchase_pass_model.dart';

abstract class RemoteRepoInterface {
  Future<Map<String, dynamic>?> checkUserExistsInAPI(String fid);
  Future<void> saveUserToPreferences(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserFromPreferences();
  Future<void> clearUserFromPreferences();
  Future<Map<String, dynamic>> signUp(Map<String, dynamic> userData);

  // Booking related methods
  Future<List<Map<String, dynamic>>> fetchSlots({
    required int vendorId,
    required int gameId,
    required String date,
  });

  Future<Map<String, dynamic>> createBooking({
    required int slotId,
    required int userId,
    required int gameId,
  });

  Future<List<Map<String, dynamic>>> fetchUserBookings(int userId);

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
  });

  // Address related methods
  Future<List<Map<String, dynamic>>> fetchAddresses();
  Future<Map<String, dynamic>> fetchActiveAddress();
  Future<void> addAddress(Map<String, dynamic> address);

  // Cart related methods
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  });

  Future<List<Map<String, dynamic>>> fetchCart();

  Future<void> deleteCartItem(String productId);

  // Checkout related methods
  Future<Map<String, dynamic>> initiateCheckout();
  Future<Map<String, dynamic>> validateTransaction(String paymentLinkId);

  // Products related methods
  Future<List<Map<String, dynamic>>> fetchProducts();
  Future<Map<String, dynamic>> fetchProductById(String productId);

  // Wallet related methods
  Future<Map<String, dynamic>> fetchWallet();
  Future<Map<String, dynamic>> addFunds({
    required double amount,
    required String description,
    required String name,
    required String contact,
    required String emailId,
  });
  Future<Map<String, dynamic>> validateFunds(String paymentLinkId);
  Future<void> saveReferralCodeToPreferences(String referralCode);

  Future<void> createVoucher({required String userId});
  Future<List<GetVoucherModel>> getVoucher({required String userId});

  Future<int> getHashCoin({required String userId});

  Future<CreateVoucherResponse> createOffer({
    required int discountPercentage,
    required String userId,
  });

  Future<String> scanQrCode({
    required String consoleId,
    required String gameId,
    required String vendorId,
    required String bookingId,
  });

  Future<String> registerFCMToken({
    required String userId,
    required String token,
  });

  Future<String> releaseBooking({required BookingModel bookings});

  Future<List<GetPassModel>> getGamePass({
    required String userId,
    required String type,
  });

  Future<List<GetPassModel>> getUserActiveGamePass({required String userId});

  Future<GetFoodMenuModel> getFoodMenu({required String vendorId});

  Future<String> purchasePass({
    required String userId,
    required PurchasePassModel passModel,
  });
}
