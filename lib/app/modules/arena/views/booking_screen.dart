import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
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
  final bool isSquadBooking;
  final int requiredConsoleCount;
  final List<ChatUserModel> selectedSquadMembers;

  const BookingScreen({
    super.key,
    required this.email,
    required this.consoleType,
    required this.title,
    required this.gameId,
    required this.vendorId,
    required this.cartItems,
    this.isSquadBooking = false,
    this.requiredConsoleCount = 1,
    this.selectedSquadMembers = const <ChatUserModel>[],
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingController controller = Get.put(BookingController());
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  late int userId;
  String selectedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  String selectedDateText = DateFormat('dd MMM, yyyy').format(DateTime.now());
  bool _loggedNoSlots = false;
  bool _loggedSoldOut = false;
  final Set<String> _almostFullLoggedSlots = <String>{};
  final Set<String> _unavailableLoggedSlots = <String>{};
  bool _isLoadingPricingEstimate = false;
  Map<String, dynamic>? _pricingEstimate;

  int get _requiredSelectionCount =>
      widget.requiredConsoleCount > 0 ? widget.requiredConsoleCount : 1;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    controller.fetchSlots(
      vendorId: widget.vendorId,
      gameId: widget.gameId,
      date: selectedDate,
    );
    _loadPricingEstimate();

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
    final type = widget.consoleType.toLowerCase().trim();
    if (type.contains('playstation') || type.contains('ps')) {
      return 'PS5';
    }
    if (type.contains('xbox')) {
      return 'Xbox';
    }
    return 'PC';
  }

  /// Get the console label for a specific index
  String getConsoleLabel(int index) {
    final consoleType = getConsoleType();
    return '$consoleType${index + 1}';
  }

  String _consoleCollectionLabel(int count) {
    final consoleType = getConsoleType();
    if (consoleType == 'PC') {
      return count == 1 ? 'PC' : 'PC setups';
    }
    if (consoleType == 'PS5') {
      return count == 1 ? 'PS5 setup' : 'PS5 setups';
    }
    if (consoleType == 'Xbox') {
      return count == 1 ? 'Xbox setup' : 'Xbox setups';
    }
    return count == 1 ? '$consoleType setup' : '$consoleType setups';
  }

  List<int> _getVisibleSlotIndices() {
    final isCurrentDate =
        selectedDate == DateFormat('yyyyMMdd').format(DateTime.now());
    final indices = <int>[];
    for (var i = 0; i < controller.slots.length; i++) {
      final slot = controller.slots[i];
      final isTimeAvailable = isCurrentDate
          ? controller.isSlotAvailableNow(slot)
          : true;
      if (isTimeAvailable) {
        indices.add(i);
      }
    }
    return indices;
  }

  String get _normalizedConsoleType {
    final type = widget.consoleType.toLowerCase().trim();
    if (type.contains('playstation') || type.contains('ps')) return 'ps';
    if (type.contains('xbox')) return 'xbox';
    return 'pc';
  }

  Map<String, dynamic>? get _pricingEngine {
    final raw = _pricingEstimate?['pricing_engine'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Map<String, dynamic>? get _squadDetailsEstimate {
    final raw = _pricingEstimate?['squad_details'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadPricingEstimate() async {
    if (!widget.isSquadBooking) return;
    setState(() {
      _isLoadingPricingEstimate = true;
    });
    try {
      final estimate = await _remoteRepo.fetchBookingPricingEstimate(
        vendorId: widget.vendorId,
        gameId: widget.gameId,
        consoleType: _normalizedConsoleType,
        squadEnabled: widget.isSquadBooking,
        playerCount: _requiredSelectionCount,
      );
      if (!mounted) return;
      setState(() {
        _pricingEstimate = estimate;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pricingEstimate = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPricingEstimate = false;
        });
      }
    }
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

          final isCurrentDate =
              selectedDate == DateFormat('yyyyMMdd').format(DateTime.now());
          final visibleSlotIndices = _getVisibleSlotIndices();
          final selectableSlots = visibleSlotIndices
              .map((index) {
                return controller.slots[index];
              })
              .where((slot) {
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
                return isApiAvailable &&
                    isTimeAvailable &&
                    availableConsoles > 0;
              })
              .toList();
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
                          'Try a different date to see more slots',
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
    final visibleSlotIndices = _getVisibleSlotIndices();
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
                      final availableSlots = visibleSlotIndices
                          .map((index) {
                            return controller.slots[index];
                          })
                          .where((slot) {
                            final bool isAvailable =
                                slot['is_available'] ??
                                slot['isAvailable'] ??
                                true;
                            final bool isTimeAvailable = isCurrentDate
                                ? controller.isSlotAvailableNow(slot)
                                : true;
                            final int availableConsoles =
                                slot['available_slot'] ??
                                slot['availableSlot'] ??
                                slot['available_slots'] ??
                                0;
                            return isAvailable &&
                                isTimeAvailable &&
                                availableConsoles > 0;
                          })
                          .toList();
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
                      final discountPercent = _asDouble(
                        _squadDetailsEstimate?['discount_percent'],
                      );
                      final squadHint =
                          widget.isSquadBooking && discountPercent > 0
                          ? ' • save ${discountPercent.toStringAsFixed(discountPercent % 1 == 0 ? 0 : 1)}% with squad'
                          : '';
                      return Text(
                        '${widget.isSquadBooking ? 'Select exactly $_requiredSelectionCount setups' : 'Solo booking'} • $totalAvailableConsoles ${_consoleCollectionLabel(totalAvailableConsoles)} selectable now$squadHint',
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
                      controller.clearSelectedSlots();
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
            itemCount: visibleSlotIndices.length,
            itemBuilder: (context, index) {
              final originalIndex = visibleSlotIndices[index];
              final slot = controller.slots[originalIndex];
              return buildSlotItem(slot, originalIndex);
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
    final bool isApiAvailable =
        slot['is_available'] ?? slot['isAvailable'] ?? true;
    final bool isTimeAvailable = isCurrentDate
        ? controller.isSlotAvailableNow(slot)
        : true;
    final bool isSelectable =
        isApiAvailable && isTimeAvailable && availablePCs > 0;
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
                        : '$availablePCs ${_consoleCollectionLabel(availablePCs)} available',
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
            ] else if (availablePCs > 0 &&
                !isTimeAvailable &&
                isCurrentDate) ...[
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
          final selectedConsoleCount = _getSelectedConsoleCount();
          final isNewConsoleSelection =
              !(controller.selectedSlots.containsKey(pcIndex) &&
                  (controller.selectedSlots[pcIndex]?.isNotEmpty ?? false));
          if (isSelected) {
            controller.selectedSlots[pcIndex]?.remove(timeIndex);
            if (controller.selectedSlots[pcIndex]?.isEmpty ?? true) {
              controller.selectedSlots.remove(pcIndex);
            }
          } else {
            if (isNewConsoleSelection &&
                selectedConsoleCount > 0 &&
                !_isAllowedTimeForNewConsole(timeIndex)) {
              _showSlotAlignmentHint();
              return;
            }
            if (isNewConsoleSelection &&
                selectedConsoleCount >= _requiredSelectionCount) {
              _showSelectionCountError(
                'You can only select $_requiredSelectionCount ${_consoleCollectionLabel(_requiredSelectionCount)} for this booking.',
              );
              return;
            }
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
      final totalSelectedSlots = _getSelectedSlotCount();
      final selectedConsoleCount = _getSelectedConsoleCount();
      final selectedTimeBlockCount = controller.selectedSlots.values
          .expand((slots) => slots)
          .toSet()
          .length;

      // Calculate total price based on actual slot prices
      double totalPrice = 0.0;
      final pricingEngine = _pricingEngine;
      final estimatedPerSlotTotal = _asDouble(
        pricingEngine?['estimated_final_amount'],
      );
      if (widget.isSquadBooking &&
          estimatedPerSlotTotal > 0 &&
          selectedTimeBlockCount > 0) {
        totalPrice = estimatedPerSlotTotal * selectedTimeBlockCount;
      } else {
        controller.selectedSlots.forEach((pcIndex, timeIndices) {
          for (var timeIndex in timeIndices) {
            if (timeIndex < controller.slots.length) {
              final slot = controller.slots[timeIndex];
              totalPrice += (slot['single_slot_price'] ?? 50).toDouble();
            }
          }
        });
      }
      final estimatedDiscountPerSlot = _asDouble(
        pricingEngine?['squad_discount_amount'],
      );

      return SafeArea(
        top: false,
        child: Container(
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
                    '$selectedConsoleCount / $_requiredSelectionCount setups • $totalSelectedSlots slot(s)',
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
              if (widget.isSquadBooking) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _isLoadingPricingEstimate
                            ? 'Checking your squad savings...'
                            : estimatedDiscountPerSlot > 0
                            ? 'Squad discount applied to each selected time slot'
                            : 'Final squad savings will be shown once pricing is ready',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!_isLoadingPricingEstimate &&
                        estimatedDiscountPerSlot > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'You save ₹${estimatedDiscountPerSlot.toStringAsFixed(1)} per slot',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            color: const Color(0xff00DC00),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
        ),
      );
    });
  }

  void onProceed() {
    final selectedConsoleCount = _getSelectedConsoleCount();
    final totalSelectedSlots = _getSelectedSlotCount();
    if (totalSelectedSlots == 0 ||
        selectedConsoleCount != _requiredSelectionCount) {
      _showSelectionCountError(
        'Select exactly $_requiredSelectionCount ${_requiredSelectionCount == 1 ? getConsoleType() : '${getConsoleType()}s'} before continuing.',
      );
      return;
    }

    final incompleteSlotTimes = _getIncompleteSlotTimes();
    if (incompleteSlotTimes.isNotEmpty) {
      _showSelectionCountError(
        'Complete ${incompleteSlotTimes.first} for all $_requiredSelectionCount setups, or remove that partial slot.',
      );
      return;
    }

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
        isPayAtCafeAvailable: _isPayAtCafeAvailable(),
        isSquadBooking: widget.isSquadBooking,
        requiredConsoleCount: _requiredSelectionCount,
        selectedSquadMembers: widget.selectedSquadMembers,
      ),
    );
  }

  bool _isPayAtCafeAvailable() {
    if (!Get.isRegistered<CybercafesController>()) {
      return false;
    }
    final cafesController = Get.find<CybercafesController>();
    final vendor = cafesController.cybercafes.cast<dynamic>().firstWhere(
      (item) =>
          item is Map &&
          (item['vendor_id']?.toString() ?? '') == widget.vendorId.toString(),
      orElse: () => null,
    );
    if (vendor is! Map) {
      return false;
    }
    final paymentMethods = vendor['payment_methods'];
    if (paymentMethods is Map) {
      final payAtCafe = paymentMethods['Pay at Cafe'];
      if (payAtCafe is bool) return payAtCafe;
      if (payAtCafe is num) return payAtCafe == 1;
      if (payAtCafe is String) {
        final normalized = payAtCafe.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
    }
    return false;
  }

  int _getSelectedSlotCount() {
    return controller.selectedSlots.values.fold(
      0,
      (sum, slots) => sum + slots.length,
    );
  }

  int _getSelectedConsoleCount() {
    return controller.selectedSlots.entries
        .where((entry) => entry.value.isNotEmpty)
        .length;
  }

  bool _isAllowedTimeForNewConsole(int timeIndex) {
    for (final selectedTimeIndices in controller.selectedSlots.values) {
      if (selectedTimeIndices.contains(timeIndex)) {
        return true;
      }
    }
    return false;
  }

  List<String> _getIncompleteSlotTimes() {
    final Map<int, int> selectionCountsByTimeIndex = <int, int>{};

    for (final timeIndices in controller.selectedSlots.values) {
      for (final timeIndex in timeIndices) {
        selectionCountsByTimeIndex.update(
          timeIndex,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final List<String> incompleteTimes = <String>[];
    for (final entry in selectionCountsByTimeIndex.entries) {
      if (entry.value == _requiredSelectionCount) {
        continue;
      }
      if (entry.key < 0 || entry.key >= controller.slots.length) {
        continue;
      }

      final slot = controller.slots[entry.key];
      incompleteTimes.add('${slot['start_time']} - ${slot['end_time']}');
    }

    return incompleteTimes;
  }

  void _showSelectionCountError(String message) {
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showSlotAlignmentHint() {
    HapticFeedback.heavyImpact();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Select the same slot time as your previous setup, then add more time if needed.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }
}
