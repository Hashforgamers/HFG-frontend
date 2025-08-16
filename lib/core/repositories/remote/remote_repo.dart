import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/error_handler.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/model/booking_model.dart';
import 'package:hash/core/repositories/model/capture_payment_model.dart';
import 'package:hash/core/repositories/model/create_voucher_response.dart';
import 'package:hash/core/repositories/model/extra_services_model.dart';
import 'package:hash/core/repositories/model/get_food_menu_model.dart';
import 'package:hash/core/repositories/model/get_pass_model.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';
import 'package:hash/core/repositories/model/purchase_pass_model.dart';
import 'package:hash/core/repositories/model/transaction_history_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/utils/encrypt_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class RemoteRepo implements RemoteRepoInterface {
  final NetworkProvider networkProvider;

  RemoteRepo({required this.networkProvider});

  @override
  Future<Map<String, dynamic>?> checkUserExistsInAPI(String fid) async {
    final dio = networkProvider.noAuth();

    try {
      final response = await dio.get(ApiEndpoints.checkUserExistsInAPI + fid);

      if (response.statusCode == 200) {
        // Dio already decodes the response data, so we don't need jsonDecode
        final Map<String, dynamic> responseBody = response.data;
        // get the JWT from the authorization Header
        final jwtToken = extractJwtFromResponse(response);
        // decode the JWT
        final decodedJwt = decodeJwtAndGetUid(jwtToken ?? '');
        // decrypt the JWT with private key
        final decryptedData = await decryptData(decodedJwt ?? '');
        // now enctypt it with the public key and make the jwt
        final encryptedData = await encryptData(decryptedData);
        // now create the jwt with the encrypted data
        final jwtEncoded = createJwtWithExpiry(
          encryptedUuid: encryptedData,
          expiryInSeconds: 3600 * 5,
          secretKey: 'dev',
        );
        // store the jwt in the preferences
        await saveJwtToPreferences(jwtEncoded);

        final Map<String, dynamic>? userData = responseBody['user'];
        final Map<String, dynamic>? userReferralData =
            responseBody['referralCode'];
        if (userReferralData != null) {
          await saveReferralCodeToPreferences(userReferralData['referralCode']);
        }

        if (userData != null) {
          // Save user data to preferences when found
          await saveUserToPreferences(userData);
          return userData;
        }
      }
      return null;
    } catch (e) {
      print('Error checking user existence: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> signUp(Map<String, dynamic> userData) async {
    final dio = networkProvider.noAuth();

    try {
      final response = await dio.post(ApiEndpoints.signUp, data: userData);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseBody = response.data;
        // Save user data to preferences after successful signup
        await saveUserToPreferences(responseBody['user']);
        return responseBody;
      } else {
        throw Exception(
          'Signup failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Handle DioException specifically
      if (e is DioException) {
        // If it's a retryable error, let the interceptor handle it
        if (ApiErrorHandler.shouldRetry(e)) {
          rethrow; // Let the retry interceptor handle it
        }

        // For non-retryable errors, extract and throw user-friendly message
        final errorMessage = ApiErrorHandler.extractErrorMessage(e);
        throw Exception(errorMessage);
      }
      print('Error during signup: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveUserToPreferences(Map<String, dynamic> userData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
    print('User data saved to preferences.');
  }

  @override
  Future<Map<String, dynamic>?> getUserFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> clearUserFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    print('User data cleared from preferences.');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSlots({
    required int vendorId,
    required int gameId,
    required String date,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.get(
        '${ApiEndpoints.slotsBaseUrl}/getSlots/vendor/$vendorId/game/$gameId/$date',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return (data['slots'] as List)
            .map((slot) => slot as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
          'Failed to fetch slots. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching slots: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createBooking({
    required int slotId,
    required int gameId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        '${ApiEndpoints.bookingsBaseUrl}/bookings',
        data: {"slot_id": slotId, "game_id": gameId},
      );

      if (response.statusCode == 201) {
        return {"success": true, "data": response.data};
      } else {
        return {
          "success": false,
          "message":
              "Failed to create booking. Status code: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserBookings() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(
        '${ApiEndpoints.bookingsBaseUrl}/users/bookings',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception(
          'Failed to fetch bookings. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        // If it's a retryable error, let the interceptor handle it
        if (ApiErrorHandler.shouldRetry(e)) {
          rethrow; // Let the retry interceptor handle it
        }

        // For non-retryable errors, extract and throw user-friendly message
        final errorMessage = ApiErrorHandler.extractErrorMessage(e);
        throw Exception(errorMessage);
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCybercafes() async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.get(ApiEndpoints.getAllVendorsList);

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['vendors']);
      } else {
        throw Exception(
          'Failed to fetch cybercafes. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching cybercafes: $e');
      if (e is DioException) {
        // If it's a retryable error, let the interceptor handle it
        if (ApiErrorHandler.shouldRetry(e)) {
          rethrow; // Let the retry interceptor handle it
        }

        // For non-retryable errors, extract and throw user-friendly message
        final errorMessage = ApiErrorHandler.extractErrorMessage(e);
        throw Exception(errorMessage);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchVendorGames(int vendorId) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.get('${ApiEndpoints.vendorGames}/$vendorId');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'games': List<Map<String, dynamic>>.from(data['games'] ?? []),
          'shop_open': data['shop_open'] ?? false,
        };
      } else {
        throw Exception(
          'Failed to fetch vendor games. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching vendor games: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGameNews({int limit = 10}) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.get(
        ApiEndpoints.gameSpotArticles,
        queryParameters: {
          'api_key': '78d76a751c4c6f512c25e16443178fa911653e93',
          'format': 'json',
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        throw Exception(
          'Failed to fetch game news. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching game news: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> confirmBooking({
    required List<int> bookingIds,
    required String paymentId,
    required String bookDate,
    required String paymentMode, // ✅ ADD THIS
    String? voucherCode,
    bool isGamePass = false,
    List<ExtraServiceItem>? extraServices,
    String? userPassId,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final Map<String, dynamic> requestData = {
        "booking_id": bookingIds,
        "payment_id": paymentId,
        "book_date": bookDate,
        "payment_mode": paymentMode,
        "use_pass": isGamePass,
        "user_pass_id": userPassId,
      };

      // Add voucher code if provided
      if (voucherCode != null && voucherCode.isNotEmpty) {
        requestData["voucher_code"] = voucherCode;
      }

      // Add extra services if provided
      if (extraServices != null && extraServices.isNotEmpty) {
        requestData["extra_services"] = extraServices
            .map((item) => item.toJson())
            .toList();
      }

      final response = await dio.post(
        ApiEndpoints.confirmBooking,
        data: requestData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to confirm booking. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error confirming booking: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.addresses);

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['addresses']);
      } else {
        throw Exception(
          'Failed to fetch addresses. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching addresses: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchActiveAddress() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.activeAddress);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch active address. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching active address: $e');
      rethrow;
    }
  }

  @override
  Future<void> addAddress(Map<String, dynamic> address) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(ApiEndpoints.addAddress, data: address);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to add address. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error adding address: $e');
      rethrow;
    }
  }

  // Cart related methods
  @override
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.cartBaseUrl,
        data: {"product_id": productId, "quantity": quantity},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to add to cart. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCart() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.cartBaseUrl);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        final List<dynamic> items = responseData['items'];
        return items.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
          'Failed to fetch cart. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching cart: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCartItem(String productId) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.delete('${ApiEndpoints.cartItem}/$productId');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete item from cart. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error deleting cart item: $e');
      rethrow;
    }
  }

  // Checkout related methods
  @override
  Future<Map<String, dynamic>> initiateCheckout() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(
        ApiEndpoints.checkoutOther,
        options: Options(followRedirects: true),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to initiate checkout. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error initiating checkout: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> validateTransaction(String paymentLinkId) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.validatePayment,
        options: Options(
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
        data: {
          "payment_link_ids": [paymentLinkId],
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to validate transaction. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error validating transaction: $e');
      rethrow;
    }
  }

  // Products related methods
  @override
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.products);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception(
          'Failed to fetch products. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProductById(String productId) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get('${ApiEndpoints.productById}/$productId');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch product. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching product by ID: $e');
      rethrow;
    }
  }

  // Wallet related methods
  @override
  Future<Map<String, dynamic>> fetchWallet({required String userId}) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.wallet());

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to fetch wallet data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching wallet: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> addFunds({
    required String userId,
    required String paymentId,
    required int amount,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.wallet(),
        data: {'amount': amount, 'reference_id': paymentId},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to add funds. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error adding funds: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> validateFunds(String paymentLinkId) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.validateFunds,
        data: {
          'payment_link_ids': [paymentLinkId],
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(
          'Failed to validate funds. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error validating funds: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveReferralCodeToPreferences(String referralCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('referralCode', referralCode);
  }

  @override
  Future<void> createVoucher({required String userId}) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(ApiEndpoints.createVoucher);
      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 400) {
        final responseData = response.data;
        String errorMessage = 'Failed to create voucher.';
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('error')) {
          errorMessage = responseData['error'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle DioException specifically to extract error message
      if (e is DioException && e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        if (statusCode == 400) {
          // Extract error message from response data
          String errorMessage = 'Failed to create voucher.';
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          }
          throw Exception(errorMessage);
        } else {
          throw Exception('Failed to create voucher. Status code: $statusCode');
        }
      }

      rethrow;
    }
  }

  @override
  Future<List<GetVoucherModel>> getVoucher({required String userId}) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.getVoucher);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;

        // The API returns {"vouchers": [...]}, so we need to extract the vouchers array
        if (responseData.containsKey('vouchers')) {
          // Create a single GetVoucherModel with all vouchers
          return [GetVoucherModel.fromJson(responseData)];
        } else {
          // If no vouchers field, return empty list
          return [];
        }
      } else {
        throw Exception(
          'Failed to get voucher. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting voucher: $e');
      rethrow;
    }
  }

  @override
  Future<int> getHashCoin() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.getHashCoin);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        // Handle null case by returning 0 if hash_coin is null
        final hashCoin = responseData['hash_coins'];
        return hashCoin is int ? hashCoin : 0;
      } else {
        throw Exception(
          'Failed to get hash coin. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting hash coin: $e');
      rethrow;
    }
  }

  @override
  Future<CreateVoucherResponse> createOffer({
    required int discountPercentage,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.createOffer,
        data: {'discount_percentage': discountPercentage},
      );
      if (response.statusCode == 200) {
        return CreateVoucherResponse.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to create offer. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error creating offer: $e');
      rethrow;
    }
  }

  @override
  Future<String> scanQrCode({
    required String consoleId,
    required String gameId,
    required String vendorId,
    required String bookingId,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.post(
        ApiEndpoints.scanQrCode,
        data: {
          'console_id': consoleId,
          'game_id': gameId,
          'vendor_id': vendorId,
          'booking_id': bookingId,
        },
      );
      if (response.statusCode == 201) {
        return response.data['message'];
      } else {
        // Handle non-201 status codes
        final responseData = response.data;
        String errorMessage = 'Failed to scan QR code.';
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('error')) {
          errorMessage = responseData['error'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle DioException specifically to extract error message
      if (e is DioException && e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        if (statusCode == 400) {
          // Extract error message from response data
          String errorMessage = 'Failed to scan QR code.';
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          }
          throw Exception(errorMessage);
        } else {
          throw Exception('Failed to scan QR code. Status code: $statusCode');
        }
      }

      rethrow;
    }
  }

  @override
  Future<String> registerFCMToken({
    required String userId,
    required String token,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.registerFCMToken,
        data: {
          "token": token,
          "platform": Platform.isAndroid ? "android" : "ios",
        },
      );
      if (response.statusCode == 200) {
        return response.data['message'];
      } else {
        throw Exception(
          'Failed to register FCM token. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      rethrow;
    }
  }

  @override
  Future<String> releaseBooking({required BookingModel bookings}) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.post(
        ApiEndpoints.releaseBooking,
        data: {'bookings': bookings},
      );
      if (response.statusCode == 200) {
        return response.data['message'];
      } else {
        throw Exception(
          'Failed to release booking. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error releasing booking: $e');
      rethrow;
    }
  }

  @override
  Future<List<GetPassModel>> getGamePass({
    required String userId,
    required String type,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(
        ApiEndpoints.gamePass,
        queryParameters: {'type': type},
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data;
        return responseData
            .map((e) => GetPassModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to get game pass. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting game pass: $e');
      rethrow;
    }
  }

  @override
  Future<List<GetPassModel>> getUserActiveGamePass({
    required String userId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.getActivePasses);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data;
        return responseData
            .map((e) => GetPassModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to get game pass. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting game pass: $e');
      rethrow;
    }
  }

  @override
  Future<GetFoodMenuModel> getFoodMenu({required String vendorId}) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.get(ApiEndpoints.getExtraService(vendorId));
      if (response.statusCode == 200) {
        final responseData = response.data;
        return GetFoodMenuModel.fromJson(responseData as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to get food menu. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting food menu: $e');
      rethrow;
    }
  }

  @override
  Future<String> purchasePass({
    required String userId,
    required PurchasePassModel passModel,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.purchasePass,
        data: passModel.toJson(),
      );
      if (response.statusCode == 200) {
        return response.data['message'];
      } else {
        throw Exception(
          'Failed to purchase pass. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error purchasing pass: $e');
      rethrow;
    }
  }

  @override
  Future<List<TransactionHistoryModel>> getTransactionHistory({
    required String userId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.getTransactionHistory);
      if (response.statusCode == 200) {
        // Check if response.data is a Map and contains 'transactions'
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('transactions')) {
          final List<dynamic> responseData = response.data['transactions'];
          return responseData
              .map(
                (e) =>
                    TransactionHistoryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        } else if (response.data is List) {
          // If response.data is directly a list of transactions
          final List<dynamic> responseData = response.data;
          return responseData
              .map(
                (e) =>
                    TransactionHistoryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw Exception(
            'Invalid response format. Expected transactions array.',
          );
        }
      } else {
        throw Exception(
          'Failed to get transaction history. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveJwtToPreferences(String jwt) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', jwt);
  }

  @override
  Future<String?> getJwtFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  @override
  Future<void> capturePayment({
    required CapturePaymentModel capturePaymentModel,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.post(
        ApiEndpoints.capturePayment,
        data: capturePaymentModel.toJson(),
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(
          'Failed to capture payment. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error capturing payment: $e');
      rethrow;
    }
  }
}
