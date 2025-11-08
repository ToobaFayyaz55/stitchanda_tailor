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
}
