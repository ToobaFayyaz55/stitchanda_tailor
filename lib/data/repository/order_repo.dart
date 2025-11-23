import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/data/repository/customer_repo.dart';

/// Repository managing tailor-facing order flows using Firestore.
/// Schema reference:
/// orders: { created_at, customer_id, delivery_date, dropoff_location{full_address,latitude,longitude},
///           order_id, payment_method, payment_status, pickup_location{...}, rider_id, status, tailor_id,
///           total_price, updated_at }
/// order_details: { customer_name, description, details_id, due_data, fabric{dupata_fabric,shirt_fabric,trouser_fabric},
///                  image_path, measurements{arm_length,chest,fitting_preferences,hips,shoulder,waist,wrist},
///                  order_id, price, tailor_id, totalprice }
class OrderRepo {
  // Firestore collections (names per user spec; ensure they match actual Firebase setup)
  final CollectionReference _ordersCol = FirebaseFirestore.instance.collection('order');
  final CustomerRepo _customerRepo;

  OrderRepo({CustomerRepo? customerRepo})
      : _customerRepo = customerRepo ?? CustomerRepo();

  // Helper to get order_details collection - using direct instance to avoid reference issues
  CollectionReference get _orderDetailsCol => FirebaseFirestore.instance.collection('order_details');

  // ==================== STATUS CONSTANTS ====================
  static const int STATUS_REJECTED = -3;   // tailor rejected
  static const int STATUS_UNACCEPTED = -2; // pending tailor action
  static const int STATUS_ACCEPTED = -1;   // tailor accepted
  static const int STATUS_UNASSIGNED = 0;  // customer side
  static const int STATUS_RIDER_ASSIGNED_CUSTOMER = 1;
  static const int STATUS_PICKED_UP_CUSTOMER = 2;
  static const int STATUS_COMPLETED_CUSTOMER = 3; // (original list called 3 Completed - customer side)
  static const int STATUS_RECEIVED_TAILOR = 4;    // tailor received physically
  static const int STATUS_COMPLETED_TAILOR = 5;   // stitching done
  static const int STATUS_CALL_RIDER_TAILOR = 6;  // tailor requested rider
  static const int STATUS_RIDER_ASSIGNED_TAILOR = 7; // rider assigned for return
  static const int STATUS_PICKED_FROM_TAILOR = 8; // picked up from tailor
  static const int STATUS_COMPLETED_TO_CUSTOMER = 9; // delivered to customer
  static const int STATUS_CUSTOMER_CONFIRMED = 10;   // customer confirmed
  static const int STATUS_SELF_DELIVERY = 11;        // tailor self delivery

  // ==================== PUBLIC FETCH METHODS ====================

  /// Fetch all orders for a tailor optionally filtered by statuses.
  /// Returns a list of Map<String,dynamic> representing raw order docs (with 'order_id').
  Future<List<Map<String, dynamic>>> fetchOrdersForTailor(String tailorId, {List<int>? statuses}) async {
    Query query = _ordersCol.where('tailor_id', isEqualTo: tailorId);
    if (statuses != null && statuses.isNotEmpty) {
      // Firestore doesn't support multiple equality OR in one query, so if >1 we must client-filter.
      if (statuses.length == 1) {
        query = query.where('status', isEqualTo: statuses.first);
        final snap = await query.get();
        return snap.docs.map((d) => _orderDocToMap(d)).toList();
      } else {
        final snap = await query.get();
        return snap.docs
            .where((d) => statuses.contains((d.data() as Map<String, dynamic>)['status']))
            .map((d) => _orderDocToMap(d))
            .toList();
      }
    } else {
      final snap = await query.get();
      return snap.docs.map((d) => _orderDocToMap(d)).toList();
    }
  }

  /// Fetch pending (status -2) orders for a tailor.
  Future<List<Map<String, dynamic>>> fetchPendingOrders(String tailorId) =>
      fetchOrdersForTailor(tailorId, statuses: [STATUS_UNACCEPTED]);

  /// Fetch accepted (status -1) orders for a tailor.
  Future<List<Map<String, dynamic>>> fetchAcceptedOrders(String tailorId) =>
      fetchOrdersForTailor(tailorId, statuses: [STATUS_ACCEPTED]);

