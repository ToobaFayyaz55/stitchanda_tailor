import 'package:cloud_firestore/cloud_firestore.dart';

class OrderData {
  final String orderId;
  final String tailorId;
  final String customerId;
  final double totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final List<OrderItemData>? orderDetails;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final int status;

  OrderData({
    required this.orderId,
    required this.tailorId,
    required this.customerId,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.orderDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderData.fromMap(Map<String, dynamic> map) {
    return OrderData(
      orderId: map['orderId'] as String? ?? '',
      tailorId: map['tailorId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      paymentStatus: map['paymentStatus'] as String? ?? 'Pending',
      status: map['status'] as int? ?? 0,
      orderDetails: map['orderDetails'] != null
          ? List<OrderItemData>.from(
              (map['orderDetails'] as List).map(
                (item) => OrderItemData.fromMap(item as Map<String, dynamic>),
              ),
            )
          : null,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'tailorId': tailorId,
      'customerId': customerId,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderDetails': orderDetails?.map((item) => item.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status,
    };
  }

  OrderData copyWith({
    String? orderId,
    String? tailorId,
    String? customerId,
    double? totalPrice,
    String? paymentMethod,
    String? paymentStatus,
    List<OrderItemData>? orderDetails,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? status,
  }) {
    return OrderData(
      orderId: orderId ?? this.orderId,
      tailorId: tailorId ?? this.tailorId,
      customerId: customerId ?? this.customerId,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderDetails: orderDetails ?? this.orderDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'OrderData(orderId: $orderId, status: $status, totalPrice: $totalPrice)';
}

class OrderItemData {
  final String id;
  final String clothType;
  final String itemType;
  final double price;
  final String createdAt;

  OrderItemData({
    required this.id,
    required this.clothType,
    required this.itemType,
    required this.price,
    required this.createdAt,
  });

  factory OrderItemData.fromMap(Map<String, dynamic> map) {
    return OrderItemData(
      id: map['id'] as String? ?? '',
      clothType: map['clothType'] as String? ?? '',
      itemType: map['itemType'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clothType': clothType,
      'itemType': itemType,
      'price': price,
      'createdAt': createdAt,
    };
  }

  OrderItemData copyWith({
    String? id,
    String? clothType,
    String? itemType,
    double? price,
    String? createdAt,
  }) {
    return OrderItemData(
      id: id ?? this.id,
      clothType: clothType ?? this.clothType,
      itemType: itemType ?? this.itemType,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

