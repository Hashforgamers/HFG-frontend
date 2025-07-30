import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class BookingController extends GetxController {
  final isLoading = false.obs;
  final slots = <Map<String, dynamic>>[].obs; // Holds fetched slots
  final userBookings = <Map<String, dynamic>>[].obs; // Holds user bookings
  final userId = 0.obs; // Holds user ID
  final selectedSlots =
      RxMap<int, List<int>>({}); // Holds selected slots per PC

  final _remoteRepo = locator<RemoteRepoInterface>();

  @override
  void onInit() {
    super.onInit();
    fetchUserId().then(
        (_) => fetchUserBookings()); // Fetch bookings after fetching user ID
  }

  /// Clear all selected slots
  void clearSelectedSlots() {
    selectedSlots.clear();
  }

  /// Check if a slot is available based on current time
  bool isSlotAvailableNow(Map<String, dynamic> slot) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Parse slot start time
      final startTimeStr = slot['start_time'] ?? '';
      final startTimeParts = startTimeStr.split(':');
      if (startTimeParts.length < 2) {
        return true; // If can't parse, assume available
      }

      final startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      final slotStartTime =
          today.add(Duration(hours: startHour, minutes: startMinute));

      // Add a buffer of 15 minutes - slots within 15 minutes of current time are not available
      final bufferTime = now.add(const Duration(minutes: 15));

      // If slot start time is in the past or within buffer time, it's not available
      if (slotStartTime.isBefore(bufferTime)) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking slot availability: $e');
      return true; // Default to available if error
    }
  }

  Future<void> fetchSlots({
    required int vendorId,
    required int gameId,
    required String date, // e.g., '20250519'
  }) async {
    _setLoading(true);
    try {
      final slotList = await _remoteRepo.fetchSlots(
        vendorId: vendorId,
        gameId: gameId,
        date: date,
      );

      // Debug logging to understand the slot structure
      print('Fetched ${slotList.length} slots');
      if (slotList.isNotEmpty) {
        print('First slot structure: ${slotList.first}');
      }

      slots.assignAll(slotList);
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
    try {
      final result = await _remoteRepo.createBooking(
        slotId: slotId,
        userId: userId,
        gameId: gameId,
      );
      return result;
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch user ID from local storage
  Future<void> fetchUserId() async {
    try {
      final userData = await _remoteRepo.getUserFromPreferences();
      if (userData != null) {
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
    try {
      final bookings = await _remoteRepo.fetchUserBookings(userId.value);
      userBookings.assignAll(bookings);
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
