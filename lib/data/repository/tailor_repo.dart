import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tailor_model.dart';

class TailorRepo {
  final CollectionReference _tailorCollection;

  TailorRepo() : _tailorCollection = FirebaseFirestore.instance.collection('tailor');

  // ==================== READ OPERATIONS ====================

  /// Get tailor by ID
  Future<Tailor?> getTailorById(String tailorId) async {
    try {
      final doc = await _tailorCollection.doc(tailorId).get();
      if (doc.exists) {
        return Tailor.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'tailor_id': tailorId,
        });
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get tailor by email
  Future<Tailor?> getTailorByEmail(String email) async {
    try {
      final query = await _tailorCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      return Tailor.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'tailor_id': doc.id,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get all tailors (with optional filters)
  Future<List<Tailor>> getAllTailors({
    String? category,
    bool? isVerified,
  }) async {
    try {
      Query query = _tailorCollection;

      if (category != null) {
        query = query.where('category', arrayContains: category);
      }

      if (isVerified != null) {
        query = query.where('is_verified', isEqualTo: isVerified);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Tailor.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'tailor_id': doc.id,
              }))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== UPDATE OPERATIONS ====================

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
  Future<void> addReview({
    required String tailorId,
    required int rating,
  }) async {
    try {
      await _tailorCollection.doc(tailorId).update({
        'review': rating,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Verify tailor
  Future<void> verifyTailor(String tailorId) async {
    try {
      await _tailorCollection.doc(tailorId).update({
        'is_verified': true,
        'verfication_status': 'verified',
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== DELETE OPERATIONS ====================

  /// Delete tailor
  Future<void> deleteTailor(String tailorId) async {
    try {
      await _tailorCollection.doc(tailorId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== SEARCH OPERATIONS ====================

  /// Search tailors by name
  Future<List<Tailor>> searchTailorsByName(String name) async {
    try {
      final snapshot = await _tailorCollection
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThan: '${name}z')
          .get();

      return snapshot.docs
          .map((doc) => Tailor.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'tailor_id': doc.id,
              }))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get nearby tailors (based on latitude/longitude range)
  Future<List<Tailor>> getNearbyTailors({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // Simple box search - can be improved with geohashing
      final latRange = radiusKm / 111.0;
      final lngRange = radiusKm / (111.0 * (1 - (latitude / 90.0).abs()));

      final snapshot = await _tailorCollection
          .where('latitude', isGreaterThan: latitude - latRange)
          .where('latitude', isLessThan: latitude + latRange)
          .where('longitude', isGreaterThan: longitude - lngRange)
          .where('longitude', isLessThan: longitude + lngRange)
          .get();

      return snapshot.docs
          .map((doc) => Tailor.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'tailor_id': doc.id,
              }))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Get featured tailors (verified and high-rated)
  Future<List<Tailor>> getFeaturedTailors({int limit = 10}) async {
    try {
      final snapshot = await _tailorCollection
          .where('is_verified', isEqualTo: true)
          .orderBy('review', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Tailor.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'tailor_id': doc.id,
              }))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}

