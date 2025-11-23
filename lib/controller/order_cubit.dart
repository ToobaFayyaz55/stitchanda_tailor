import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/data/repository/order_repo.dart';

// ==================== STATES ====================

sealed class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState { const OrderInitial(); }
class OrderLoading extends OrderState { const OrderLoading(); }

class OrderDetailsSuccess extends OrderState {
  final List<OrderDetail> orderDetails;
  const OrderDetailsSuccess(this.orderDetails);
  @override
  List<Object?> get props => [orderDetails];
}

class OrdersListSuccess extends OrderState {
  final List<Map<String, dynamic>> orders; // raw order maps with order_id
  const OrdersListSuccess(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderItemsSuccess extends OrderState {
  final String orderId;
  final List<Map<String, dynamic>> items; // order_details docs
  const OrderItemsSuccess(this.orderId, this.items);
  @override
  List<Object?> get props => [orderId, items];
}

class RequestAccepted extends OrderState { const RequestAccepted(); }
class RequestRejected extends OrderState { const RequestRejected(); }

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
  @override
  List<Object?> get props => [message];
}

// ==================== CUBIT ====================

class OrderCubit extends Cubit<OrderState> {
  final OrderRepo orderRepo;
  OrderCubit({required this.orderRepo}) : super(const OrderInitial());

