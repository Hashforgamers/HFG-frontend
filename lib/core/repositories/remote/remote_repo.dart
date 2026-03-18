import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/api_error_handler.dart';
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
import 'package:hash/core/service/device_identifier_service.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/utils/encrypt_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class RemoteRepo implements RemoteRepoInterface {
  final NetworkProvider networkProvider;
  final DeviceIdentifierService? deviceIdentifierService;

  RemoteRepo({required this.networkProvider, this.deviceIdentifierService});

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
      final headers =
          await deviceIdentifierService?.buildRequestHeaders() ??
          const <String, String>{};
      final response = await dio.post(
        ApiEndpoints.signUp,
        data: userData,
        options: headers.isEmpty ? null : Options(headers: headers),
      );

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

  Future<Map<String, dynamic>> deleteUser() async {
    final dio = await networkProvider
        .auth(); // must attach Authorization header (Bearer <jwt>)
    try {
      // If your API expects /api/users/{id}, switch endpoint to: '${ApiEndpoints.baseUrl}/$userId'
      final response = await dio.delete(
        ApiEndpoints
            .baseUrl, // DELETE /api/users  -> delete current authenticated user
        options: Options(
          // treat 4xx (except 5xx) as handled so we can show API message
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          "success": true,
          "message": (response.data is Map && response.data['message'] != null)
              ? response.data['message']
              : "Account deleted successfully",
        };
      }

      // Handle common auth/client errors with useful messages
      final data = response.data;
      final serverMsg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : "Failed to delete account. Status code: ${response.statusCode}";
      return {"success": false, "message": serverMsg};
    } on DioException catch (e) {
      // Let retry interceptor handle retryable errors
      if (ApiErrorHandler.shouldRetry(e)) rethrow;

      final msg = ApiErrorHandler.extractErrorMessage(e);
      return {"success": false, "message": msg};
    } catch (e) {
      return {"success": false, "message": "Unexpected error: $e"};
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
        final bookings = data.map((e) => e as Map<String, dynamic>).toList();

        if (bookings.isNotEmpty) {
          final rawUserId =
              bookings.first['user_id'] ?? bookings.first['userId'];
          final userId = rawUserId?.toString().trim() ?? '';
          if (userId.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', userId);
          }
        }

        return bookings;
      } else {
        throw Exception(
          'Failed to fetch bookings. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        // If it's a retryable error, let the intercep
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
        final vendors = List<Map<String, dynamic>>.from(data['vendors']);
        for (final vendor in vendors) {
          AppLogger.d(
            'Vendor amenities debug -> vendor_id=${vendor['vendor_id']}, cafe_name=${vendor['cafe_name']}, amenities=${vendor['amenities']}',
          );
        }
        return vendors;
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
    // Dashboard vendor-games drives UI cards, booking service ids drive slot API.
    final dashboardDio = await networkProvider.auth();
    final bookingDio = networkProvider.noAuth();
    try {
      final response = await dashboardDio.get(
        ApiEndpoints.vendorGamesByVendorId('$vendorId'),
      );

      final Map<String, int> bookingGameIdByPlatform = {};
      bool? legacyShopOpen;
      final List<Map<String, dynamic>> legacyGamesForFallback = [];
      try {
        final legacyResponse = await bookingDio.get(
          '${ApiEndpoints.vendorGames}/$vendorId',
        );
        if (legacyResponse.statusCode == 200 && legacyResponse.data is Map) {
          legacyShopOpen = _parseLooseBool(
            legacyResponse.data['shop_open'] ??
                legacyResponse.data['is_open'] ??
                legacyResponse.data['open_close_flag'],
          );
          final legacyGames =
              (legacyResponse.data['games'] as List?) ?? const [];
          for (final item in legacyGames) {
            if (item is! Map) continue;
            final map = Map<String, dynamic>.from(item);
            legacyGamesForFallback.add(map);
            final id = map['id'];
            if (id is! num) continue;
            final rawPlatform =
                (map['game_name'] ??
                        map['game_platform'] ??
                        map['platform_type'] ??
                        '')
                    .toString();
            final normalizedPlatform = _normalizePlatform(rawPlatform);
            if (normalizedPlatform.isEmpty) continue;
            bookingGameIdByPlatform[normalizedPlatform] = id.toInt();
          }
        }
      } catch (e) {
        debugPrint('Legacy booking game mapping unavailable: $e');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];

        // Normalize dashboard data for optional enrichment, but prefer legacy
        // booking inventory when present because it carries the actual
        // booking ids, console type, and total_slots semantics used by the UI.
        final dashboardGames = data.map<Map<String, dynamic>>((item) {
          final game = (item is Map ? item['game'] : null) ?? {};
          final consoles = (item is Map ? item['consoles'] : []) ?? [];

          final normalizedConsoles = <Map<String, dynamic>>[];
          if (consoles is List) {
            for (final c in consoles) {
              if (c is! Map) continue;
              final console = Map<String, dynamic>.from(c);
              final consoleType = _normalizePlatform(
                (console['console_type'] ?? console['consoleType'] ?? '')
                    .toString(),
              );
              final bookingGameId = bookingGameIdByPlatform[consoleType];
              if (bookingGameId != null) {
                console['booking_game_id'] = bookingGameId;
              }
              normalizedConsoles.add(console);
            }
          }

          final fallbackPlatform = normalizedConsoles.isNotEmpty
              ? (normalizedConsoles.first['console_type'] ??
                        normalizedConsoles.first['consoleType'] ??
                        game['platform'] ??
                        '')
                    .toString()
              : (game['platform'] ?? '').toString();
          final gameBookingId =
              bookingGameIdByPlatform[_normalizePlatform(fallbackPlatform)];

          double? derivedPrice;
          if (item is Map && item['avg_price'] != null) {
            derivedPrice = (item['avg_price'] as num).toDouble();
          } else if (normalizedConsoles.isNotEmpty) {
            final first = normalizedConsoles.first;
            if (first['price_per_hour'] != null) {
              derivedPrice = (first['price_per_hour'] as num).toDouble();
            }
          }

          return {
            'game_name': game['name'] ?? game['title'],
            'game_platform': game['platform'],
            'genre': game['genre'],
            'image_url': game['image_url'],
            'total_slots': item is Map ? item['total_consoles'] ?? 0 : 0,
            'single_slot_price': derivedPrice ?? 0,
            'booking_game_id': gameBookingId,
            'consoles': normalizedConsoles,
          };
        }).toList();

        final normalizedGames = <Map<String, dynamic>>[];

        if (legacyGamesForFallback.isNotEmpty) {
          final dashboardByPlatform = <String, Map<String, dynamic>>{};
          for (final dashboardGame in dashboardGames) {
            final platform = _normalizePlatform(
              (dashboardGame['game_platform'] ??
                      dashboardGame['game_name'] ??
                      '')
                  .toString(),
            );
            if (platform.isEmpty || dashboardByPlatform.containsKey(platform)) {
              continue;
            }
            dashboardByPlatform[platform] = dashboardGame;
          }

          for (final legacy in legacyGamesForFallback) {
            final platform =
                (legacy['game_platform'] ??
                        legacy['platform_type'] ??
                        legacy['game_name'] ??
                        '')
                    .toString();
            final normalizedPlatform = _normalizePlatform(platform);
            final bookingId = legacy['id'];
            if (bookingId is! num) continue;
            final dashboardMatch = dashboardByPlatform[normalizedPlatform];
            normalizedGames.add({
              'game_name': (legacy['game_name'] ?? normalizedPlatform)
                  .toString(),
              'game_platform': platform,
              'genre': (dashboardMatch?['genre'] ?? legacy['genre'] ?? '')
                  .toString(),
              'image_url':
                  (dashboardMatch?['image_url'] ?? legacy['image_url'] ?? '')
                      .toString(),
              'total_slots': legacy['total_slots'] ?? 1,
              'single_slot_price': (legacy['single_slot_price'] is num)
                  ? (legacy['single_slot_price'] as num).toDouble()
                  : 0.0,
              'booking_game_id': bookingId.toInt(),
              'consoles': <Map<String, dynamic>>[],
            });
          }
        } else {
          normalizedGames.addAll(dashboardGames);
        }

        final bool? dashboardShopOpen = response.data is Map<String, dynamic>
            ? _parseLooseBool(
                response.data['shop_open'] ??
                    response.data['is_open'] ??
                    response.data['open_close_flag'],
              )
            : null;

        return {
          'games': normalizedGames,
          'shop_open': legacyShopOpen ?? dashboardShopOpen,
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

  String _normalizePlatform(String value) {
    final v = value.toLowerCase().trim();
    if (v.isEmpty) return '';
    if (v.contains('ps') || v.contains('playstation')) return 'ps5';
    if (v.contains('xbox')) return 'xbox';
    if (v.contains('vr') || v.contains('virtual')) return 'vr';
    return 'pc';
  }

  bool? _parseLooseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'open') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'closed') {
        return false;
      }
    }
    return null;
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
    Map<String, dynamic>? squadDetails,
    int? suggestedExtraControllerQty,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final Map<String, dynamic> requestData = {
        "booking_id": bookingIds,
        "payment_id": paymentId,
        "book_date": bookDate,
        "payment_mode": paymentMode,
      };

      if (isGamePass) {
        requestData["use_pass"] = true;
        if (userPassId != null && userPassId.trim().isNotEmpty) {
          requestData["user_pass_id"] = userPassId.trim();
        }
      }

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

      if (squadDetails != null && squadDetails.isNotEmpty) {
        requestData["squad_details"] = squadDetails;
        requestData["squadDetails"] = squadDetails;
        final playerCount = squadDetails["player_count"];
        if (playerCount is num) {
          requestData["playerCount"] = playerCount.toInt();
        }
      }

      if (suggestedExtraControllerQty != null) {
        requestData["suggestedExtraControllerQty"] =
            suggestedExtraControllerQty < 0 ? 0 : suggestedExtraControllerQty;
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
    } on DioException catch (e) {
      if (ApiErrorHandler.shouldRetry(e)) {
        rethrow;
      }
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      print('Error confirming booking: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchBookingPricingEstimate({
    required int vendorId,
    required int gameId,
    required String consoleType,
    required bool squadEnabled,
    required int playerCount,
    int? suggestedExtraControllerQty,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final queryParameters = <String, dynamic>{
        "vendor_id": vendorId,
        "game_id": gameId,
        "consoleType": consoleType,
        "squadEnabled": squadEnabled,
        "playerCount": playerCount,
      };
      if (suggestedExtraControllerQty != null) {
        queryParameters["suggestedExtraControllerQty"] =
            suggestedExtraControllerQty < 0 ? 0 : suggestedExtraControllerQty;
      }

      final response = await dio.get(
        ApiEndpoints.bookingPricingEstimate,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return Map<String, dynamic>.from(response.data as Map);
      }

      throw Exception(
        'Failed to fetch pricing estimate. Status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      if (ApiErrorHandler.shouldRetry(e)) {
        rethrow;
      }
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error fetching pricing estimate: $e');
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
  Future<void> claimDropCrateBonus({
    required String userId,
    int amount = 30,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        '${ApiEndpoints.baseUrl}/wallet',
        data: {
          "amount": amount,
          "reference_id": "drop_crate_${DateTime.now().millisecondsSinceEpoch}",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Drop Crate bonus claimed successfully.");
      } else {
        final err = response.data;
        throw Exception(
          (err is Map && err.containsKey('error'))
              ? err['error']
              : 'Failed to claim drop crate bonus',
        );
      }
    } catch (e) {
      debugPrint("❌ Error claiming drop crate bonus: $e");
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
  Future<int> addHashCoins({
    required int amount,
    String? source,
    String? referenceId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.getHashCoin,
        data: {
          'amount': amount,
          'source': source ?? 'external_cafe_like',
          'reference_id':
              referenceId ??
              'external_cafe_like_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final hashCoins = data['hash_coins'] ?? data['total_hash_coins'];
          if (hashCoins is int) return hashCoins;
          if (hashCoins is num) return hashCoins.toInt();
        }
        return amount;
      }

      throw Exception(
        'Failed to add hash coins. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error adding hash coins: $e');
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
      debugPrint(
        'scanQrCode request -> console_id=$consoleId, game_id=$gameId, vendor_id=$vendorId, booking_id=$bookingId',
      );
      final response = await dio.post(
        ApiEndpoints.scanQrCode,
        data: {
          'console_id': consoleId,
          'game_id': gameId,
          'vendor_id': vendorId,
          'booking_id': bookingId,
        },
      );
      debugPrint(
        'scanQrCode response -> status=${response.statusCode}, body=${response.data}',
      );
      final responseData = response.data;
      final statusCode = response.statusCode ?? 0;

      String? successMessage;
      String? errorMessage;

      if (responseData is Map<String, dynamic>) {
        final rawMessage = responseData['message']?.toString().trim() ?? '';
        final rawError = responseData['error']?.toString().trim() ?? '';
        if (rawMessage.isNotEmpty) successMessage = rawMessage;
        if (rawError.isNotEmpty) errorMessage = rawError;
      } else if (responseData is List && responseData.isNotEmpty) {
        final first = responseData.first;
        if (first is Map<String, dynamic>) {
          final rawMessage = first['message']?.toString().trim() ?? '';
          final rawError = first['error']?.toString().trim() ?? '';
          if (rawMessage.isNotEmpty) successMessage = rawMessage;
          if (rawError.isNotEmpty) errorMessage = rawError;
        } else if (first is Map) {
          final map = Map<String, dynamic>.from(first);
          final rawMessage = map['message']?.toString().trim() ?? '';
          final rawError = map['error']?.toString().trim() ?? '';
          if (rawMessage.isNotEmpty) successMessage = rawMessage;
          if (rawError.isNotEmpty) errorMessage = rawError;
        }
      }

      if (statusCode >= 200 && statusCode < 300 && errorMessage == null) {
        return successMessage ?? 'QR scanned successfully.';
      }

      final resolvedError = errorMessage ?? 'Failed to scan QR code.';
      debugPrint('scanQrCode resolved error -> $resolvedError');
      throw Exception(resolvedError);
    } catch (e) {
      // Handle DioException specifically to extract error message
      if (e is DioException && e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        debugPrint(
          'scanQrCode DioException -> status=$statusCode, body=$responseData, error=${e.message}',
        );

        if (statusCode == 400) {
          // Extract error message from response data
          String errorMessage = 'Failed to scan QR code.';
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          } else if (responseData is List && responseData.isNotEmpty) {
            final first = responseData.first;
            if (first is Map && first['error'] != null) {
              errorMessage = first['error'].toString();
            }
          }
          debugPrint('scanQrCode 400 error -> $errorMessage');
          throw Exception(errorMessage);
        } else {
          debugPrint('scanQrCode unexpected status -> $statusCode');
          throw Exception('Failed to scan QR code. Status code: $statusCode');
        }
      }

      debugPrint('scanQrCode unexpected exception -> $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createCafeReview({
    required int vendorId,
    required int bookingId,
    required int rating,
    String? title,
    String? comment,
    bool? isAnonymous,
  }) async {
    final dio = await networkProvider.auth();
    final url = ApiEndpoints.createReview;
    final payload = <String, dynamic>{
      'vendor_id': vendorId,
      'booking_id': bookingId,
      'rating': rating,
      if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
      if ((comment ?? '').trim().isNotEmpty) 'comment': comment!.trim(),
      if (isAnonymous != null) 'is_anonymous': isAnonymous,
    };

    try {
      debugPrint('createCafeReview request -> url=$url, body=$payload');
      final response = await dio.post(
        url,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        debugPrint(
          'createCafeReview success -> url=$url, status=${response.statusCode}, response=$body',
        );
        if (body is Map) {
          return Map<String, dynamic>.from(body);
        }
        throw Exception('Invalid review create response format.');
      }
      debugPrint(
        'createCafeReview failed -> url=$url, status=${response.statusCode}, body=$payload, response=${response.data}',
      );
      throw Exception(
        'Failed to create review. Status code: ${response.statusCode}',
      );
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          'createCafeReview DioException -> url=$url, status=${e.response?.statusCode}, body=$payload, response=${e.response?.data}, message=${e.message}',
        );
      }
      debugPrint('Error creating cafe review: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateCafeReview({
    required int reviewId,
    int? rating,
    String? title,
    String? comment,
    bool? isAnonymous,
  }) async {
    final dio = await networkProvider.auth();
    final url = ApiEndpoints.updateReview(reviewId.toString());
    final payload = <String, dynamic>{
      if (rating != null) 'rating': rating,
      if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
      if ((comment ?? '').trim().isNotEmpty) 'comment': comment!.trim(),
      if (isAnonymous != null) 'is_anonymous': isAnonymous,
    };

    try {
      debugPrint(
        'updateCafeReview request -> url=$url, reviewId=$reviewId, body=$payload',
      );
      final response = await dio.patch(
        url,
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
      if (response.statusCode == 200) {
        final body = response.data;
        debugPrint(
          'updateCafeReview success -> url=$url, reviewId=$reviewId, status=${response.statusCode}, response=$body',
        );
        if (body is Map) {
          return Map<String, dynamic>.from(body);
        }
        throw Exception('Invalid review update response format.');
      }
      debugPrint(
        'updateCafeReview failed -> url=$url, reviewId=$reviewId, status=${response.statusCode}, body=$payload, response=${response.data}',
      );
      throw Exception(
        'Failed to update review. Status code: ${response.statusCode}',
      );
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          'updateCafeReview DioException -> url=$url, reviewId=$reviewId, status=${e.response?.statusCode}, body=$payload, response=${e.response?.data}, message=${e.message}',
        );
      }
      debugPrint('Error updating cafe review: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVendorReviews({
    required int vendorId,
    int limit = 20,
    int offset = 0,
    int? rating,
    String sort = 'recent',
  }) async {
    final dio = networkProvider.noAuth();
    final safeLimit = limit.clamp(1, 100);
    final safeSort = sort.trim().toLowerCase() == 'top' ? 'top' : 'recent';
    try {
      final response = await dio.get(
        ApiEndpoints.vendorReviews(
          vendorId.toString(),
          limit: safeLimit,
          offset: offset,
          rating: rating,
          sort: safeSort,
        ),
      );
      if (response.statusCode == 200) {
        final body = response.data;
        final items = body is Map<String, dynamic> ? body['items'] : null;
        if (items is List) {
          return items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const [];
      }
      throw Exception(
        'Failed to fetch vendor reviews. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error fetching vendor reviews: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchVendorReviewsSummary({
    required int vendorId,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.get(
        ApiEndpoints.vendorReviewsSummary(vendorId.toString()),
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception(
        'Failed to fetch review summary. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error fetching review summary: $e');
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

  @override
  Future<String> createRazorpayOrder({
    required int amountInPaisa,
    String? receiptPrefix,
  }) async {
    final dio = networkProvider.noAuth();
    final receiptBase = (receiptPrefix ?? 'order_rcpt').trim();
    final payload = {
      'amount': amountInPaisa,
      'currency': 'INR',
      'receipt': '${receiptBase}_${DateTime.now().millisecondsSinceEpoch}',
    };

    try {
      final response = await dio.post(
        ApiEndpoints.createPaymentOrder,
        data: payload,
      );
      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        final orderId = (data['id'] ?? '').toString().trim();
        if (orderId.isNotEmpty) {
          return orderId;
        }
      }
      throw Exception(
        'Failed to create payment order. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error creating payment order: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> addMealsToBooking({
    required String bookingId,
    required List<Map<String, dynamic>> meals,
    bool settleOnRelease = true,
    String? modeOfPayment,
  }) async {
    final dio = await networkProvider.auth();
    final payload = <String, dynamic>{
      'meals': meals,
      'settle_on_release': settleOnRelease,
    };
    final normalizedPaymentMode = modeOfPayment?.trim();
    if (normalizedPaymentMode != null && normalizedPaymentMode.isNotEmpty) {
      payload['mode_of_payment'] = normalizedPaymentMode;
    }

    try {
      final response = await dio.post(
        ApiEndpoints.addMealsToBooking(bookingId),
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'message': response.data?.toString() ?? 'Meal order added.'};
      }
      throw Exception(
        'Failed to add meals to booking. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error adding meals to booking: $e');
      rethrow;
    }
  }

  @override
  Future<String> getUIDFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid') ?? '';
  }

  @override
  Future<void> saveUIDToPreferences(String uid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
  }

  @override
  Future<List<GetVendorPassesModel>> getAllAvailablePasses({
    required String vendorId,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.get(
        ApiEndpoints.getAllAvailablePasses(vendorId),
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data['passes'];
        return responseData
            .map((e) => GetVendorPassesModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to get vendor passes. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting vendor passes: $e');
      rethrow;
    }
  }

  @override
  Future<String> makePurchasePassPayment({
    required PurchasePassModel purchasePassModel,
  }) async {
    final dio = networkProvider.noAuth();
    try {
      final response = await dio.post(
        ApiEndpoints.purchasePass,
        data: purchasePassModel.toJson(),
      );
      if (response.statusCode == 201) {
        return response.data['payment_id'] as String;
      } else {
        throw Exception(
          'Failed to make purchase pass payment. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error making purchase pass payment: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPublicEvents() async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.eventsPublic);
      if (response.statusCode == 200) {
        return _extractDynamicList(
          response.data,
          candidateKeys: const ['events', 'data', 'results', 'items'],
        );
      }
      throw Exception(
        'Failed to fetch events. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error fetching public events: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchEventById({required String eventId}) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.eventById(eventId));
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          if (map['event'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(map['event'] as Map);
          }
          if (map['data'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(map['data'] as Map);
          }
          return map;
        }
        throw Exception('Unexpected event response format');
      }
      throw Exception(
        'Failed to fetch event details. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error fetching event details: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEventLeaderboard({
    required String eventId,
  }) async {
    final dio = await networkProvider.auth();
    final endpoint = ApiEndpoints.eventLeaderboard(eventId);
    try {
      final response = await dio.get(endpoint);
      if (response.statusCode == 200) {
        return _extractDynamicList(
          response.data,
          candidateKeys: const ['leaderboard', 'teams', 'data', 'results'],
        );
      }
      AppLogger.e(
        'Leaderboard API non-200 | eventId=$eventId | status=${response.statusCode} | endpoint=$endpoint | body=${response.data}',
      );
      throw Exception(
        'Failed to fetch leaderboard. Status code: ${response.statusCode}',
      );
    } on DioException catch (e, st) {
      AppLogger.e(
        'Leaderboard API DioException | eventId=$eventId | endpoint=$endpoint | status=${e.response?.statusCode} | data=${e.response?.data}',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        'Leaderboard API unexpected error | eventId=$eventId | endpoint=$endpoint',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createEventTeam({
    required String eventId,
    required int userId,
    required String teamName,
    required bool isIndividual,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.eventTeams(eventId),
        data: {
          'user_id': userId,
          'name': teamName,
          'is_individual': isIndividual,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to create team. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error creating event team: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> joinEventTeam({
    required String eventId,
    required String teamId,
    required int userId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.eventTeamJoin(eventId, teamId),
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to join team. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error joining event team: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> leaveEventTeam({
    required String eventId,
    required String teamId,
    required int userId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.delete(
        ApiEndpoints.eventTeamLeave(eventId, teamId),
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to leave team. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error leaving event team: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> registerEventTeam({
    required String eventId,
    required int userId,
    required String teamId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.eventRegister(eventId),
        data: {'user_id': userId, 'team_id': teamId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to register team. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error registering event team: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEventTeamMembers({
    required String eventId,
    required String teamId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(
        ApiEndpoints.eventTeamMembers(eventId, teamId),
      );
      if (response.statusCode == 200) {
        return _extractDynamicList(
          response.data,
          candidateKeys: const ['members', 'users', 'team_members', 'data'],
        );
      }
      throw Exception(
        'Failed to fetch team members. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error fetching event team members: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserTeams({
    required int userId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(ApiEndpoints.userTeams(userId));
      if (response.statusCode == 200) {
        return _extractDynamicList(
          response.data,
          candidateKeys: const ['teams', 'data', 'results', 'items'],
        );
      }
      throw Exception(
        'Failed to fetch user teams. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error fetching user teams: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> fetchJoinedTournaments({
    required int userId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(
        ApiEndpoints.userJoinedTournaments(userId),
      );
      if (response.statusCode == 200) {
        final payload = _asMap(response.data);
        List<Map<String, dynamic>> extract(List<String> keys) {
          dynamic raw;
          for (final key in keys) {
            if (payload.containsKey(key)) {
              raw = payload[key];
              break;
            }
          }
          if (raw is List) {
            return raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          return const <Map<String, dynamic>>[];
        }

        final live = extract(const ['live', 'Live']);
        final upcoming = extract(const ['upcoming', 'Upcoming']);
        final completed = extract(const ['completed', 'Completed']);
        final directAll = extract(const ['all', 'All', 'joined']);

        final mergedAll = directAll.isNotEmpty
            ? directAll
            : [...live, ...upcoming, ...completed];

        final dedupedAll = <String, Map<String, dynamic>>{};
        for (final item in mergedAll) {
          final id = (item['id'] ?? item['event_id'] ?? '').toString().trim();
          final key = id.isNotEmpty ? id : item.toString();
          dedupedAll[key] = item;
        }

        return {
          'all': dedupedAll.values.toList(),
          'live': live,
          'upcoming': upcoming,
          'completed': completed,
        };
      }
      throw Exception(
        'Failed to fetch joined tournaments. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error fetching joined tournaments: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updateEventTeam({
    required String eventId,
    required String teamId,
    required String teamName,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.patch(
        ApiEndpoints.eventTeam(eventId, teamId),
        data: {'name': teamName},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to update team. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error updating event team: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> addEventTeamMember({
    required String eventId,
    required String teamId,
    required int userId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.eventTeamMembers(eventId, teamId),
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to add team member. Status code: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error adding event team member: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> forceRemoveEventTeamMember({
    required String eventId,
    required String teamId,
    required int actingUserId,
    required int targetUserId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.delete(
        ApiEndpoints.eventTeamForceRemoveMember(eventId, teamId, targetUserId),
        data: {'user_id': actingUserId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to remove team member. Status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioMessage(e, fallback: 'Unable to remove member from team.'),
      );
    } catch (e) {
      debugPrint('Error force removing event team member: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> inviteUserToEventTeam({
    required String eventId,
    required String teamId,
    required int inviterUserId,
    required int invitedUserId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.eventTeamInvite(eventId, teamId),
        data: {
          'inviter_user_id': inviterUserId,
          'invited_user_id': invitedUserId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to invite user. Status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioMessage(e, fallback: 'Unable to invite user.'),
      );
    } catch (e) {
      debugPrint('Error inviting user to team: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> respondToEventTeamInvite({
    required String eventId,
    required String teamId,
    required String inviteId,
    required int userId,
    required String action,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.post(
        ApiEndpoints.eventTeamInviteRespond(eventId, teamId, inviteId),
        data: {'user_id': userId, 'action': action},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to respond to invite. Status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioMessage(e, fallback: 'Unable to process invite response.'),
      );
    } catch (e) {
      debugPrint('Error responding to event invite: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchUserNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.get(
        ApiEndpoints.userNotifications(limit: limit, unreadOnly: unreadOnly),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to fetch notifications. Status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioMessage(e, fallback: 'Unable to fetch notifications.'),
      );
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> markNotificationAsRead({
    required String notificationId,
  }) async {
    final dio = await networkProvider.auth();
    try {
      final response = await dio.patch(
        ApiEndpoints.markNotificationRead(notificationId),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _asMap(response.data);
      }
      throw Exception(
        'Failed to mark notification as read. Status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioMessage(e, fallback: 'Unable to mark notification as read.'),
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {'data': value};
  }

  List<Map<String, dynamic>> _extractDynamicList(
    dynamic payload, {
    required List<String> candidateKeys,
  }) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (payload is Map) {
      for (final key in candidateKeys) {
        final value = payload[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }

    return const <Map<String, dynamic>>[];
  }

  String _extractDioMessage(DioException error, {required String fallback}) {
    if (ApiErrorHandler.shouldRetry(error)) {
      return fallback;
    }
    final responseData = error.response?.data;
    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      final message =
          map['message']?.toString().trim() ??
          map['error']?.toString().trim() ??
          map['detail']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    final parsed = ApiErrorHandler.extractErrorMessage(error).trim();
    return parsed.isEmpty ? fallback : parsed;
  }
}
