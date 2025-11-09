import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String driverId;
  final String name;
  final String phone;
  final String email;
  final double rating;
  final String profileImagePath;
  final String vehicleType; // 'motorcycle', 'car', 'van', etc.
  final bool availability;
  final Map<String, dynamic>? address;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Driver({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.email,
    required this.rating,
    required this.profileImagePath,
    required this.vehicleType,
    required this.availability,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      driverId: map['driver_id'] as String? ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      profileImagePath: map['profile_image_path'] as String? ?? '',
      vehicleType: map['vehicle_type'] as String? ?? 'motorcycle',
      availability: map['availability'] as bool? ?? false,
      address: map['address'] as Map<String, dynamic>?,
      createdAt: map['created_at'] as Timestamp?,
      updatedAt: map['updated_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'name': name,
      'phone': phone,
      'email': email,
      'rating': rating,
      'profile_image_path': profileImagePath,
      'vehicle_type': vehicleType,
      'availability': availability,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Driver copyWith({
    String? driverId,
    String? name,
    String? phone,
    String? email,
    double? rating,
    String? profileImagePath,
    String? vehicleType,
    bool? availability,
    Map<String, dynamic>? address,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Driver(
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      vehicleType: vehicleType ?? this.vehicleType,
      availability: availability ?? this.availability,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Driver(driverId: $driverId, name: $name, rating: $rating)';
}