  // ---------- Existing compatibility: details list joined with order.status ----------
  Future<void> fetchPendingOrderDetailsForTailor(String tailorId) async {
    try {
      emit(const OrderLoading());
      final orderDetails = await orderRepo.getPendingOrderDetailsForTailor(tailorId);
      emit(OrderDetailsSuccess(orderDetails));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> getOrderDetailById(String detailsId) async {
    try {
      emit(const OrderLoading());
      final orderDetail = await orderRepo.getOrderDetailById(detailsId);
      if (orderDetail != null) {
        emit(OrderDetailsSuccess([orderDetail]));
      } else {
        emit(const OrderError('Order detail not found'));
      }
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ---------- New: Order-level fetching ----------
  Future<void> fetchPendingOrdersForTailor(String tailorId) async {
    try {
      emit(const OrderLoading());
      final orders = await orderRepo.fetchPendingOrders(tailorId);
      emit(OrdersListSuccess(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> fetchAcceptedOrdersForTailor(String tailorId) async {
    try {
      emit(const OrderLoading());
      final orders = await orderRepo.fetchAcceptedOrders(tailorId);
      emit(OrdersListSuccess(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> fetchOrdersForTailor(String tailorId, {List<int>? statuses}) async {
    try {
      emit(const OrderLoading());
      final orders = await orderRepo.fetchOrdersForTailor(tailorId, statuses: statuses);
      emit(OrdersListSuccess(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// NEW: Fetch orders with customer names enriched
  Future<void> fetchOrdersForTailorWithCustomerNames(String tailorId, {List<int>? statuses}) async {
    try {
      emit(const OrderLoading());
      final orders = await orderRepo.fetchOrdersForTailorWithCustomerNames(tailorId, statuses: statuses);
      emit(OrdersListSuccess(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> fetchOrderItems(String orderId) async {
    try {
      emit(const OrderLoading());
      final items = await orderRepo.getOrderDetails(orderId);
      emit(OrderItemsSuccess(orderId, items));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ---------- New: accept/reject by orderId ----------
  Future<void> acceptOrderById({required String orderId, required String tailorId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.acceptOrder(orderId, tailorId);
      emit(const RequestAccepted());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> rejectOrderById({required String orderId, required String tailorId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.rejectOrder(orderId, tailorId);
      emit(const RequestRejected());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Confirm material received by tailor (status 3 -> 4)
  Future<void> confirmMaterialReceived({required String orderId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.updateOrderStatus(orderId, OrderRepo.STATUS_RECEIVED_TAILOR);
      emit(const RequestAccepted()); // Reuse existing success state
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Mark order as completed by tailor (status 4 -> 5)
  Future<void> markOrderCompleted({required String orderId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.updateOrderStatus(orderId, OrderRepo.STATUS_COMPLETED_TAILOR);
      emit(const RequestAccepted()); // Reuse existing success state
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Call rider for pickup (status 5 -> 6)
  Future<void> callRider({required String orderId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.updateOrderStatus(orderId, OrderRepo.STATUS_CALL_RIDER_TAILOR);
      emit(const RequestAccepted()); // Reuse existing success state
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Mark order as self delivery (tailor will deliver) -> status 9
  Future<void> markSelfDelivery({required String orderId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.updateOrderStatus(orderId, OrderRepo.STATUS_COMPLETED_TO_CUSTOMER);
      emit(const RequestAccepted());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ---------- Existing compatibility: accept/reject by detailsId ----------
  Future<void> tailorAcceptRequest({required String detailsId, required String tailorId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorAcceptRequest(detailsId: detailsId, tailorId: tailorId);
      emit(const RequestAccepted());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> tailorRejectRequest({required String detailsId, required String tailorId}) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorRejectRequest(detailsId: detailsId, tailorId: tailorId);
      emit(const RequestRejected());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ---------- Streams ----------
  Stream<List<Map<String, dynamic>>> streamOrdersForTailor(String tailorId, {List<int>? statuses}) {
    return orderRepo.streamOrdersForTailor(tailorId, statuses: statuses);
  }

  Stream<List<Map<String, dynamic>>> streamOrdersForTailorWithCustomerNames(String tailorId, {List<int>? statuses}) {
    return orderRepo.streamOrdersForTailorWithCustomerNames(tailorId, statuses: statuses);
  }

  Stream<List<Map<String, dynamic>>> streamOrderItems(String orderId) {
    return orderRepo.streamOrderDetails(orderId);
  }

  Stream<Map<String, dynamic>?> streamOrder(String orderId) => orderRepo.streamOrder(orderId);

  // ==================== STATUS HELPERS ====================

  /// Get all status values for different order states
  static int get statusUnaccepted => OrderRepo.STATUS_UNACCEPTED;
  static int get statusAccepted => OrderRepo.STATUS_ACCEPTED;
  static int get statusRejected => OrderRepo.STATUS_REJECTED;
  static int get statusUnassigned => OrderRepo.STATUS_UNASSIGNED;
  static int get statusRiderAssignedCustomer => OrderRepo.STATUS_RIDER_ASSIGNED_CUSTOMER;
  static int get statusPickedUpCustomer => OrderRepo.STATUS_PICKED_UP_CUSTOMER;
  static int get statusCompletedCustomer => OrderRepo.STATUS_COMPLETED_CUSTOMER;
  static int get statusReceivedTailor => OrderRepo.STATUS_RECEIVED_TAILOR;
  static int get statusCompletedTailor => OrderRepo.STATUS_COMPLETED_TAILOR;
  static int get statusCallRiderTailor => OrderRepo.STATUS_CALL_RIDER_TAILOR;
  static int get statusRiderAssignedTailor => OrderRepo.STATUS_RIDER_ASSIGNED_TAILOR;
  static int get statusPickedFromTailor => OrderRepo.STATUS_PICKED_FROM_TAILOR;
  static int get statusCompletedToCustomer => OrderRepo.STATUS_COMPLETED_TO_CUSTOMER;
  static int get statusCustomerConfirmed => OrderRepo.STATUS_CUSTOMER_CONFIRMED;
  static int get statusSelfDelivery => OrderRepo.STATUS_SELF_DELIVERY;

  /// Get status label for display
  static String getStatusLabel(int status) {
    if (status == OrderRepo.STATUS_UNACCEPTED) return 'Pending';
    if (status == OrderRepo.STATUS_ACCEPTED) return 'Accepted';
    if (status == OrderRepo.STATUS_REJECTED) return 'Rejected';
    if (status == OrderRepo.STATUS_UNASSIGNED) return 'Customer Waiting for Rider';
    if (status == OrderRepo.STATUS_RIDER_ASSIGNED_CUSTOMER) return 'Rider Assigned to Customer';
    if (status == OrderRepo.STATUS_PICKED_UP_CUSTOMER) return 'Picked Up From Customer';
    if (status == OrderRepo.STATUS_COMPLETED_CUSTOMER) return 'Delivered'; // Changed from 'Completed' to 'Delivered'
    if (status == OrderRepo.STATUS_RECEIVED_TAILOR) return 'Received';
    if (status == OrderRepo.STATUS_COMPLETED_TAILOR) return 'Stitching Done';
    if (status == OrderRepo.STATUS_CALL_RIDER_TAILOR) return 'Call Rider by Tailor';
    if (status == OrderRepo.STATUS_RIDER_ASSIGNED_TAILOR) return 'Rider Assigned by Tailor';
    if (status == OrderRepo.STATUS_PICKED_FROM_TAILOR) return 'Picked Up From Tailor';
    if (status == OrderRepo.STATUS_COMPLETED_TO_CUSTOMER) return 'Delivered to Customer\n(Awaiting for Payment)';
    if (status == OrderRepo.STATUS_CUSTOMER_CONFIRMED) return 'Confirmed by Customer';
    if (status == OrderRepo.STATUS_SELF_DELIVERY) return 'Self Delivery';
    return 'Unknown';
  }

  /// Get status color for display
  static Color getStatusColor(int status) {
    if (status == OrderRepo.STATUS_UNACCEPTED) return Colors.orange;
    if (status == OrderRepo.STATUS_REJECTED) return Colors.grey;
    if (status == OrderRepo.STATUS_ACCEPTED) return Colors.blue;
    if (status == OrderRepo.STATUS_UNASSIGNED) return Colors.blueGrey;
    if (status == OrderRepo.STATUS_RIDER_ASSIGNED_CUSTOMER) return Colors.indigo;
    if (status == OrderRepo.STATUS_PICKED_UP_CUSTOMER) return Colors.purple;
    if (status == OrderRepo.STATUS_COMPLETED_CUSTOMER) return Colors.green;
    if (status == OrderRepo.STATUS_RECEIVED_TAILOR) return Colors.cyan;
    if (status == OrderRepo.STATUS_COMPLETED_TAILOR) return Colors.teal;
    if (status == OrderRepo.STATUS_CALL_RIDER_TAILOR) return Colors.deepOrange;
    if (status == OrderRepo.STATUS_RIDER_ASSIGNED_TAILOR) return Colors.deepPurple;
    if (status == OrderRepo.STATUS_PICKED_FROM_TAILOR) return Colors.amber;
    if (status == OrderRepo.STATUS_COMPLETED_TO_CUSTOMER) return Colors.lightGreen;
    if (status == OrderRepo.STATUS_CUSTOMER_CONFIRMED) return Colors.green.shade700;
    if (status == OrderRepo.STATUS_SELF_DELIVERY) return Colors.brown;
    return Colors.black45;
  }

  /// Get list of statuses for "in progress" filter
  static List<int> get inProgressStatuses => [
    OrderRepo.STATUS_ACCEPTED,
    OrderRepo.STATUS_UNASSIGNED,
    OrderRepo.STATUS_RIDER_ASSIGNED_CUSTOMER,
    OrderRepo.STATUS_PICKED_UP_CUSTOMER,
    OrderRepo.STATUS_COMPLETED_CUSTOMER,
    OrderRepo.STATUS_RECEIVED_TAILOR,
    OrderRepo.STATUS_COMPLETED_TAILOR,
  ];

  /// Get list of statuses for "completed" filter
  static List<int> get completedStatuses => [
    OrderRepo.STATUS_REJECTED,
    OrderRepo.STATUS_CALL_RIDER_TAILOR,
    OrderRepo.STATUS_RIDER_ASSIGNED_TAILOR,
    OrderRepo.STATUS_PICKED_FROM_TAILOR,
    OrderRepo.STATUS_COMPLETED_TO_CUSTOMER,
    OrderRepo.STATUS_CUSTOMER_CONFIRMED,
    OrderRepo.STATUS_SELF_DELIVERY,
  ];
}
