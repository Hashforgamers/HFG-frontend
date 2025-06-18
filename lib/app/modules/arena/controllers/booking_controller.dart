import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingController extends GetxController {
  final isLoading = false.obs;
  final slots = <Map<String, dynamic>>[].obs;
  final userBookings = <Map<String, dynamic>>[].obs;
  final userId = 0.obs;
  final selectedSlots = RxMap<int, List<int>>({});
  final errorMessage = ''.obs;

  static const String _baseUrl = 'https://hfg-booking-hmnx.onrender.com/api';
  
  // Cache management
  final Map<String, dynamic> _slotsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidity = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    fetchUserId().then((_) => fetchUserBookings());
  }

  Future<void> fetchSlots({
    required int vendorId,
    required int gameId,
    required String date,
  }) async {
    final cacheKey = 'slots_${vendorId}_${gameId}_$date';
    
    if (_isCacheValid(cacheKey)) {
      slots.assignAll(_slotsCache[cacheKey]);
      return;
    }

    _setLoading(true);
    errorMessage.value = '';
    
    final url = Uri.parse('$_baseUrl/getSlots/vendor/$vendorId/game/$gameId/$date');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final slotList = (data['slots'] as List)
            .map((slot) => slot as Map<String, dynamic>)
            .toList();
        
        _slotsCache[cacheKey] = slotList;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        slots.assignAll(slotList);
      } else {
        _handleError('Failed to fetch slots');
        slots.clear();
      }
    } catch (e) {
      _handleError('Error fetching slots');
      slots.clear();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required int slotId,
    required int userId,
    required int gameId,
  }) async {
    _setLoading(true);
    errorMessage.value = '';
    
    final url = Uri.parse('$_baseUrl/bookings');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "slot_id": slotId,
          "user_id": userId,
          "game_id": gameId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": "Failed to create booking"};
      }
    } catch (e) {
      return {"success": false, "message": "Error creating booking"};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        userId.value = userData['id'] ?? 0;
      } else {
        _handleError('User data not found');
      }
    } catch (e) {
      _handleError('Error fetching user ID');
    }
  }

  Future<void> fetchUserBookings() async {
    if (userId.value == 0) return;
    
    _setLoading(true);
    errorMessage.value = '';
    
    final url = Uri.parse('$_baseUrl/users/${userId.value}/bookings');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        userBookings.assignAll(data.map((e) => e as Map<String, dynamic>).toList());
      } else {
        _handleError('Failed to fetch bookings');
        userBookings.clear();
      }
    } catch (e) {
      _handleError('Error fetching bookings');
      userBookings.clear();
    } finally {
      _setLoading(false);
    }
  }

  bool _isCacheValid(String key) {
    if (!_slotsCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheValidity;
  }

  void _handleError(String message) {
    errorMessage.value = message;
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  void _setLoading(bool value) {
    isLoading.value = value;
  }
}
