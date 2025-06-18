import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';

import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'booking_summary_screen.dart';

class BookingScreen extends StatefulWidget {
  final String title;
  final int gameId;
  final int vendorId;

  const BookingScreen({super.key, required this.title, required this.gameId, required this.vendorId});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingController controller = Get.put(BookingController());
  late int userId;
  String selectedDate = DateFormat('yyyyMMdd').format(DateTime.now());
  String selectedDateText = DateFormat('dd MMM, yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    controller.fetchSlots(vendorId: widget.vendorId, gameId: widget.gameId, date: selectedDate);
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
        title: Text(widget.title),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingShimmer();
          }

          if (controller.errorMessage.isNotEmpty) {
            return _buildErrorState();
          }

          if (controller.slots.isEmpty) {
            return _buildEmptyState();
          }

          return buildSlotList();
        }),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              controller.fetchSlots(
                vendorId: widget.vendorId,
                gameId: widget.gameId,
                date: selectedDate,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffDE3A3A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'No slots available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try a different date',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
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
              Text(
                'Global Gaming Cafe | $selectedDateText',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                      return Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = DateFormat('yyyyMMdd').format(pickedDate);
                      selectedDateText = DateFormat('dd MMM, yyyy').format(pickedDate);
                      controller.fetchSlots(vendorId: 1, gameId: widget.gameId, date: selectedDate);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white),
              )
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
      print('Error formatting time: $e');
      return rawTime;
    }
  }

  Widget buildSlotItem(Map<String, dynamic> slot, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xff2D2D2D)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot: ${formatTime(slot['start_time'])} - ${formatTime(slot['end_time'])}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  6,
                      (pcIndex) => buildPCSlotRow(
                    pcIndex: pcIndex + 1,
                    timeIndex: index,
                    slotId: slot['slot_id'],
                  ),
                ),
              ),
            ),
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
      final isSelected = controller.selectedSlots[pcIndex]?.contains(timeIndex) ?? false;

      return GestureDetector(
        onTap: () {
          String message;
          if (isSelected) {
            controller.selectedSlots[pcIndex]?.remove(timeIndex);
            if (controller.selectedSlots[pcIndex]?.isEmpty ?? true) {
              controller.selectedSlots.remove(pcIndex);
            }
            message = 'Slot deselected from PC $pcIndex';
          } else {
            controller.selectedSlots[pcIndex] = controller.selectedSlots[pcIndex] ?? [];
            controller.selectedSlots[pcIndex]?.add(timeIndex);
            message = 'Slot selected for PC $pcIndex';
          }

          Fluttertoast.showToast(
            msg: message,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 14,
          );

          controller.selectedSlots.refresh();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [Color(0xff00FFAB), Color(0xffDE3A3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected ? null : const Color(0xff2D2D2D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.greenAccent : Colors.grey.shade700,
            ),
          ),
          child: Text(
            'PC $pcIndex',
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
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
      int totalSelectedSlots = controller.selectedSlots.values.fold(0, (sum, slots) => sum + slots.length);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: const BoxDecoration(
          color: Color(0xff121212),
          border: Border(
            top: BorderSide(color: Color(0xff2D2D2D), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalSelectedSlots Slot(s)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${totalSelectedSlots * 50}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
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
                backgroundColor: totalSelectedSlots > 0 ? const Color(0xffDE3A3A) : Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: totalSelectedSlots > 0 ? 8 : 0,
              ),
              child: Text(
                'PROCEED',
                style: TextStyle(
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
    if (controller.errorMessage.isNotEmpty) {
      Get.snackbar(
        'Error',
        'Please resolve the error before proceeding',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    List<Map<String, dynamic>> selectedSlotDetails = [];
    controller.selectedSlots.forEach((pcIndex, timeIndices) {
      for (var timeIndex in timeIndices) {
        final slot = controller.slots[timeIndex];
        selectedSlotDetails.add({
          "pc_index": pcIndex,
          "slot_id": slot['slot_id'],
          "start_time": slot['start_time'],
          "end_time": slot['end_time'],
        });
      }
    });

    Get.to(() => BookingSummaryScreen(
      selectedSlots: selectedSlotDetails,
      gameId: widget.gameId,
      userId: userId,
    ));
  }
}