  /// Fetch a single order by id (returns raw map or null).
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final doc = await _ordersCol.doc(orderId).get();
    if (!doc.exists) return null;
    return _orderDocToMap(doc);
  }

  /// Fetch all details (items) for an order_id.
  /// Status is NOT stored in order_details; consumer should use order status from parent order.
  Future<List<Map<String, dynamic>>> getOrderDetails(String orderId) async {
    final snap = await _orderDetailsCol.where('order_id', isEqualTo: orderId).get();
    return snap.docs.map((d) => _detailDocToMap(d)).toList();
  }

  /// Compatibility method for existing UI expecting OrderDetail objects with injected status.
  /// Joins all tailor's details with their parent order status (status lives only on order).
  Future<List<OrderDetail>> getPendingOrderDetailsForTailor(String tailorId) async {
    final detailsSnap = await _orderDetailsCol.where('tailor_id', isEqualTo: tailorId).get();
    final details = detailsSnap.docs
        .map((d) => OrderDetail.fromMap({...d.data() as Map<String, dynamic>, 'details_id': d.id}))
        .toList();
    if (details.isEmpty) return details;
    final orderIds = details.map((e) => e.orderId).toSet().toList();
    final statusMap = await _bulkFetchStatuses(orderIds);
    return details
        .map((od) => od.copyWith(status: statusMap[od.orderId] ?? STATUS_UNACCEPTED))
        .toList()
      ..sort((a, b) => _timestampToDate(b.createdAt).compareTo(_timestampToDate(a.createdAt)));
  }

  /// Fetch single detail (compat) plus inject status from parent order.
  Future<OrderDetail?> getOrderDetailById(String detailsId) async {
    final doc = await _orderDetailsCol.doc(detailsId).get();
    if (!doc.exists) return null;
    final raw = doc.data() as Map<String, dynamic>;
    final orderId = raw['order_id'] as String? ?? '';
    int status = STATUS_UNACCEPTED;
    if (orderId.isNotEmpty) {
      final orderDoc = await _ordersCol.doc(orderId).get();
      if (orderDoc.exists) {
        status = (orderDoc.data() as Map<String, dynamic>)['status'] as int? ?? STATUS_UNACCEPTED;
      }
    }
    return OrderDetail.fromMap({...raw, 'details_id': doc.id, 'status': status});
  }

  // ==================== MUTATION METHODS ====================

  /// Accept order (status -2 -> -1). Concurrency safe via transaction.
  Future<void> acceptOrder(String orderId, String tailorId) async {
    await _transition(orderId, tailorId, from: STATUS_UNACCEPTED, to: STATUS_ACCEPTED);
  }

  /// Reject order (status -2 -> -3).
  Future<void> rejectOrder(String orderId, String tailorId) async {
    await _transition(orderId, tailorId, from: STATUS_UNACCEPTED, to: STATUS_REJECTED);
  }

  /// Generic status update without from-state guard (use with caution for future flows).
  Future<void> updateOrderStatus(String orderId, int newStatus, {Map<String, dynamic> extra = const {}, String? tailorId}) async {
    final ref = _ordersCol.doc(orderId);
    await ref.update({
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
      ...extra,
      if (tailorId != null) 'tailor_id': tailorId,
    });
  }

  // ==================== COMPATIBILITY METHODS FOR EXISTING CUBIT ====================

  /// Existing UI calls tailorAcceptRequest(detailsId,...). Provide shim using detail -> order lookup.
  Future<void> tailorAcceptRequest({required String detailsId, required String tailorId}) async {
    final orderId = await _orderIdFromDetail(detailsId);
    await acceptOrder(orderId, tailorId);
  }

  /// Existing UI calls tailorRejectRequest(detailsId,...). Provide shim.
  Future<void> tailorRejectRequest({required String detailsId, required String tailorId}) async {
    final orderId = await _orderIdFromDetail(detailsId);
    await rejectOrder(orderId, tailorId);
  }

  // ==================== STREAMS ====================
  Stream<List<Map<String, dynamic>>> streamOrdersForTailor(String tailorId, {List<int>? statuses}) {
    Query base = _ordersCol.where('tailor_id', isEqualTo: tailorId);

    // Helper to map and sort by created_at desc
    List<Map<String, dynamic>> _mapAndSort(QuerySnapshot snap) {
      final list = snap.docs.map((d) => _orderDocToMap(d)).toList();
      list.sort((a, b) => _toDateTime(b['created_at']).compareTo(_toDateTime(a['created_at'])));
      return list;
    }

    if (statuses == null || statuses.isEmpty) {
      return base.snapshots().map(_mapAndSort);
    }
    if (statuses.length == 1) {
      return base.where('status', isEqualTo: statuses.first).snapshots().map(_mapAndSort);
    }
    if (statuses.length <= 10) {
      // Firestore supports whereIn up to 10 items
      return base.where('status', whereIn: statuses).snapshots().map(_mapAndSort);
    }
    // Fallback: client-side filter
    return base.snapshots().map((snap) {
      final list = _mapAndSort(snap).where((m) => statuses.contains(m['status'] as int? ?? -999)).toList();
      return list;
    });
  }

  /// Stream orders for tailor with customer names enriched
  Stream<List<Map<String, dynamic>>> streamOrdersForTailorWithCustomerNames(
    String tailorId,
    {List<int>? statuses}
  ) async* {
    await for (final orders in streamOrdersForTailor(tailorId, statuses: statuses)) {
      final enrichedOrders = <Map<String, dynamic>>[];
      for (final order in orders) {
        enrichedOrders.add(await enrichOrderWithCustomerName(order));
      }
      yield enrichedOrders;
    }
  }

  Stream<List<Map<String, dynamic>>> streamOrderDetails(String orderId) {
    return _orderDetailsCol
        .where('order_id', isEqualTo: orderId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _detailDocToMap(d)).toList());
  }

  Stream<Map<String, dynamic>?> streamOrder(String orderId) {
    return _ordersCol.doc(orderId).snapshots().map((snap) => snap.exists ? _orderDocToMap(snap) : null);
  }

  DateTime _toDateTime(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ==================== INTERNAL HELPERS ====================

  Map<String, dynamic> _orderDocToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Use the order_id from the document data if it exists, otherwise use document ID
    final orderId = data['order_id'] as String? ?? doc.id;
    return {
      ...data,
      'order_id': orderId,
    };
  }

  Map<String, dynamic> _detailDocToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      ...data,
      'details_id': doc.id,
    };
  }

  Future<String> _orderIdFromDetail(String detailsId) async {
    final d = await _orderDetailsCol.doc(detailsId).get();
    if (!d.exists) throw Exception('Order detail not found');
    final data = d.data() as Map<String, dynamic>;
    final orderId = data['order_id'] as String? ?? '';
    if (orderId.isEmpty) throw Exception('order_id missing in order detail');
    return orderId;
  }

  Future<void> _transition(String orderId, String tailorId, {required int from, required int to}) async {
    final ref = _ordersCol.doc(orderId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Order not found');
      final data = snap.data() as Map<String, dynamic>;
      final current = (data['status'] ?? -999) as int;
      final existingTailor = (data['tailor_id'] as String?) ?? tailorId; // if not set yet, allow set
      if (existingTailor.isNotEmpty && existingTailor != tailorId) {
        // Another tailor already owns it
        throw Exception('Order assigned to another tailor');
      }
      if (current != from) {
        throw Exception('Invalid state transition (expected $from, found $current)');
      }
      tx.update(ref, {
        'status': to,
        'tailor_id': tailorId,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Map<String, int>> _bulkFetchStatuses(List<String> orderIds) async {
    final Map<String, int> map = {};
    if (orderIds.isEmpty) return map;
    const chunkSize = 10; // Firestore whereIn limit
    for (var i = 0; i < orderIds.length; i += chunkSize) {
      final sub = orderIds.sublist(i, i + chunkSize > orderIds.length ? orderIds.length : i + chunkSize);
      final snap = await _ordersCol.where(FieldPath.documentId, whereIn: sub).get();
      for (final d in snap.docs) {
        map[d.id] = (d.data() as Map<String, dynamic>)['status'] as int? ?? STATUS_UNACCEPTED;
      }
    }
    return map;
  }

  DateTime _timestampToDate(Timestamp? ts) => ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Enrich a single order with customer name and earliest delivery date
  Future<Map<String, dynamic>> enrichOrderWithCustomerName(Map<String, dynamic> order) async {
    final customerId = order['customer_id'] as String?;
    if (customerId != null && customerId.isNotEmpty) {
      final customerName = await _customerRepo.getCustomerName(customerId);
      if (customerName != null) {
        order['customer_name'] = customerName;
      }
    }

    // If delivery_date already present on order doc (Timestamp), keep it. Otherwise derive from order_details due_data.
    if (order['delivery_date'] == null) {
      final orderId = order['order_id'] as String?;
      if (orderId != null && orderId.isNotEmpty) {
        try {
          final detailsSnap = await _orderDetailsCol.where('order_id', isEqualTo: orderId).get();

          String? earliestDueDateStr;
          DateTime? earliestDateTime;

            for (final doc in detailsSnap.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final dueData = data['due_data'] as String?; // still stored as due_data in order_details
              if (dueData != null && dueData.isNotEmpty) {
                try {
                  final dt = DateTime.parse(dueData);
                  if (earliestDateTime == null || dt.isBefore(earliestDateTime)) {
                    earliestDateTime = dt;
                    earliestDueDateStr = dueData;
                  }
                } catch (_) {}
              }
            }

          if (earliestDateTime != null) {
            // Store as ISO string if we derived it (since we don't have server Timestamp here)
            order['delivery_date'] = earliestDueDateStr;
          }
        } catch (_) {
          // ignore enrichment failure
        }
      }
    }

    return order;
  }

  /// Enrich multiple orders with customer names
  Future<List<Map<String, dynamic>>> enrichOrdersWithCustomerNames(List<Map<String, dynamic>> orders) async {
    final enrichedOrders = <Map<String, dynamic>>[];
    for (final order in orders) {
      enrichedOrders.add(await enrichOrderWithCustomerName(order));
    }
    return enrichedOrders;
  }

  /// Fetch all orders for a tailor with customer names enriched
  Future<List<Map<String, dynamic>>> fetchOrdersForTailorWithCustomerNames(
    String tailorId,
    {List<int>? statuses}
  ) async {
    final orders = await fetchOrdersForTailor(tailorId, statuses: statuses);
    return await enrichOrdersWithCustomerNames(orders);
  }
}
