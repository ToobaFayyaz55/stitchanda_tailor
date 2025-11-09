import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stichanda_tailor/data/models/driver_model.dart';

class RideRepo {
  final CollectionReference _orderDetailCollection =
      FirebaseFirestore.instance.collection('orderDetail');
  final CollectionReference _driverCollection =
      FirebaseFirestore.instance.collection('drivers');

  // ==================== RIDE BOOKING STATUS CODES ====================
  static const int STATUS_DRIVER_REQUESTED = 6;
  static const int STATUS_DRIVER_ASSIGNED = 7;
  static const int STATUS_PICKED_FROM_TAILOR = 8;
  static const int STATUS_DELIVERED = 9;

  // ==================== DRIVER FETCH OPERATIONS ====================

  /// Fetch all available drivers from the drivers collection
  Future<List<Driver>> getAvailableDrivers() async {
    try {
      final query = await _driverCollection
          .where('availability', isEqualTo: true)
          .get();

      final results = query.docs
          .map((doc) => Driver.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'driver_id': doc.id,
              }))
          .toList();

      // Sort by rating descending
      results.sort((a, b) => b.rating.compareTo(a.rating));

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single driver by ID
  Future<Driver?> getDriverById(String driverId) async {
    try {
      final doc = await _driverCollection.doc(driverId).get();

      if (doc.exists) {
        return Driver.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'driver_id': doc.id,
        });
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream available drivers for real-time updates
  Stream<List<Driver>> watchAvailableDrivers() {
    return _driverCollection
        .where('availability', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final results = snapshot.docs
          .map((doc) => Driver.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'driver_id': doc.id,
              }))
          .toList();

      // Sort by rating descending
      results.sort((a, b) => b.rating.compareTo(a.rating));

      return results;
    });
  }

  // ==================== RIDE REQUEST OPERATIONS ====================

  /// Tailor presses "Call Driver"
  /// Status transition: 5 → 6
  /// Sets driver_request_at timestamp (awaiting assignment)
  Future<void> requestDriver({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final docRef = _orderDetailCollection.doc(detailsId);
        final snapshot = await tx.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Order not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentStatus = (data['status'] ?? -1) as int;

        // Validate current status (must be 5 - completed by tailor)
        if (currentStatus != 5) {
          throw Exception(
            'Invalid transition: can only request driver when status == 5 (current: $currentStatus)',
          );
        }

        // Update order
        tx.update(docRef, {
          'status': STATUS_DRIVER_REQUESTED,
          'driver_request_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Assign a driver to an order
  /// Status transition: 6 → 7
  /// Sets driver_id and status to assigned
  Future<void> assignDriver({
    required String detailsId,
    required String driverId,
    required String tailorId,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final docRef = _orderDetailCollection.doc(detailsId);
        final snapshot = await tx.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Order not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentStatus = (data['status'] ?? -1) as int;

        // Validate current status (must be 6 - driver requested)
        if (currentStatus != STATUS_DRIVER_REQUESTED) {
          throw Exception(
            'Invalid transition: can only assign driver when status == $STATUS_DRIVER_REQUESTED (current: $currentStatus)',
          );
        }

        // Verify driver exists and is available
        final driverSnapshot = await tx.get(_driverCollection.doc(driverId));
        if (!driverSnapshot.exists) {
          throw Exception('Driver not found');
        }

        final driverData = driverSnapshot.data() as Map<String, dynamic>;
        if (!(driverData['availability'] as bool? ?? false)) {
          throw Exception('Driver is not available');
        }

        // Update order
        tx.update(docRef, {
          'status': STATUS_DRIVER_ASSIGNED,
          'driver_id': driverId,
          'driver_assigned_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mark that rider has picked up the order from tailor
  /// Status transition: 7 → 8
  Future<void> markPickedFromTailor({
    required String detailsId,
    required String driverId,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final docRef = _orderDetailCollection.doc(detailsId);
        final snapshot = await tx.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Order not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentStatus = (data['status'] ?? -1) as int;
        final assignedDriver = data['driver_id'] as String?;

        // Validate current status and driver
        if (currentStatus != STATUS_DRIVER_ASSIGNED) {
          throw Exception(
            'Invalid transition: can only mark pickup when status == $STATUS_DRIVER_ASSIGNED (current: $currentStatus)',
          );
        }

        if (assignedDriver != driverId) {
          throw Exception('Unauthorized: driver mismatch');
        }

        // Update order
        tx.update(docRef, {
          'status': STATUS_PICKED_FROM_TAILOR,
          'picked_from_tailor_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mark delivery complete (system or driver update)
  /// Status transition: 8 → 9
  Future<void> markDeliveryComplete({
    required String detailsId,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final docRef = _orderDetailCollection.doc(detailsId);
        final snapshot = await tx.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Order not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentStatus = (data['status'] ?? -1) as int;

        // Validate current status
        if (currentStatus != STATUS_PICKED_FROM_TAILOR) {
          throw Exception(
            'Invalid transition: can only mark delivery when status == $STATUS_PICKED_FROM_TAILOR (current: $currentStatus)',
          );
        }

        // Update order
        tx.update(docRef, {
          'status': STATUS_DELIVERED,
          'delivered_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== STREAM OPERATIONS ====================

  /// Watch real-time updates for a specific order
  /// Used to detect when driver is assigned by the system
  Stream<Map<String, dynamic>?> watchOrderStatus(String detailsId) {
    return _orderDetailCollection
        .doc(detailsId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
      return null;
    });
  }
}

