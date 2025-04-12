import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingController extends GetxController {
  final isLoading = false.obs;
  final slots = <Map<String, dynamic>>[].obs; // Holds fetched slots
  final userBookings = <Map<String, dynamic>>[].obs; // Holds user bookings
  final userId = 0.obs; // Holds user ID
  final selectedSlots = RxMap<int, List<int>>({}); // Holds selected slots per PC

  final String _baseUrl = 'https://hfg-booking-service.onrender.com/api'; // Base URL for API

  @override
  void onInit() {
  super.onInit();
  fetchUserId().then((_) => fetchUserBookings()); // Fetch bookings after fetching user ID
  }

  Future<void> fetchSlots(int gameId) async {
    _setLoading(true);
    final url = Uri.parse('$_baseUrl/slots/game/$gameId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final slotList = (data['slots'] as List)
            .map((slot) => slot as Map<String, dynamic>)
            .toList();
        slots.assignAll(slotList);
      } else {
        _logError('Failed to fetch slots. Status code: ${response.statusCode}');
        slots.clear();
      }
    } catch (e) {
      _logError('Error fetching slots: $e');
      slots.clear();
    } finally {
      _setLoading(false);
    }
  }


  /// Create a booking
  Future<Map<String, dynamic>> createBooking({
    required int slotId,
    required int userId,
    required int gameId,
  }) async {
    _setLoading(true);
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
        return {"success": false, "message": "Failed to create booking. Status code: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch user ID from local storage
  Future<void> fetchUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        userId.value = userData['id'] ?? 0;
        print('User ID: ${userId.value}');
      } else {
        _logError('User data not found in preferences!');
      }
    } catch (e) {
      _logError('Error fetching user ID: $e');
      Get.snackbar(
        'Error',
        'Unable to fetch user data. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Fetch bookings for a specific user
  Future<void> fetchUserBookings() async {
    if (userId.value == 0) return; // Skip if user ID is not set
    _setLoading(true);
    final url = Uri.parse('$_baseUrl/users/${userId.value}/bookings');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        userBookings.assignAll(data.map((e) => e as Map<String, dynamic>).toList());
      } else {
        _logError('Failed to fetch bookings. Status code: ${response.statusCode}');
        userBookings.clear();
      }
    } catch (e) {
      _logError('Error fetching bookings: $e');
      userBookings.clear();
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool value) {
    isLoading.value = value;
  }

  /// Log errors
  void _logError(String message) {
    print(message);
  }
}
