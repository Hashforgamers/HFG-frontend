import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/models/chat_user_model.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/controllers/cafe_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'booking_design.dart';
import 'booking_summary_screen.dart';
import 'package:hash/core/localization/app_region.dart';

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
  String selectedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  String selectedDateText = DateFormat('dd MMM, yyyy').format(DateTime.now());
  bool _loggedNoSlots = false;
  bool _loggedSoldOut = false;
  final Set<String> _almostFullLoggedSlots = <String>{};
  final Set<String> _unavailableLoggedSlots = <String>{};
  bool _isLoadingPricingEstimate = false;
  bool _isOpeningSummary = false;
  Map<String, dynamic>? _pricingEstimate;

  int get _requiredSelectionCount =>
      widget.requiredConsoleCount > 0 ? widget.requiredConsoleCount : 1;

  @override
  void initState() {
    super.initState();
    controller.fetchSlots(
      vendorId: widget.vendorId,
      gameId: widget.gameId,
      date: selectedDate,
    );
    _loadPricingEstimate();

    // Clear any previous selections when entering the screen
    controller.clearSelectedSlots();
  }

  /// Get the console type from the passed parameter
  String getConsoleType() {
    final type = widget.consoleType.toLowerCase().trim();
    if (type.contains('playstation 3') ||
        RegExp(r'\bps\s*3\b').hasMatch(type)) {
      return 'PS3';
    }
    if (type.contains('playstation 4') ||
        RegExp(r'\bps\s*4\b').hasMatch(type)) {
      return 'PS4';
    }
    if (type.contains('playstation 5') ||
        RegExp(r'\bps\s*5\b').hasMatch(type)) {
      return 'PS5';
    }
    if (type.contains('playstation') || RegExp(r'\bps\b').hasMatch(type)) {
      return 'PlayStation';
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

  /// Console slug sent to pricing.
  ///
  /// This used to collapse everything that was not PlayStation or Xbox down to
  /// 'pc', so arcade cabinets, Switch, VR, racing rigs and rooms were all
  /// priced as a PC while the booking POST sent the real slug in
  /// `console_type`. Pricing and booking now agree on one vocabulary.
  String get _normalizedConsoleType {
    final type = widget.consoleType
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    if (type.isEmpty) return 'pc';
    if (type.contains('playstation') || type.startsWith('ps')) return 'ps';
    if (type.contains('xbox')) return 'xbox';
    if (type.contains('nintendo') || type.contains('switch')) {
      return 'nintendo_switch';
    }
    if (type.contains('arcade')) return 'arcade_cabinet';
    if (type.contains('vr') || type.contains('virtual')) return 'vr_headset';
    if (type.contains('steam') || type.contains('deck')) return 'steam_deck';
    if (type.contains('racing') || type.contains('rig')) return 'racing_rig';
    if (type.contains('simulator')) return 'simulator';
    if (type.contains('vip')) return 'vip_room';
    if (type.contains('bootcamp')) return 'bootcamp_room';
    if (type.contains('private')) return 'private_room';
    if (type.contains('pc') || type.contains('computer')) return 'pc';
    return type;
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

  @override
  Widget build(BuildContext context) {
    return BookingScaffold(
      title: widget.title,
      subtitle: widget.isSquadBooking ? 'Squad booking' : 'Select your slots',
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: BookingColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            widget.isSquadBooking ? 'Squad booking' : 'Select your slots',
            style: GoogleFonts.inter(
              color: BookingColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isSlotsLoading.value) {
            return Column(
              children: [
                _buildDateStrip(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Shimmer.fromColors(
                        baseColor: BookingColors.surface,
                        highlightColor: BookingColors.surfaceHigh,
                        child: Container(
                          height: 96,
                          decoration: BoxDecoration(
                            color: BookingColors.surface,
                            borderRadius: BorderRadius.circular(
                              BookingRadius.card,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          if (controller.slotsError.value.isNotEmpty) {
            return _buildSlotsErrorState();
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
            return _buildEmptySlotsState(
              icon: Icons.schedule_rounded,
              title: 'No slots available',
              message: 'This cafe has no bookable sessions on this date.',
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
            return _buildEmptySlotsState(
              icon: Icons.sports_esports_rounded,
              title: 'All slots are booked',
              message: 'Choose another date to find an available session.',
            );
          }

          return buildSlotList();
        }),
      ),
    );
  }

  Widget _buildEmptySlotsState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Column(
      children: [
        _buildDateStrip(),
        Expanded(
          child: BookingEmptyState(
            icon: icon,
            title: title,
            message: message,
            footnote: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BookingColors.surfaceHigh,
                borderRadius: BorderRadius.circular(BookingRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: BookingColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedDateText,
                    style: GoogleFonts.inter(
                      color: BookingColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(DateTime pickedDate) async {
    setState(() {
      selectedDate = DateFormat('yyyyMMdd').format(pickedDate);
      selectedDateText = DateFormat('dd MMM, yyyy').format(pickedDate);
      _loggedNoSlots = false;
      _loggedSoldOut = false;
      _almostFullLoggedSlots.clear();
      _unavailableLoggedSlots.clear();
    });
    controller.clearSelectedSlots();
    await controller.fetchSlots(
      vendorId: widget.vendorId,
      gameId: widget.gameId,
      date: selectedDate,
    );
  }

  Future<void> _openCalendar() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BookingColors.accent,
              surface: BookingColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && mounted) {
      await _pickDate(pickedDate);
    }
  }

  /// Horizontal quick-pick strip of the next two weeks, plus a calendar entry
  /// point for arbitrary dates — a faster way to switch dates than the old
  /// single "choose another date" button.
  Widget _buildDateStrip() {
    final today = DateTime.now();
    final days = List.generate(
      14,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: SizedBox(
        height: 74,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: days.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == days.length) {
              return _CalendarChip(onTap: _openCalendar);
            }
            final day = days[index];
            final key = DateFormat('yyyyMMdd').format(day);
            final selected = key == selectedDate;
            return _DateChip(
              day: day,
              isToday: index == 0,
              selected: selected,
              onTap: () {
                if (!selected) _pickDate(day);
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildSlotList() {
    final visibleSlotIndices = _getVisibleSlotIndices();
    final isCurrentDate =
        selectedDate == DateFormat('yyyyMMdd').format(DateTime.now());
    final availableSlots = visibleSlotIndices
        .map((index) => controller.slots[index])
        .where((slot) {
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
        })
        .toList();
    final totalAvailableConsoles = availableSlots.fold<int>(0, (sum, slot) {
      final int availableConsoles =
          slot['available_slot'] ??
          slot['availableSlot'] ??
          slot['available_slots'] ??
          0;
      return sum + availableConsoles;
    });
    final discountPercent = _asDouble(
      _squadDetailsEstimate?['discount_percent'],
    );

    return Column(
      children: [
        _buildDateStrip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.isSquadBooking
                      ? 'Pick exactly $_requiredSelectionCount ${_consoleCollectionLabel(_requiredSelectionCount)}'
                      : 'Available sessions',
                  style: BookingText.title(context),
                ),
              ),
              BookingStatusPill(
                label: '$totalAvailableConsoles open',
                tone: totalAvailableConsoles > 0
                    ? BookingPillTone.success
                    : BookingPillTone.danger,
                icon: Icons.bolt_rounded,
                dense: true,
              ),
              if (widget.isSquadBooking && discountPercent > 0) ...[
                const SizedBox(width: 6),
                BookingStatusPill(
                  label:
                      'Squad -${discountPercent.toStringAsFixed(discountPercent % 1 == 0 ? 0 : 1)}%',
                  tone: BookingPillTone.accent,
                  dense: true,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

    final bool hasSelectionHere = controller.selectedSlots.values.any(
      (times) => times.contains(index),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BookingCard(
        padding: const EdgeInsets.all(16),
        color: isSelectable ? BookingColors.surface : BookingColors.bgElevated,
        highlight: hasSelectionHere,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        (isSelectable
                                ? BookingColors.accent
                                : BookingColors.textMuted)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 19,
                    color: isSelectable
                        ? BookingColors.accentBright
                        : BookingColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${formatTime(slot['start_time'])} – ${formatTime(slot['end_time'])}',
                    style: GoogleFonts.inter(
                      color: isTimeAvailable
                          ? BookingColors.textPrimary
                          : BookingColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                BookingStatusPill(
                  label: !isApiAvailable
                      ? 'Sold out'
                      : (!isTimeAvailable && isCurrentDate)
                      ? 'Expired'
                      : '$availablePCs left',
                  tone: !isApiAvailable
                      ? BookingPillTone.danger
                      : (!isTimeAvailable && isCurrentDate)
                      ? BookingPillTone.neutral
                      : (availablePCs <= 2
                            ? BookingPillTone.warning
                            : BookingPillTone.success),
                  dense: true,
                ),
              ],
            ),
            if (isSelectable) ...[
              const SizedBox(height: 14),
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
              const SizedBox(height: 12),
              _slotNotice(
                icon: Icons.schedule_rounded,
                text: 'Slot time has passed',
                tone: BookingPillTone.warning,
              ),
            ] else if (!isApiAvailable) ...[
              const SizedBox(height: 12),
              _slotNotice(
                icon: Icons.block_rounded,
                text: 'This slot is sold out',
                tone: BookingPillTone.danger,
              ),
            ] else ...[
              const SizedBox(height: 12),
              _slotNotice(
                icon: Icons.info_outline_rounded,
                text: 'No ${getConsoleType()}s available for this slot',
                tone: BookingPillTone.danger,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _slotNotice({
    required IconData icon,
    required String text,
    required BookingPillTone tone,
  }) {
    final color = switch (tone) {
      BookingPillTone.warning => BookingColors.warning,
      BookingPillTone.danger => BookingColors.danger,
      _ => BookingColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

      return Semantics(
        button: true,
        selected: isSelected,
        label:
            '${getConsoleLabel(pcIndex - 1)}${isSelected ? ', selected' : ''}',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
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
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: isSelected ? BookingColors.accentGradient : null,
              color: isSelected ? null : BookingColors.surfaceHigh,
              borderRadius: BorderRadius.circular(BookingRadius.chip),
              border: Border.all(
                color: isSelected
                    ? BookingColors.accentBright
                    : BookingColors.borderStrong,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: BookingColors.accent.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: BookingColors.textOnAccent,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  getConsoleLabel(pcIndex - 1),
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? BookingColors.textOnAccent
                        : BookingColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
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

      return BookingBottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Money.symbol}${totalPrice.toInt()}',
                        style: GoogleFonts.inter(
                          color: BookingColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$selectedConsoleCount/$_requiredSelectionCount ${_consoleCollectionLabel(_requiredSelectionCount)} • $totalSelectedSlots slot(s)',
                        style: GoogleFonts.inter(
                          color: BookingColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isSquadBooking &&
                    !_isLoadingPricingEstimate &&
                    estimatedDiscountPerSlot > 0)
                  BookingStatusPill(
                    label:
                        'Save ${Money.symbol}${estimatedDiscountPerSlot.toStringAsFixed(estimatedDiscountPerSlot % 1 == 0 ? 0 : 1)}/slot',
                    tone: BookingPillTone.success,
                    icon: Icons.savings_rounded,
                    dense: true,
                  ),
                if (totalSelectedSlots > 0) ...[
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Clear selection',
                    child: TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        controller.clearSelectedSlots();
                        controller.selectedSlots.refresh();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: BookingColors.textSecondary,
                      ),
                      label: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          color: BookingColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (widget.isSquadBooking && _isLoadingPricingEstimate) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Checking your squad savings…',
                  style: GoogleFonts.inter(
                    color: BookingColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            BookingPrimaryButton(
              label: 'Proceed',
              icon: Icons.arrow_forward_rounded,
              loading: _isOpeningSummary,
              enabled: totalSelectedSlots > 0,
              onPressed: totalSelectedSlots > 0 && !_isOpeningSummary
                  ? onProceed
                  : null,
            ),
          ],
        ),
      );
    });
  }

  Future<void> onProceed() async {
    if (_isOpeningSummary) return;
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

    setState(() => _isOpeningSummary = true);
    await Get.to(
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
    if (mounted) setState(() => _isOpeningSummary = false);
  }

  Widget _buildSlotsErrorState() {
    return Column(
      children: [
        _buildDateStrip(),
        Expanded(
          child: BookingEmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Slots could not be loaded',
            message: controller.slotsError.value.isEmpty
                ? 'Please check your connection and try again.'
                : controller.slotsError.value,
            tone: BookingPillTone.neutral,
            footnote: SizedBox(
              width: 200,
              child: BookingSecondaryButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                onPressed: () => controller.fetchSlots(
                  vendorId: widget.vendorId,
                  gameId: widget.gameId,
                  date: selectedDate,
                ),
              ),
            ),
          ),
        ),
      ],
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

/// A single day chip in the quick-pick date strip.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat('EEE').format(day).toUpperCase();
    final dayNum = DateFormat('d').format(day);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${isToday ? 'Today' : DateFormat('EEEE').format(day)}, '
          '${DateFormat('d MMMM').format(day)}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          decoration: BoxDecoration(
            gradient: selected ? BookingColors.accentGradient : null,
            color: selected ? null : BookingColors.surface,
            borderRadius: BorderRadius.circular(BookingRadius.button),
            border: Border.all(
              color: selected
                  ? BookingColors.accentBright
                  : BookingColors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: BookingColors.accent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isToday ? 'TODAY' : weekday,
                style: GoogleFonts.inter(
                  color: selected
                      ? BookingColors.textOnAccent.withValues(alpha: 0.8)
                      : BookingColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                dayNum,
                style: GoogleFonts.inter(
                  color: selected
                      ? BookingColors.textOnAccent
                      : BookingColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing "open calendar" chip in the date strip.
class _CalendarChip extends StatelessWidget {
  const _CalendarChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        decoration: BoxDecoration(
          color: BookingColors.surfaceAlt,
          borderRadius: BorderRadius.circular(BookingRadius.button),
          border: Border.all(color: BookingColors.borderStrong),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: BookingColors.textSecondary,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              'More',
              style: TextStyle(
                color: BookingColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
