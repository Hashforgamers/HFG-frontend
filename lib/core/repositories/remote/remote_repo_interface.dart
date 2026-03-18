import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';
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
  Future<List<Map<String, dynamic>>> fetchSlots({
    required int vendorId,
    required int gameId,
    required String date,
  });

  Future<Map<String, dynamic>> createBooking({
    required int slotId,
    required int gameId,
  });
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
    Map<String, dynamic>? squadDetails,
    int? suggestedExtraControllerQty,
  });

  Future<Map<String, dynamic>> fetchBookingPricingEstimate({
    required int vendorId,
    required int gameId,
    required String consoleType,
    required bool squadEnabled,
    required int playerCount,
    int? suggestedExtraControllerQty,
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
  Future<Map<String, dynamic>> fetchWallet({required String userId});
  Future<Map<String, dynamic>> addFunds({
    required String userId,
    required int amount,
    required String paymentId,
  });
  Future<void> claimDropCrateBonus({required String userId, int amount});

  Future<Map<String, dynamic>> validateFunds(String paymentLinkId);
  Future<void> saveReferralCodeToPreferences(String referralCode);

  Future<void> createVoucher({required String userId});
  Future<List<GetVoucherModel>> getVoucher({required String userId});

  Future<int> getHashCoin();
  Future<int> addHashCoins({
    required int amount,
    String? source,
    String? referenceId,
  });

  Future<CreateVoucherResponse> createOffer({required int discountPercentage});

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

  Future<Map<String, dynamic>> createCafeReview({
    required int vendorId,
    required int bookingId,
    required int rating,
    String? title,
    String? comment,
    bool? isAnonymous,
  });

  Future<Map<String, dynamic>> updateCafeReview({
    required int reviewId,
    int? rating,
    String? title,
    String? comment,
    bool? isAnonymous,
  });

  Future<List<Map<String, dynamic>>> fetchVendorReviews({
    required int vendorId,
    int limit = 20,
    int offset = 0,
    int? rating,
    String sort = 'recent',
  });

  Future<Map<String, dynamic>> fetchVendorReviewsSummary({
    required int vendorId,
  });

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

  Future<List<TransactionHistoryModel>> getTransactionHistory({
    required String userId,
  });

  Future<void> capturePayment({
    required CapturePaymentModel capturePaymentModel,
  });
  Future<String> createRazorpayOrder({
    required int amountInPaisa,
    String? receiptPrefix,
  });
  Future<Map<String, dynamic>> addMealsToBooking({
    required String bookingId,
    required List<Map<String, dynamic>> meals,
    bool settleOnRelease = true,
    String? modeOfPayment,
  });

  Future<void> saveUIDToPreferences(String uid);
  Future<String> getUIDFromPreferences();

  Future<List<GetVendorPassesModel>> getAllAvailablePasses({
    required String vendorId,
  });
  Future<String> makePurchasePassPayment({
    required PurchasePassModel purchasePassModel,
  });

  Future<List<Map<String, dynamic>>> fetchPublicEvents();
  Future<Map<String, dynamic>> fetchEventById({required String eventId});
  Future<List<Map<String, dynamic>>> fetchEventLeaderboard({
    required String eventId,
  });
  Future<Map<String, dynamic>> createEventTeam({
    required String eventId,
    required int userId,
    required String teamName,
    required bool isIndividual,
  });
  Future<Map<String, dynamic>> joinEventTeam({
    required String eventId,
    required String teamId,
    required int userId,
  });
  Future<Map<String, dynamic>> leaveEventTeam({
    required String eventId,
    required String teamId,
    required int userId,
  });
  Future<Map<String, dynamic>> registerEventTeam({
    required String eventId,
    required int userId,
    required String teamId,
  });
  Future<List<Map<String, dynamic>>> fetchEventTeamMembers({
    required String eventId,
    required String teamId,
  });
  Future<List<Map<String, dynamic>>> fetchUserTeams({required int userId});
  Future<Map<String, List<Map<String, dynamic>>>> fetchJoinedTournaments({
    required int userId,
  });
  Future<Map<String, dynamic>> updateEventTeam({
    required String eventId,
    required String teamId,
    required String teamName,
  });
  Future<Map<String, dynamic>> addEventTeamMember({
    required String eventId,
    required String teamId,
    required int userId,
  });
  Future<Map<String, dynamic>> forceRemoveEventTeamMember({
    required String eventId,
    required String teamId,
    required int actingUserId,
    required int targetUserId,
  });
  Future<Map<String, dynamic>> inviteUserToEventTeam({
    required String eventId,
    required String teamId,
    required int inviterUserId,
    required int invitedUserId,
  });
  Future<Map<String, dynamic>> respondToEventTeamInvite({
    required String eventId,
    required String teamId,
    required String inviteId,
    required int userId,
    required String action,
  });
  Future<Map<String, dynamic>> fetchUserNotifications({
    int limit = 50,
    bool unreadOnly = false,
  });
  Future<Map<String, dynamic>> markNotificationAsRead({
    required String notificationId,
  });
}
