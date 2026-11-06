import 'package:get/get.dart';
import 'package:hash/utils/constants.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:hash/core/utils/app_logger.dart';

class ReviewController extends GetxController {
  final String baseUri = hostName;

  var reviews = [].obs;
  var isLoading = false.obs;
  final Dio _dio = Dio();

  // Method to add a review
  Future<void> addReview(String token, String pid, double rating, String comment) async {
    final url = '$baseUri/product/$pid/reviews';
    final body = {
      'rating': rating,
      'comment': comment,
    };

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.d('Review added successfully');
        // Refresh the reviews after adding a new one
        getReviews(pid);
      } else {
        AppLogger.d('Failed to add review: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.d('Error adding review: $e');
    }
  }

  // Method to get reviews
  Future<void> getReviews(String pid) async {
    isLoading.value = true;
    final url = '$baseUri/product/$pid/reviews';

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response.data is String
          ? json.decode(response.data as String)
          : response.data;
      AppLogger.d(data);
      if (response.statusCode == 200) {
        reviews.value = data['reviews'];
      } else {
        AppLogger.d('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.d('Error fetching reviews: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Method to delete a review
  Future<void> deleteReview(String token, String pid, String reviewId) async {
    final url = '$baseUri/product/$pid/reviews/$reviewId';

    try {
      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        AppLogger.d('Review deleted successfully');
        // Refresh the reviews after deleting one
        getReviews(pid);
      } else {
        AppLogger.d('Failed to delete review: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.d('Error deleting review: $e');
    }
  }
}
