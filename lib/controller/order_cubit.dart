import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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

  Stream<List<Map<String, dynamic>>> streamOrderItems(String orderId) {
    return orderRepo.streamOrderDetails(orderId);
  }

  Stream<Map<String, dynamic>?> streamOrder(String orderId) => orderRepo.streamOrder(orderId);
}
