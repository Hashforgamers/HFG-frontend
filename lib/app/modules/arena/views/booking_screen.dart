import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'booking_summary_screen.dart';

class BookingScreen extends StatefulWidget {
  final String email;
  final String consoleType;
  final String title;
  final int gameId;
  final int vendorId;
  final List<Map<String, dynamic>>? cartItems;

  const BookingScreen({
    super.key,
    required this.email,
    required this.consoleType,
    required this.title,
    required this.gameId,
    required this.vendorId,
    required this.cartItems,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingController controller = Get.put(BookingController());
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  late int userId;
  String selectedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  String selectedDateText = DateFormat('dd MMM, yyyy').format(DateTime.now());
  bool _loggedNoSlots = false;
  bool _loggedSoldOut = false;
  final Set<String> _almostFullLoggedSlots = <String>{};
  final Set<String> _unavailableLoggedSlots = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    controller.fetchSlots(
      vendorId: widget.vendorId,
      gameId: widget.gameId,
      date: selectedDate,
    );

    // Clear any previous selections when entering the screen
    controller.clearSelectedSlots();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear selections when returning to this screen
    controller.clearSelectedSlots();
  }

  /// Get the console type from the passed parameter
  String getConsoleType() {
    return widget.consoleType;
  }

  /// Get the console label for a specific index
  String getConsoleLabel(int index) {
    final consoleType = getConsoleType();
    return '$consoleType${index + 1}';
  }

  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        userId = userData['id'];
      });
    } else {
      Get.snackbar(
        'Error',
        'User data not found in preferences!',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clear selections when building the widget (ensures fresh state)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedSlots.isNotEmpty) {
        controller.clearSelectedSlots();
      }
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        child: Obx(() {
          if (controller.isLoading.value) {
            return ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[900]!,
                  highlightColor: Colors.grey[800]!,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            );
          }

          if (controller.slots.isEmpty) {
            if (!_loggedNoSlots) {
              _loggedNoSlots = true;
              _segmentService.onCustomEvent('Cafe Slot Sold Out', {
                'cafe_id': widget.vendorId.toString(),
                'slot_time': selectedDate,
              });
              _fbEventsService.onCafeSlotSoldOut(
                cafeId: widget.vendorId.toString(),
                slotTime: selectedDate,
              );
            }
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No slots available',
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try selecting a different date',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                buildCalendarButton(),
              ],
            );
          }

          // Show all API slots to users.
          // Only check for selectable slots to drive empty state messaging.
          final isCurrentDate =
              selectedDate == DateFormat('yyyyMMdd').format(DateTime.now());
          final selectableSlots = controller.slots.where((slot) {
            final bool isApiAvailable =
                slot['is_available'] ?? slot['isAvailable'] ?? true;
            final int availableConsoles =
                slot['available_slot'] ??
                slot['availableSlot'] ??
                slot['available_slots'] ??
                0;
            final bool isTimeAvailable = isCurrentDate
                ? controller.isSlotAvailableNow(slot)
                : true;
            return isApiAvailable && isTimeAvailable && availableConsoles > 0;
          }).toList();
          if (selectableSlots.isEmpty) {
            if (!_loggedSoldOut) {
              _loggedSoldOut = true;
              _segmentService.onCustomEvent('Cafe Fully Booked', {
                'cafe_id': widget.vendorId.toString(),
              });
              _fbEventsService.onCafeFullyBooked(
                cafeId: widget.vendorId.toString(),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.computer, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No selectable slots right now',
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different date or check slots marked as time expired/sold out',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                buildCalendarButton(),
              ],
            );
          }

          return buildSlotList();
        }),
      ),
    );
  }

  Widget buildCalendarButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xff121212),
        border: Border(top: BorderSide(color: Color(0xff2D2D2D), width: 1)),
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            builder: (context, child) {
              return Theme(data: ThemeData.dark(), child: child!);
            },
          );

          if (pickedDate != null) {
            setState(() {
              selectedDate = DateFormat('yyyyMMdd').format(pickedDate);
              selectedDateText = DateFormat('dd MMM, yyyy').format(pickedDate);
              _loggedNoSlots = false;
              _loggedSoldOut = false;
              _almostFullLoggedSlots.clear();
              _unavailableLoggedSlots.clear();
              controller.fetchSlots(
                vendorId: widget.vendorId,
                gameId: widget.gameId,
                date: selectedDate,
              );
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffDE3A3A),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 8,
        ),
        icon: const Icon(Icons.calendar_today, color: Colors.white),
        label: Text(
          'SELECT DIFFERENT DATE',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildSlotList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDateText,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final isCurrentDate =
                          selectedDate ==
                          DateFormat('yyyyMMdd').format(DateTime.now());
                      final availableSlots = controller.slots.where((slot) {
                        final bool isAvailable =
                            slot['is_available'] ?? slot['isAvailable'] ?? true;
                        final bool isTimeAvailable = isCurrentDate
                            ? controller.isSlotAvailableNow(slot)
                            : true;
                        final int availableConsoles =
                            slot['available_slot'] ??
                            slot['availableSlot'] ??
                            slot['available_slots'] ??
                            0;
                        return isAvailable && isTimeAvailable && availableConsoles > 0;
                      }).toList();
                      final int expiredSlots = controller.slots.where((slot) {
                        if (!isCurrentDate) return false;
                        return !controller.isSlotAvailableNow(slot);
                      }).length;
                      final totalAvailableConsoles = availableSlots.fold<int>(
                        0,
                        (sum, slot) {
                          final int availableConsoles =
                              slot['available_slot'] ??
                              slot['availableSlot'] ??
                              slot['available_slots'] ??
                              0;
                          return sum + availableConsoles;
                        },
                      );
                      final consoleType = getConsoleType();
                      return Text(
                        '$totalAvailableConsoles ${consoleType == 'PC' ? 'PCs' : '${consoleType}s'} selectable now • ${controller.slots.length} total slots${expiredSlots > 0 ? ' • $expiredSlots expired' : ''}',
                        style: GoogleFonts.inter(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    builder: (context, child) {
                      return Theme(data: ThemeData.dark(), child: child!);
                    },
                  );

                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = DateFormat('yyyyMMdd').format(pickedDate);
                      selectedDateText = DateFormat(
                        'dd MMM, yyyy',
                      ).format(pickedDate);
                      _loggedNoSlots = false;
                      _loggedSoldOut = false;
                      _almostFullLoggedSlots.clear();
                      _unavailableLoggedSlots.clear();
                      controller.fetchSlots(
                        vendorId: widget.vendorId,
                        gameId: widget.gameId,
                        date: selectedDate,
                      );
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: controller.slots.length,
            itemBuilder: (context, index) {
              final slot = controller.slots[index];
              return buildSlotItem(slot, index);
            },
          ),
        ),
        buildFooter(),
      ],
    );
  }

  String formatTime(String rawTime) {
    try {
      final DateTime parsedTime = DateFormat('HH:mm:ss').parse(rawTime);
      return DateFormat('HH:mm').format(parsedTime);
    } catch (e) {
      return rawTime;
    }
  }

  Widget buildSlotItem(Map<String, dynamic> slot, int index) {
    // Get the number of available PCs for this slot with fallback
    final int availablePCs =
        slot['available_slot'] ??
        slot['availableSlot'] ??
        slot['available_slots'] ??
        0;

    // Check if slot is available based on time - only for current date
    final bool isCurrentDate =
        selectedDate == DateFormat('yyyyMMdd').format(DateTime.now());
    final bool isApiAvailable = slot['is_available'] ?? slot['isAvailable'] ?? true;
    final bool isTimeAvailable = isCurrentDate
        ? controller.isSlotAvailableNow(slot)
        : true;
    final bool isSelectable = isApiAvailable && isTimeAvailable && availablePCs > 0;
    final startTime = (slot['start_time'] ?? '').toString();
    final slotKey = '${selectedDate}_$startTime';
    if (availablePCs > 0 &&
        availablePCs <= 2 &&
        !_almostFullLoggedSlots.contains(slotKey)) {
      _almostFullLoggedSlots.add(slotKey);
      _segmentService.onCustomEvent('Cafe Almost Full', {
        'cafe_id': widget.vendorId.toString(),
        'remaining_slots': availablePCs,
      });
      _fbEventsService.onCafeAlmostFull(
        cafeId: widget.vendorId.toString(),
        availableSlots: availablePCs,
      );
    }
    if (availablePCs <= 0 && !_unavailableLoggedSlots.contains(slotKey)) {
      _unavailableLoggedSlots.add(slotKey);
      _segmentService.onCustomEvent('Slot Unavailable', {
        'cafe_id': widget.vendorId.toString(),
        'slot_time': startTime,
      });
      _fbEventsService.onSlotUnavailable(
        cafeId: widget.vendorId.toString(),
        slotTime: startTime,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelectable
              ? const Color(0xFF1A1A1D)
              : const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isTimeAvailable
                ? const Color(0xff2D2D2D)
                : Colors.grey.shade800,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slot: ${formatTime(slot['start_time'])} - ${formatTime(slot['end_time'])}',
                  style: GoogleFonts.inter(
                    color: isTimeAvailable
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isTimeAvailable
                        ? (isApiAvailable
                              ? const Color(0xff00DC00).withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2))
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTimeAvailable
                          ? (isApiAvailable
                                ? const Color(0xff00DC00).withValues(alpha: 0.5)
                                : Colors.red.withValues(alpha: 0.5))
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    !isApiAvailable
                        ? 'Sold Out'
                        : (!isTimeAvailable && isCurrentDate)
                            ? 'Time Expired'
                            : '$availablePCs ${getConsoleType()}${availablePCs > 1 ? 's' : ''} Available',
                    style: GoogleFonts.inter(
                      color: !isApiAvailable
                          ? Colors.redAccent
                          : (isTimeAvailable
                                ? const Color(0xff00DC00)
                                : Colors.grey),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isSelectable) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    availablePCs,
                    (pcIndex) => buildPCSlotRow(
                      pcIndex: pcIndex + 1,
                      timeIndex: index,
                      slotId: slot['slot_id'] ?? slot['id'],
                    ),
                  ),
                ),
              ),
            ] else if (availablePCs > 0 && !isTimeAvailable && isCurrentDate) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Slot time has passed',
                      style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!isApiAvailable) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'This slot is sold out',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'No ${getConsoleType()}s available for this slot',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildPCSlotRow({
    required int pcIndex,
    required int timeIndex,
    required int slotId,
  }) {
    return Obx(() {
      final isSelected =
          controller.selectedSlots[pcIndex]?.contains(timeIndex) ?? false;

      return GestureDetector(
        onTap: () {
          if (isSelected) {
            controller.selectedSlots[pcIndex]?.remove(timeIndex);
            if (controller.selectedSlots[pcIndex]?.isEmpty ?? true) {
              controller.selectedSlots.remove(pcIndex);
            }
          } else {
            controller.selectedSlots[pcIndex] =
                controller.selectedSlots[pcIndex] ?? [];
            controller.selectedSlots[pcIndex]?.add(timeIndex);
            // message = 'Slot selected for ${getConsoleLabel(pcIndex - 1)}';
            _segmentService.onCustomEvent('Cafe Slot Selected', {
              'cafe_id': widget.vendorId.toString(),
              'slot_time': selectedDateText,
              'console_type': widget.consoleType,
            });
            _fbEventsService.onCafeSlotSelected(
              cafeId: widget.vendorId.toString(),
              slotTime: selectedDateText,
            );
          }

          // Fluttertoast.showToast(
          //   msg: message,
          //   backgroundColor: Colors.black,
          //   textColor: Colors.white,
          //   fontSize: 14,
          // );

          controller.selectedSlots.refresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff00DC00)
                : const Color(0xff2D2D2D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xff00DC00)
                  : Colors.grey.shade700,
            ),
          ),
          child: Text(
            getConsoleLabel(pcIndex - 1),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    });
  }

  Widget buildFooter() {
    return Obx(() {
      int totalSelectedSlots = controller.selectedSlots.values.fold(
        0,
        (sum, slots) => sum + slots.length,
      );

      // Calculate total price based on actual slot prices
      double totalPrice = 0.0;
      controller.selectedSlots.forEach((pcIndex, timeIndices) {
        for (var timeIndex in timeIndices) {
          if (timeIndex < controller.slots.length) {
            final slot = controller.slots[timeIndex];
            totalPrice += (slot['single_slot_price'] ?? 50).toDouble();
          }
        }
      });

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: const BoxDecoration(
          color: Color(0xff121212),
          border: Border(top: BorderSide(color: Color(0xff2D2D2D), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalSelectedSlots Slot(s)',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${totalPrice.toInt()}',
                  style: GoogleFonts.inter(
                    color: const Color(0xff00DC00),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: totalSelectedSlots > 0 ? onProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: totalSelectedSlots > 0
                    ? const Color(0xff00DC00)
                    : Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: totalSelectedSlots > 0 ? 8 : 0,
              ),
              child: Text(
                'PROCEED',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: totalSelectedSlots > 0 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void onProceed() {
    // Track game details viewed event when user proceeds with console selection
    _segmentService.onGameDetailsViewed(
      gameId: widget.gameId.toString(),
      cafeId: widget.vendorId.toString(),
    );
    _fbEventsService.onGameDetailsViewed(
      gameId: widget.gameId.toString(),
      cafeId: widget.vendorId.toString(),
    );

    List<Map<String, dynamic>> selectedSlotDetails = [];
    controller.selectedSlots.forEach((pcIndex, timeIndices) {
      for (var timeIndex in timeIndices) {
        final slot = controller.slots[timeIndex];
        selectedSlotDetails.add({
          "pc_index": pcIndex,
          "console_label": getConsoleLabel(pcIndex - 1),
          "slot_id": slot['slot_id'] ?? slot['id'],
          "start_time": slot['start_time'],
          "end_time": slot['end_time'],
          "price": slot['single_slot_price'] ?? 50,
        });
      }
    });

    _segmentService.onCafeConsoleSelected(
      email: widget.email,
      consoleType: widget.consoleType,
      consoleAmount: selectedSlotDetails.length,
    );

    Get.to(
      () => BookingSummaryScreen(
        selectedCafeName: widget.title,
        consoleType: widget.consoleType,
        selectedSlots: selectedSlotDetails,
        cartItems: widget.cartItems ?? [],
        gameId: widget.gameId,
        vendorId: widget.vendorId,
        selectedDate: selectedDate,
      ),
    );
  }
}
