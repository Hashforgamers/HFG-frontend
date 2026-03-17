import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingController extends GetxController {
  final isLoading = false.obs;
  final slots = <Map<String, dynamic>>[].obs; // Holds fetched slots
  final userBookings = <Map<String, dynamic>>[].obs; // Holds user bookings
  final selectedSlots = RxMap<int, List<int>>(
    {},
  ); // Holds selected slots per PC

  final _remoteRepo = locator<RemoteRepoInterface>();

  @override
  void onInit() {
    super.onInit();
    fetchUserBookings(); // Fetch bookings directly
  }

  /// Clear all selected slots
  void clearSelectedSlots() {
    selectedSlots.clear();
  }

  /// Filter and sort time slots based on start time
  List<Map<String, dynamic>> filterAndSortTimeSlots(
    List<Map<String, dynamic>> rawSlots,
  ) {
    try {
      // Keep all slots from API; only sort by time.
      // Availability/time status is handled in UI so users can understand why a slot is not selectable.
      final sortedSlots = List<Map<String, dynamic>>.from(rawSlots);

      // Sort slots by start time
      sortedSlots.sort((a, b) {
        final startTimeA = a['start_time'] ?? '';
        final startTimeB = b['start_time'] ?? '';

        // Parse time strings (format: "HH:mm:ss")
        final timeA = _parseTimeString(startTimeA);
        final timeB = _parseTimeString(startTimeB);

        return timeA.compareTo(timeB);
      });

      // Log the sorted slots for debugging
      AppLogger.d(
        'Sorted ${sortedSlots.length} slots out of ${rawSlots.length} total slots',
      );
      for (var slot in sortedSlots.take(3)) {
        AppLogger.d(
          'Slot: ${slot['start_time']} - ${slot['end_time']}, Available: ${slot['available_slot']}',
        );
      }

      return sortedSlots;
    } catch (e) {
      AppLogger.d('Error filtering and sorting slots: $e');
      return rawSlots; // Return original list if error occurs
    }
  }

  /// Parse time string to DateTime for comparison
  DateTime _parseTimeString(String timeStr) {
    try {
      if (timeStr.isEmpty) {
        return DateTime(2000, 1, 1, 0, 0);
      }

      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        // Validate hour and minute ranges
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(
            2000,
            1,
            1,
            hour,
            minute,
          ); // Use arbitrary date for time comparison
        }
      }
    } catch (e) {
      AppLogger.d('Error parsing time string: $timeStr, error: $e');
    }
    return DateTime(2000, 1, 1, 0, 0); // Default to midnight if parsing fails
  }

  /// Check if a slot is available based on current time
  bool isSlotAvailableNow(Map<String, dynamic> slot) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final startTimeStr = (slot['start_time'] ?? '').toString();
      final startTimeParts = startTimeStr.split(':');
      if (startTimeParts.length < 2) {
        return true;
      }

      final startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      final slotStartTime = today.add(
        Duration(hours: startHour, minutes: startMinute),
      );

      // Show only future slots for the current day. Ongoing or elapsed slots
      // should not be bookable, but upcoming slots must remain visible right
      // until their start time.
      return now.isBefore(slotStartTime);
    } catch (e) {
      return true; // Default to available if error
    }
  }

  /// Get filtered and sorted slots based on availability and time
  List<Map<String, dynamic>> getFilteredSlots(String selectedDate) {
    try {
      final isCurrentDate = selectedDate == _getCurrentDateString();

      return slots.where((slot) {
        // First check if slot is available from API
        final bool isAvailable =
            slot['is_available'] ?? slot['isAvailable'] ?? true;

        // Then check if slot is available based on current time (only for current date)
        final bool isTimeAvailable = isCurrentDate
            ? isSlotAvailableNow(slot)
            : true;

        // Also check if there are actually available consoles for this slot
        final int availableConsoles =
            slot['available_slot'] ??
            slot['availableSlot'] ??
            slot['available_slots'] ??
            0;

        return isAvailable && isTimeAvailable && availableConsoles > 0;
      }).toList();
    } catch (e) {
      AppLogger.d('Error getting filtered slots: $e');
      return slots.toList();
    }
  }

  /// Get total available consoles from filtered slots
  int getTotalAvailableConsoles(String selectedDate) {
    try {
      final availableSlots = getFilteredSlots(selectedDate);
      return availableSlots.fold<int>(0, (sum, slot) {
        final int availableConsoles =
            slot['available_slot'] ??
            slot['availableSlot'] ??
            slot['available_slots'] ??
            0;
        return sum + availableConsoles;
      });
    } catch (e) {
      AppLogger.d('Error calculating total available consoles: $e');
      return 0;
    }
  }

  /// Get current date string in yyyyMMdd format
  String _getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  /// Get the original index of a slot in the main slots list
  int getOriginalSlotIndex(Map<String, dynamic> slot) {
    try {
      return slots.indexWhere(
        (s) => s['slot_id'] == slot['slot_id'] || s['id'] == slot['id'],
      );
    } catch (e) {
      AppLogger.d('Error getting original slot index: $e');
      return 0;
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

      // Filter and sort the slots based on start time
      final filteredAndSortedSlots = filterAndSortTimeSlots(slotList);
      slots.assignAll(filteredAndSortedSlots);
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
    required int gameId,
  }) async {
    _setLoading(true);
    try {
      final result = await _remoteRepo.createBooking(
        slotId: slotId,
        gameId: gameId,
      );
      return result;
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch bookings for the current user
  Future<void> fetchUserBookings() async {
    _setLoading(true);
    try {
      final bookings = await _remoteRepo.fetchUserBookings();
      userBookings.assignAll(bookings);
      await _syncBackendUserIdFromBookings(bookings);
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
    AppLogger.d(message);
  }

  Future<void> _syncBackendUserIdFromBookings(
    List<Map<String, dynamic>> bookings,
  ) async {
    if (bookings.isEmpty) return;

    final dynamic rawUserId =
        bookings.first['user_id'] ?? bookings.first['userId'];
    final String userId = rawUserId?.toString().trim() ?? '';
    if (userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);

    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      userController.id.value = userId;
    }

    AppLogger.d('✅ Synced backend user_id from bookings: $userId');
  }
}
