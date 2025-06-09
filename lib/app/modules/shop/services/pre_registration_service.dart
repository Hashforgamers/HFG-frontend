import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pre_registration_model.dart';

class PreRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'pre_registrations';

  Future<bool> isAlreadyRegistered(String userId, String productId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check registration status: $e');
    }
  }

  Future<void> savePreRegistration(PreRegistration registration) async {
    try {
      // Check if user is already registered for this product
      final bool isRegistered = await isAlreadyRegistered(
        registration.userId,
        registration.productId,
      );

      if (isRegistered) {
        throw Exception('You have already pre-registered for this product');
      }

      await _firestore.collection(_collection).add(registration.toMap());
    } catch (e) {
      throw Exception('Failed to save pre-registration: $e');
    }
  }

  Future<List<PreRegistration>> getUserPreRegistrations(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => PreRegistration.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pre-registrations: $e');
    }
  }
} 