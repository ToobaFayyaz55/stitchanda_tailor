import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stichanda_tailor/data/models/order_model.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/data/repository/order_repo.dart';

// ==================== STATES ====================

sealed class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderDetailsSuccess extends OrderState {
  final List<OrderDetail> orderDetails;

  const OrderDetailsSuccess(this.orderDetails);

  @override
  List<Object?> get props => [orderDetails];
}

class OrdersSuccess extends OrderState {
  final List<OrderData> orders;

  const OrdersSuccess(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderCreated extends OrderState {
  final OrderDetail orderDetail;

  const OrderCreated(this.orderDetail);

  @override
  List<Object?> get props => [orderDetail];
}

class OrderUpdated extends OrderState {
  final OrderDetail orderDetail;

  const OrderUpdated(this.orderDetail);

  @override
  List<Object?> get props => [orderDetail];
}

class OrderDeleted extends OrderState {
  const OrderDeleted();
}

class RequestAccepted extends OrderState {
  const RequestAccepted();
}

class RequestRejected extends OrderState {
  const RequestRejected();
}

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

  // ==================== FETCH OPERATIONS ====================

  Future<void> fetchPendingOrderDetailsForTailor(String tailorId) async {
    try {
      emit(const OrderLoading());
      final orderDetails = await orderRepo.getPendingOrderDetailsForTailor(tailorId);
      emit(OrderDetailsSuccess(orderDetails));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> fetchOrdersByCustomer(String customerId) async {
    try {
      emit(const OrderLoading());
      final orders = await orderRepo.getOrdersByCustomer(customerId);
      emit(OrdersSuccess(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ==================== GET OPERATIONS ====================

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

  Future<void> getOrderById(String orderId) async {
    try {
      emit(const OrderLoading());
      final order = await orderRepo.getOrderById(orderId);
      if (order != null) {
        emit(OrdersSuccess([order]));
      } else {
        emit(const OrderError('Order not found'));
      }
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ==================== UPDATE OPERATIONS ====================

  Future<void> updateOrderDetailStatus({
    required String detailsId,
    required int newStatus,
  }) async {
    try {
      await orderRepo.updateOrderDetailStatus(
        detailsId: detailsId,
        newStatus: newStatus,
      );
      emit(OrderUpdated(OrderDetail(
        detailsId: detailsId,
        orderId: '',
        tailorId: '',
        customerId: '',
        customerName: '',
        description: '',
        price: 0,
        totalPrice: 0,
        paymentMethod: '',
        paymentStatus: '',
        status: newStatus,
      )));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> updateOrderPaymentStatus({
    required String orderId,
    required String paymentStatus,
  }) async {
    try {
      await orderRepo.updateOrderPaymentStatus(
        orderId: orderId,
        paymentStatus: paymentStatus,
      );
      emit(OrderUpdated(OrderDetail(
        detailsId: '',
        orderId: orderId,
        tailorId: '',
        customerId: '',
        customerName: '',
        description: '',
        price: 0,
        totalPrice: 0,
        paymentMethod: '',
        paymentStatus: paymentStatus,
        status: 0,
      )));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ==================== CREATE OPERATIONS ====================

  Future<void> createOrder({
    required String tailorId,
    required String customerId,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    try {
      emit(const OrderLoading());
      final orderId = await orderRepo.createOrder(
        tailorId: tailorId,
        customerId: customerId,
        totalPrice: totalPrice,
        paymentMethod: paymentMethod,
      );
      emit(OrderCreated(OrderDetail(
        detailsId: '',
        orderId: orderId,
        tailorId: tailorId,
        customerId: customerId,
        customerName: '',
        description: '',
        price: 0,
        totalPrice: totalPrice,
        paymentMethod: paymentMethod,
        paymentStatus: 'Pending',
        status: -1,
      )));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ==================== DELETE OPERATIONS ====================

  Future<void> deleteOrderDetail(String detailsId) async {
    try {
      await orderRepo.deleteOrderDetail(detailsId);
      emit(const OrderDeleted());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await orderRepo.deleteOrder(orderId);
      emit(const OrderDeleted());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ==================== REQUEST WORKFLOW ACTIONS ====================

  /// Tailor action: Accept incoming order request
  /// Status transition: -2 → -1
  Future<void> tailorAcceptRequest({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorAcceptRequest(
        detailsId: detailsId,
        tailorId: tailorId,
      );
      emit(const RequestAccepted());
      // Refresh the orders list
      await getOrderDetailById(detailsId);
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Tailor action: Reject incoming order request
  /// Deletes the request
  Future<void> tailorRejectRequest({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorRejectRequest(
        detailsId: detailsId,
        tailorId: tailorId,
      );
      emit(const RequestRejected());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ==================== TAILOR WORKFLOW ACTIONS ====================

  /// Tailor action: Receive incoming order
  /// Status transition: 3 → 4
  Future<void> tailorReceiveOrder({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorReceiveOrder(
        detailsId: detailsId,
        tailorId: tailorId,
      );
      // Fetch updated order to reflect new status
      await getOrderDetailById(detailsId);
      emit(OrderUpdated(OrderDetail(
        detailsId: '',
        orderId: '',
        tailorId: '',
        customerId: '',
        customerName: '',
        description: '',
        price: 0,
        totalPrice: 0,
        paymentMethod: '',
        paymentStatus: '',
        status: OrderRepo.STATUS_RECEIVED_BY_TAILOR,
      )));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Tailor action: Mark stitching as completed
  /// Status transition: 4 → 5
  Future<void> tailorMarkCompleted({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorMarkCompleted(
        detailsId: detailsId,
        tailorId: tailorId,
      );
      // Fetch updated order to reflect new status
      await getOrderDetailById(detailsId);
      emit(OrderUpdated(OrderDetail(
        detailsId: '',
        orderId: '',
        tailorId: '',
        customerId: '',
        customerName: '',
        description: '',
        price: 0,
        totalPrice: 0,
        paymentMethod: '',
        paymentStatus: '',
        status: OrderRepo.STATUS_TAILOR_COMPLETED,
      )));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Tailor action: Request driver pickup
  /// Status transition: 5 → 6
  Future<void> tailorCallDriver({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorCallDriver(
        detailsId: detailsId,
        tailorId: tailorId,
      );
      // Fetch updated order to reflect new status
      await getOrderDetailById(detailsId);
      emit(OrderUpdated(OrderDetail(
        detailsId: '',
        orderId: '',
        tailorId: '',
        customerId: '',
        customerName: '',
        description: '',
        price: 0,
        totalPrice: 0,
        paymentMethod: '',
        paymentStatus: '',
        status: OrderRepo.STATUS_DRIVER_REQUESTED,
      )));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  /// Mark order available for customer self-pickup
  /// Status transition: 5 → 11
  Future<void> tailorSelfDeliver({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      emit(const OrderLoading());
      await orderRepo.tailorSelfDeliver(
        detailsId: detailsId,
        tailorId: tailorId,
      );
      // Fetch updated order to reflect new status
      await getOrderDetailById(detailsId);
      emit(OrderUpdated(OrderDetail(
        detailsId: '',
        orderId: '',
        tailorId: '',
        customerId: '',
        customerName: '',
        description: '',
        price: 0,
        totalPrice: 0,
        paymentMethod: '',
        paymentStatus: '',
        status: OrderRepo.STATUS_SELF_DELIVERY,
      )));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ==================== UI HELPER METHODS ====================

  /// Get button visibility for a given order status
  static String getButtonVisibility(int status) {
    return OrderRepo.getButtonVisibility(status);
  }

  /// Check if tailor can perform actions on this order
  static bool canTailorActOn(int status) {
    return OrderRepo.canTailorActOn(status);
  }
}

