import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/booking_controller.dart';
import 'booking_summary_screen.dart';

class BookingScreen extends StatefulWidget {
  final String title;
  final int gameId;

  BookingScreen({super.key, required this.title, required this.gameId});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingController controller = Get.put(BookingController());
  final selectedSlots = RxMap<int, List<int>>({});
  late int userId; // User ID dynamically fetched

  @override
  void initState() {
    super.initState();
    _fetchUserId(); // Fetch userId on initialization
    controller.fetchSlots(widget.gameId);
    print('gaemrId:${widget.gameId}');// Fetch slots when the screen loads
  }

  /// Fetch the `userId` from SharedPreferences
  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data'); // Get JSON string

    if (userDataString != null) {
      final Map<String, dynamic> userData = jsonDecode(userDataString); // Decode JSON string
      setState(() {
        userId = userData['id']; // Access and assign the id directly as an integer
      });
      print('User ID: $userId');
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
    controller.fetchSlots(widget.gameId);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.title),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.slots.isEmpty) {
            return Center(
              child: Text(
                'No slots available',
                style: TextStyle(color: Colors.white),
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
          child: Text(
            'Global Gaming Cafe | 17 Sep, 2024',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
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
      // Parse the raw time string
      final DateTime parsedTime = DateFormat('HH:mm:ss').parse(rawTime);

      // Format it to 24-hour format (HH:mm)
      return DateFormat('HH:mm').format(parsedTime);
    } catch (e) {
      print('Error formatting time: $e');
      return rawTime; // Fallback to rawTime in case of error
    }
  }
  Widget buildSlotItem(Map<String, dynamic> slot, int index) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 90,
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        // Icon(Icons.access_time, color: Colors.white70, size: 15),
                        // SizedBox(width: 4),
                        Text(
                          '${formatTime(slot['time']['start_time'])} - ${formatTime(slot['time']['end_time'])}     |',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),                        SizedBox(width: 14),

                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          6, // Number of PCs
                              (pcIndex) => buildPCSlotRow(
                            pcIndex: pcIndex + 1,
                            timeIndex: index,
                            slotId: slot['id'],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(
          color: Color(0xff2D2D2D),
          thickness: 1,
          indent: 24,
          endIndent: 24,
          height: 30,
        ),
      ],
    );
  }

  Widget buildFooter() {
    return Obx(() {
      int totalSelectedSlots = controller.selectedSlots.values.fold(
        0,
            (sum, slots) => sum + slots.length,
      );

      return Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        decoration: BoxDecoration(
          color: Color(0xff0F0F0F),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalSelectedSlots Slot(s) Selected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Total: ₹${totalSelectedSlots * 50}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: totalSelectedSlots > 0 ? onProceed : null,
              child: Text('PROCEED', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: totalSelectedSlots > 0
                    ? Color(0xff00D701)
                    : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: totalSelectedSlots > 0 ? 8 : 0,
              ),
            ),
          ],
        ),
      );
    });
  }


  int getTotalSelectedSlots() {
    return selectedSlots.values.fold(0, (sum, slots) => sum + slots.length);
  }

  Widget buildPCSlotRow({
    required int pcIndex,
    required int timeIndex,
    required int slotId,
  }) {
    bool isSelected = controller.selectedSlots[pcIndex]?.contains(timeIndex) ?? false;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          controller.selectedSlots[pcIndex]?.remove(timeIndex);
          if (controller.selectedSlots[pcIndex]?.isEmpty ?? true) {
            controller.selectedSlots.remove(pcIndex);
          }
        } else {
          controller.selectedSlots[pcIndex] = controller.selectedSlots[pcIndex] ?? [];
          controller.selectedSlots[pcIndex]?.add(timeIndex);
        }
        controller.selectedSlots.refresh(); // Notify observers
      },
      child: Obx(() {
        final isSelected = controller.selectedSlots[pcIndex]?.contains(timeIndex) ?? false;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
              colors: [
                Colors.green.withOpacity(0.8),
                Color(0xff00D701),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected ? Colors.white.withOpacity(0.9) : Color(0xff0E0E0E),
            border: Border.all(color: Color(0xff2D2D2D)),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.5),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
            ],
          ),
          margin: EdgeInsets.symmetric(horizontal: 5),
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PC $pcIndex',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected ? Colors.white : Colors.white,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }


  void onProceed() {
    List<Map<String, dynamic>> selectedSlotDetails = [];
    selectedSlots.forEach((pcIndex, timeIndices) {
      for (var timeIndex in timeIndices) {
        final slot = controller.slots[timeIndex];
        selectedSlotDetails.add({
          "pc_index": pcIndex,
          "slot_id": slot['id'],
          "start_time": slot['time']['start_time'],
          "end_time": slot['time']['end_time'],
        });
      }
    });

    Get.to(() => BookingSummaryScreen(
      selectedSlots: selectedSlotDetails,
      gameId: widget.gameId,
      userId:userId,

    ));
  }
}
