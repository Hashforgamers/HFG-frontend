import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewController extends GetxController {
  final String baseUri = hostName;

  var reviews = [].obs;
  var isLoading = false.obs;

  // Method to add a review
  Future<void> addReview(String token, String pid, double rating, String comment) async {
    final url = Uri.parse('$baseUri/product/$pid/reviews');
    final body = {
      'rating': rating,
      'comment': comment,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Review added successfully');
        // Refresh the reviews after adding a new one
        getReviews(pid);
      } else {
        print('Failed to add review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding review: $e');
    }
  }

  // Method to get reviews
  Future<void> getReviews(String pid) async {
    isLoading.value = true;
    final url = Uri.parse('$baseUri/product/$pid/reviews');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        reviews.value = responseData['reviews'];
      } else {
        print('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to delete a review
  Future<void> deleteReview(String token, String pid, String reviewId) async {
    final url = Uri.parse('$baseUri/product/$pid/reviews/$reviewId');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Review deleted successfully');
        // Refresh the reviews after deleting one
        getReviews(pid);
      } else {
        print('Failed to delete review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting review: $e');
    }
  }
}
