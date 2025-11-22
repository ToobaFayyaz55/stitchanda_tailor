import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetail {
  final String detailsId;
  final String orderId;
  final String tailorId;
  final String customerName;
  final String? description;
  final String? imagePath;
  final Fabric? fabric;
  final Measurements? measurements;
  final double price;
  final double? totalPrice;
  final String? dueData; // Note: Firebase has "due_data" - keeping as-is from schema
  final int status; // -1, 0, 1, 2, etc.
  final List<OrderItem>? orderDetails;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  OrderDetail({
    required this.detailsId,
    required this.orderId,
    required this.tailorId,
    required this.customerName,
    this.description,
    this.imagePath,
    this.fabric,
    this.measurements,
    required this.price,
    this.totalPrice,
    this.dueData,
    required this.status,
    this.orderDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderDetail.fromMap(Map<String, dynamic> map) {
    return OrderDetail(
      detailsId: map['details_id'] as String? ?? '',
      orderId: map['order_id'] as String? ?? '',
      tailorId: map['tailor_id'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      description: map['description'] as String?,
      imagePath: map['imagePath'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalprice'] as num?)?.toDouble(),
      dueData: map['due_data'] as String?,
      status: map['status'] as int? ?? -1,
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
      'customer_name': customerName,
      if (description != null) 'description': description,
      if (imagePath != null) 'imagePath': imagePath,
      'price': price,
      if (totalPrice != null) 'totalprice': totalPrice,
      if (dueData != null) 'due_data': dueData,
      'status': status,
      if (fabric != null) 'fabric': fabric!.toMap(),
      if (measurements != null) 'measurements': measurements!.toMap(),
      if (orderDetails != null) 'orderDetails': orderDetails!.map((item) => item.toMap()).toList(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  OrderDetail copyWith({
    String? detailsId,
    String? orderId,
    String? tailorId,
    String? customerName,
    String? description,
    String? imagePath,
    Fabric? fabric,
    Measurements? measurements,
    double? price,
    double? totalPrice,
    String? dueData,
    int? status,
    List<OrderItem>? orderDetails,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return OrderDetail(
      detailsId: detailsId ?? this.detailsId,
      orderId: orderId ?? this.orderId,
      tailorId: tailorId ?? this.tailorId,
      customerName: customerName ?? this.customerName,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      fabric: fabric ?? this.fabric,
      measurements: measurements ?? this.measurements,
      price: price ?? this.price,
      totalPrice: totalPrice ?? this.totalPrice,
      dueData: dueData ?? this.dueData,
      status: status ?? this.status,
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
  final String? shirtFabric;
  final String? trouserFabric;
  final String? dupataFabric;

  Fabric({
    this.shirtFabric,
    this.trouserFabric,
    this.dupataFabric,
  });

  factory Fabric.fromMap(Map<String, dynamic> map) {
    return Fabric(
      shirtFabric: map['shirt_fabric'] as String?,
      trouserFabric: map['trouser_fabric'] as String?,
      dupataFabric: map['dupata_fabric'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (shirtFabric != null) 'shirt_fabric': shirtFabric,
      if (trouserFabric != null) 'trouser_fabric': trouserFabric,
      if (dupataFabric != null) 'dupata_fabric': dupataFabric,
    };
  }

  Fabric copyWith({
    String? shirtFabric,
    String? trouserFabric,
    String? dupataFabric,
  }) {
    return Fabric(
      shirtFabric: shirtFabric ?? this.shirtFabric,
      trouserFabric: trouserFabric ?? this.trouserFabric,
      dupataFabric: dupataFabric ?? this.dupataFabric,
    );
  }
}

class Measurements {
  final double? armLength;
  final double? chest;
  final double? shoulder;
  final double? waist;
  final double? hips;
  final double? wrist;
  final String? fittingPreferences;

  Measurements({
    this.armLength,
    this.chest,
    this.shoulder,
    this.waist,
    this.hips,
    this.wrist,
    this.fittingPreferences,
  });

  factory Measurements.fromMap(Map<String, dynamic> map) {
    return Measurements(
      armLength: (map['arm_length'] as num?)?.toDouble(),
      chest: (map['chest'] as num?)?.toDouble(),
      shoulder: (map['shoulder'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hips: (map['hips'] as num?)?.toDouble(),
      wrist: (map['wrist'] as num?)?.toDouble(),
      fittingPreferences: map['fitting_preferences'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (armLength != null) 'arm_length': armLength,
      if (chest != null) 'chest': chest,
      if (shoulder != null) 'shoulder': shoulder,
      if (waist != null) 'waist': waist,
      if (hips != null) 'hips': hips,
      if (wrist != null) 'wrist': wrist,
      if (fittingPreferences != null) 'fitting_preferences': fittingPreferences,
    };
  }

  Measurements copyWith({
    double? armLength,
    double? chest,
    double? shoulder,
    double? waist,
    double? hips,
    double? wrist,
    String? fittingPreferences,
  }) {
    return Measurements(
      armLength: armLength ?? this.armLength,
      chest: chest ?? this.chest,
      shoulder: shoulder ?? this.shoulder,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      wrist: wrist ?? this.wrist,
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

