import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tailor_model.dart';

class TailorRepo {
  final CollectionReference _tailorCollection;

  TailorRepo()
      : _tailorCollection = FirebaseFirestore.instance.collection('tailor');

  // ==================== READ OPERATIONS ====================


  /// Update tailor profile
  Future<void> updateTailorProfile({
    required String tailorId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      updates['updated_at'] = Timestamp.now();
      await _tailorCollection.doc(tailorId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  /// Update tailor location
  Future<void> updateTailorLocation({
    required String tailorId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      await _tailorCollection.doc(tailorId).update({
        'latitude': latitude,
        'longitude': longitude,
        'full_address': address,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update availability status
  Future<void> updateAvailabilityStatus({
    required String tailorId,
    required bool isAvailable,
  }) async {
    try {
      await _tailorCollection.doc(tailorId).update({
        'availibility_status': isAvailable,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Add review and update rating



}


