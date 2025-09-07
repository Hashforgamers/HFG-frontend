import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> addCafeRequest({
    required String cafeName,
    required String pincode,
    required String address,
  }) async {
    try {
      await _firestore.collection('requested_cafes').add({
        'cafe_name': cafeName,
        'pincode': pincode,
        'address': address,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit cafe request. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Stream<QuerySnapshot> getRequestedCafes() {
    return _firestore
        .collection('requested_cafes')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> updateCafeRequestStatus(String requestId, String status) async {
    try {
      await _firestore.collection('requested_cafes').doc(requestId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update cafe request status.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
} 