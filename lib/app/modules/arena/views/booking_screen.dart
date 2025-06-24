import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';

import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/models/slot_model.dart';
import 'booking_summary_screen.dart';

class BookingScreen extends StatefulWidget {
  final String title;
  final int gameId;
  final int vendorId;

  BookingScreen({super.key, required this.title, required this.gameId, required this.vendorId});

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
        decoration: BoxDecoration(color: Colors.black),
        child: Obx(() {
          if (controller.isLoading.value) {
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

          if (controller.slots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No slots available',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try selecting a different date',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Check if there are any available slots
          final availableSlots = controller.slots.where((slot) {
            final bool isAvailable = slot['is_available'] ?? slot['isAvailable'] ?? true;
            return isAvailable;
          }).toList();
          if (availableSlots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.computer,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No available slots for this date',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All slots are currently booked',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return buildSlotList();
        }),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Gaming Cafe | $selectedDateText',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Obx(() {
                      final availableSlots = controller.slots.where((slot) {
                        final bool isAvailable = slot['is_available'] ?? slot['isAvailable'] ?? true;
                        return isAvailable;
                      }).toList();
                      final totalAvailablePCs = availableSlots.fold<int>(0, (sum, slot) {
                        final int availablePCs = slot['available_slot'] ?? slot['availableSlot'] ?? slot['available_slots'] ?? 0;
                        return sum + availablePCs;
                      });
                      return Text(
                        '$totalAvailablePCs PCs available across ${availableSlots.length} time slots',
                        style: TextStyle(
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
                    lastDate: DateTime.now().add(Duration(days: 30)),
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
                      controller.fetchSlots(vendorId: widget.vendorId, gameId: widget.gameId, date: selectedDate);
                    });
                  }
                },
                icon: Icon(Icons.calendar_today, color: Colors.white),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: controller.slots.length,
            itemBuilder: (context, index) {
              final slot = controller.slots[index];
              // Check availability with fallback field names
              final bool isAvailable = slot['is_available'] ?? slot['isAvailable'] ?? true;
              if (isAvailable) {
                return buildSlotItem(slot, index);
              } else {
                return SizedBox.shrink(); // Hide unavailable slots
              }
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
    // Get the number of available PCs for this slot with fallback
    final int availablePCs = slot['available_slot'] ?? slot['availableSlot'] ?? slot['available_slots'] ?? 0;
    
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slot: ${formatTime(slot['start_time'])} - ${formatTime(slot['end_time'])}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Text(
                    '$availablePCs PC${availablePCs > 1 ? 's' : ''} Available',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (availablePCs > 0) ...[
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
            ] else ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No PCs available for this slot',
                      style: TextStyle(
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
                ? LinearGradient(
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
                  '₹${totalPrice.toInt()}',
                  style: TextStyle(
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
    List<Map<String, dynamic>> selectedSlotDetails = [];
    controller.selectedSlots.forEach((pcIndex, timeIndices) {
      for (var timeIndex in timeIndices) {
        final slot = controller.slots[timeIndex];
        selectedSlotDetails.add({
          "pc_index": pcIndex,
          "slot_id": slot['slot_id'] ?? slot['id'],
          "start_time": slot['start_time'],
          "end_time": slot['end_time'],
          "price": slot['single_slot_price'] ?? 50,
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