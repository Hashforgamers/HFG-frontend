import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CybercafesController extends GetxController {
  RxList<dynamic> cybercafes = [].obs;
  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // Base URL and auth token
  static const String baseUrl = hostName;

  // Fetch all cybercafes
  Future<void> fetchAllCybercafes() async {
    final authToken = await _getToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cybercafe/getAll'),
        headers: {'Authorization': "Bearer $authToken"},
      );
      print('result${response.body}');
      if (response.statusCode == 200) {
        cybercafes.assignAll(response.body as List<dynamic>);

      } else {
        throw Exception('Failed to load cybercafes');
      }
    } catch (e) {
      print('Error fetching cybercafes: $e');
    }
  }

  // Set user location
  // Set user location
  Future<void> setUserLocation(double latitude, double longitude) async {
    final authToken = await _getToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/set_location'),
        headers: {
          'Authorization': "Bearer $authToken",
          'Content-Type': 'application/json', // Ensure content type is JSON
        },
        body: jsonEncode({'latitude': latitude.toString(), 'longitude': longitude.toString()}),
      );

      if (response.statusCode == 200) {
        print('fetchloc${latitude}   $longitude');
      } else {
        throw Exception('Failed to set user location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error setting user location: $e');
    }
  }

  // Fetch nearby cybercafes
  Future<void> fetchNearbyCybercafes(double latitude, double longitude) async {
    final authToken = await _getToken();

      await setUserLocation(latitude, longitude);
      final response = await http.get(
        Uri.parse('$baseUrl/cybercafes'),
        headers: {'Authorization': "Bearer $authToken"},
      );
      print('fetchloc${response.body}');
      if (response.statusCode == 200) {
        cybercafes.assignAll(jsonDecode(response.body) as List);

      } else {
        throw Exception('Failed to load nearby cybercafes: ${response.statusCode}');
      }

  }
}

class BookingController extends GetxController {
  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }
  // Base URL and auth token
  static const String baseUrl = hostName;
  static const String authToken = 'YOUR_AUTH_TOKEN';

  Future<void> bookCybercafe(String cafeId, DateTime bookingTime, int slotDuration) async {
    final authToken = await _getToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cybercafe/book'),
        headers: {'Authorization': "Bearer $authToken"},
        body: {
          'cafe_id': cafeId,
          'booking_time': bookingTime.toUtc().toIso8601String(),
          'slot_duration': slotDuration.toString(),
        },
      );
      if (response.statusCode == 200) {
        Get.snackbar('Booking Status', 'Booking successful');
      } else {
        throw Exception('Failed to book cybercafe');
      }
    } catch (e) {
      print('Error booking cybercafe: $e');
      Get.snackbar('Booking Status', 'Failed to book cybercafe');
    }
  }
}

class CybercafeListPage extends StatelessWidget {
  final CybercafesController _cybercafesController = Get.find();
  final BookingController _bookingController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cybercafes'),
      ),
      body: Obx(() => ListView.builder(
        itemCount: _cybercafesController.cybercafes.length,
        itemBuilder: (context, index) {
          final cafe = _cybercafesController.cybercafes[index];
          return ListTile(
            title: Text(cafe['name']),
            subtitle: Text(cafe['address']['addressLine1']),
            onTap: () {
              // Example booking logic
              _bookingController.bookCybercafe(cafe['_id'], DateTime.now(), 120);
            },
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Fetch cybercafes
          _cybercafesController.fetchAllCybercafes();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
