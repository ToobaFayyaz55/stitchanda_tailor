import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stichanda_tailor/data/models/order_model.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';

class OrderRepo {
  final CollectionReference _orderCollection =
      FirebaseFirestore.instance.collection('order');
  final CollectionReference _orderDetailCollection =
      FirebaseFirestore.instance.collection('orderDetail');

  // Helper to normalize various timestamp representations to DateTime
  DateTime _toDateTime(Object? value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ==================== READ OPERATIONS ====================

  /// Get all pending order details for a specific tailor
  Future<List<OrderDetail>> getPendingOrderDetailsForTailor(String tailorId) async {
    try {
      final query = await _orderDetailCollection
          .where('tailor_id', isEqualTo: tailorId)
          .get();

      final results = query.docs
          .map((doc) => OrderDetail.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'details_id': doc.id,
              }))
          .toList();

      // Sort by created_at descending in code instead of using orderBy
      results.sort((a, b) => _toDateTime(b.createdAt).compareTo(_toDateTime(a.createdAt)));

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// Get order detail by ID
  Future<OrderDetail?> getOrderDetailById(String detailsId) async {
    try {
      final doc = await _orderDetailCollection.doc(detailsId).get();

      if (doc.exists) {
        return OrderDetail.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'details_id': doc.id,
        });
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get order by ID
  Future<OrderData?> getOrderById(String orderId) async {
    try {
      final doc = await _orderCollection.doc(orderId).get();

      if (doc.exists) {
        return OrderData.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'orderId': doc.id,
        });
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all orders for a customer
  Future<List<OrderData>> getOrdersByCustomer(String customerId) async {
    try {
      final query = await _orderCollection
          .where('customerId', isEqualTo: customerId)
          .get();

      final results = query.docs
          .map((doc) => OrderData.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'orderId': doc.id,
              }))
          .toList();

      // Sort by createdAt descending in code
      results.sort((a, b) => _toDateTime(b.createdAt).compareTo(_toDateTime(a.createdAt)));

      return results;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== UPDATE OPERATIONS ====================

  /// Update order detail status
  Future<void> updateOrderDetailStatus({
    required String detailsId,
    required int newStatus,
  }) async {
    try {
      await _orderDetailCollection.doc(detailsId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update order payment status
  Future<void> updateOrderPaymentStatus({
    required String orderId,
    required String paymentStatus,
  }) async {
    try {
      await _orderCollection.doc(orderId).update({
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== CREATE OPERATIONS ====================

  /// Create a new order
  Future<String> createOrder({
    required String tailorId,
    required String customerId,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    try {
      final doc = await _orderCollection.add({
        'tailorId': tailorId,
        'customerId': customerId,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'Pending',
        'status': -1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return doc.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Create order detail
  Future<String> createOrderDetail({
    required String orderId,
    required String tailorId,
    required String customerId,
    required String customerName,
    required String description,
    required double price,
    required String paymentStatus,
  }) async {
    try {
      final doc = await _orderDetailCollection.add({
        'order_id': orderId,
        'tailor_id': tailorId,
        'customer_id': customerId,
        'customer_name': customerName,
        'description': description,
        'price': price,
        'totalPrice': price,
        'paymentStatus': paymentStatus,
        'status': -1,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return doc.id;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== DELETE OPERATIONS ====================

  /// Delete order detail
  Future<void> deleteOrderDetail(String detailsId) async {
    try {
      await _orderDetailCollection.doc(detailsId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _orderCollection.doc(orderId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== TAILOR WORKFLOW OPERATIONS ====================
  // These methods enforce strict order status transitions per tailor workflow

  /// Status Constants (Tailor-side relevant)
  static const int STATUS_RECEIVED_BY_TAILOR = 4;
  static const int STATUS_TAILOR_COMPLETED = 5;
  static const int STATUS_DRIVER_REQUESTED = 6;
  static const int STATUS_DRIVER_ASSIGNED = 7;
  static const int STATUS_PICKED_FROM_TAILOR = 8;
  static const int STATUS_DELIVERED = 9;
  static const int STATUS_SELF_DELIVERY = 11;

  /// Tailor presses "Receive Order"
  /// Transition: status 3 → 4
  /// Updates: order_status, received_by_tailor, received_at
  Future<void> tailorReceiveOrder({
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
        final docTailorId = data['tailor_id'] as String?;

        // Validate current status
        if (currentStatus != 3) {
          throw Exception(
            'Invalid transition: can only receive when status == 3 (current: $currentStatus)',
          );
        }

        // Validate tailor ownership
        if (docTailorId != null && docTailorId != tailorId) {
          throw Exception('Unauthorized: tailor mismatch');
        }

        // Update order
        tx.update(docRef, {
          'status': STATUS_RECEIVED_BY_TAILOR,
          'received_by_tailor': true,
          'received_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Tailor presses "Mark as Completed"
  /// Transition: status 4 → 5
  /// Updates: order_status, tailor_completed, completed_at
  Future<void> tailorMarkCompleted({
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
        final docTailorId = data['tailor_id'] as String?;

        // Validate current status
        if (currentStatus != STATUS_RECEIVED_BY_TAILOR) {
          throw Exception(
            'Invalid transition: can only mark completed when status == $STATUS_RECEIVED_BY_TAILOR (current: $currentStatus)',
          );
        }

        // Validate tailor ownership
        if (docTailorId != null && docTailorId != tailorId) {
          throw Exception('Unauthorized: tailor mismatch');
        }

        // Update order
        tx.update(docRef, {
          'status': STATUS_TAILOR_COMPLETED,
          'tailor_completed': true,
          'completed_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Tailor presses "Call Driver"
  /// Transition: status 5 → 6
  /// Updates: order_status, driver_request_at
  Future<void> tailorCallDriver({
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
        final docTailorId = data['tailor_id'] as String?;

        // Validate current status
        if (currentStatus != STATUS_TAILOR_COMPLETED) {
          throw Exception(
            'Invalid transition: can only request driver when status == $STATUS_TAILOR_COMPLETED (current: $currentStatus)',
          );
        }

        // Validate tailor ownership
        if (docTailorId != null && docTailorId != tailorId) {
          throw Exception('Unauthorized: tailor mismatch');
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

  /// Tailor marks order available for customer self-pickup
  /// Transition: status 5 → 11
  /// Updates: order_status, delivered_by, delivered_at
  Future<void> tailorSelfDeliver({
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
        final docTailorId = data['tailor_id'] as String?;

        // Validate current status
        if (currentStatus != STATUS_TAILOR_COMPLETED) {
          throw Exception(
            'Invalid transition: can only self-deliver when status == $STATUS_TAILOR_COMPLETED (current: $currentStatus)',
          );
        }

        // Validate tailor ownership
        if (docTailorId != null && docTailorId != tailorId) {
          throw Exception('Unauthorized: tailor mismatch');
        }

        // Update order
        tx.update(docRef, {
          'status': STATUS_SELF_DELIVERY,
          'delivered_by': 'tailor',
          'delivered_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Helper: Check which button should be shown based on current status
  /// Returns the UI action name or empty string if no button should show
  static String getButtonVisibility(int status) {
    switch (status) {
      case 3:
        return 'Receive Order';
      case STATUS_RECEIVED_BY_TAILOR:
        return 'Mark as Completed';
      case STATUS_TAILOR_COMPLETED:
        return 'Call Driver / Self Delivery';
      case STATUS_DRIVER_REQUESTED:
        return 'Waiting for Driver Assignment';
      case STATUS_DRIVER_ASSIGNED:
        return 'Waiting for Driver Pickup';
      case STATUS_PICKED_FROM_TAILOR:
        return 'Order Picked Up (disabled)';
      default:
        if (status >= STATUS_DELIVERED) {
          return ''; // Hide all buttons
        }
        return '';
    }
  }

  /// Validate if tailor can perform an action on this order
  static bool canTailorActOn(int status) {
    return status >= 3 && status < STATUS_DELIVERED;
  }
}
