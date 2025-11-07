import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetail {
  final String detailsId;
  final String orderId;
  final String tailorId;
  final String customerId;
  final String customerName;
  final String description;
  final double price;
  final double totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final int status; // -1, 0, 1, 2, etc.
  final DateTime? dueDate;
  final Fabric? fabric;
  final Measurements? measurements;
  final List<OrderItem>? orderDetails;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  OrderDetail({
    required this.detailsId,
    required this.orderId,
    required this.tailorId,
    required this.customerId,
    required this.customerName,
    required this.description,
    required this.price,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.dueDate,
    this.fabric,
    this.measurements,
    this.orderDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderDetail.fromMap(Map<String, dynamic> map) {
    return OrderDetail(
      detailsId: map['details_id'] as String? ?? '',
      orderId: map['order_id'] as String? ?? '',
      tailorId: map['tailor_id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalprice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      paymentStatus: map['paymentStatus'] as String? ?? 'Pending',
      status: map['status'] as int? ?? -1,
      dueDate: map['due_data'] != null
          ? DateTime.tryParse(map['due_data'] as String)
          : null,
      fabric: map['fabric'] != null
          ? Fabric.fromMap(map['fabric'] as Map<String, dynamic>)
          : null,
      measurements: map['measurements'] != null
          ? Measurements.fromMap(map['measurements'] as Map<String, dynamic>)
          : null,
      orderDetails: map['orderDetails'] != null
          ? List<OrderItem>.from(
              (map['orderDetails'] as List).map(
                (item) => OrderItem.fromMap(item as Map<String, dynamic>),
              ),
            )
          : null,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'details_id': detailsId,
      'order_id': orderId,
      'tailor_id': tailorId,
      'customerId': customerId,
      'customer_name': customerName,
      'description': description,
      'price': price,
      'totalprice': totalPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'due_data': dueDate?.toIso8601String(),
      'fabric': fabric?.toMap(),
      'measurements': measurements?.toMap(),
      'orderDetails': orderDetails?.map((item) => item.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  OrderDetail copyWith({
    String? detailsId,
    String? orderId,
    String? tailorId,
    String? customerId,
    String? customerName,
    String? description,
    double? price,
    double? totalPrice,
    String? paymentMethod,
    String? paymentStatus,
    int? status,
    DateTime? dueDate,
    Fabric? fabric,
    Measurements? measurements,
    List<OrderItem>? orderDetails,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return OrderDetail(
      detailsId: detailsId ?? this.detailsId,
      orderId: orderId ?? this.orderId,
      tailorId: tailorId ?? this.tailorId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      description: description ?? this.description,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      fabric: fabric ?? this.fabric,
      measurements: measurements ?? this.measurements,
      orderDetails: orderDetails ?? this.orderDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'OrderDetail(orderId: $orderId, status: $status, totalPrice: $totalPrice)';
}

class Fabric {
  final String shirtFabric;
  final String trouserFabric;
  final String dupatFabric;

  Fabric({
    required this.shirtFabric,
    required this.trouserFabric,
    required this.dupatFabric,
  });

  factory Fabric.fromMap(Map<String, dynamic> map) {
    return Fabric(
      shirtFabric: map['shirt_fabric'] as String? ?? '',
      trouserFabric: map['trouser_fabric'] as String? ?? '',
      dupatFabric: map['dupata_fabric'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shirt_fabric': shirtFabric,
      'trouser_fabric': trouserFabric,
      'dupata_fabric': dupatFabric,
    };
  }

  Fabric copyWith({
    String? shirtFabric,
    String? trouserFabric,
    String? dupatFabric,
  }) {
    return Fabric(
      shirtFabric: shirtFabric ?? this.shirtFabric,
      trouserFabric: trouserFabric ?? this.trouserFabric,
      dupatFabric: dupatFabric ?? this.dupatFabric,
    );
  }
}

class Measurements {
  final double chest;
  final double waist;
  final double hips;
  final double shoulder;
  final double armLength;
  final double wrist;
  final double armpit;
  final String fittingPreferences;

  Measurements({
    required this.chest,
    required this.waist,
    required this.hips,
    required this.shoulder,
    required this.armLength,
    required this.wrist,
    required this.armpit,
    required this.fittingPreferences,
  });

  factory Measurements.fromMap(Map<String, dynamic> map) {
    return Measurements(
      chest: (map['chest'] as num?)?.toDouble() ?? 0.0,
      waist: (map['waist'] as num?)?.toDouble() ?? 0.0,
      hips: (map['hips'] as num?)?.toDouble() ?? 0.0,
      shoulder: (map['shoulder'] as num?)?.toDouble() ?? 0.0,
      armLength: (map['arm_length'] as num?)?.toDouble() ?? 0.0,
      wrist: (map['wrist'] as num?)?.toDouble() ?? 0.0,
      armpit: (map['armpit'] as num?)?.toDouble() ?? 0.0,
      fittingPreferences: map['fitting_preferences'] as String? ?? 'Regular Fit',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'shoulder': shoulder,
      'arm_length': armLength,
      'wrist': wrist,
      'armpit': armpit,
      'fitting_preferences': fittingPreferences,
    };
  }

  Measurements copyWith({
    double? chest,
    double? waist,
    double? hips,
    double? shoulder,
    double? armLength,
    double? wrist,
    double? armpit,
    String? fittingPreferences,
  }) {
    return Measurements(
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      shoulder: shoulder ?? this.shoulder,
      armLength: armLength ?? this.armLength,
      wrist: wrist ?? this.wrist,
      armpit: armpit ?? this.armpit,
      fittingPreferences: fittingPreferences ?? this.fittingPreferences,
    );
  }
}

class OrderItem {
  final String id;
  final String clothType;
  final String itemType;
  final double price;
  final String createdAt;

  OrderItem({
    required this.id,
    required this.clothType,
    required this.itemType,
    required this.price,
    required this.createdAt,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
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

  OrderItem copyWith({
    String? id,
    String? clothType,
    String? itemType,
    double? price,
    String? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      clothType: clothType ?? this.clothType,
      itemType: itemType ?? this.itemType,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

