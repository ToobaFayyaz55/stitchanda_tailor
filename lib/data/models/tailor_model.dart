import 'package:cloud_firestore/cloud_firestore.dart';

class Tailor {
  final String tailor_id;
  final String name;
  final String email;
  final String phone;
  final String full_address;
  final double latitude;
  final double longitude;
  final bool availibility_status;
  final List<String> category;
  final int? cnic;
  final Timestamp? created_at;
  final Timestamp? updated_at;
  final int? experience;
  final String? gender;
  final String image_path;  // Required with default empty string
  final bool is_verified;   // Required with default false
  final int review;        // Required with default 0
  final String verfication_status; // Required with default 'pending'

  Tailor({
    required this.tailor_id,
    required this.name,
    required this.email,
    required this.phone,
    required this.full_address,
    required this.latitude,
    required this.longitude,
    required this.availibility_status,
    required this.category,
    this.cnic,
    this.created_at,
    this.updated_at,
    this.experience,
    this.gender,
    this.image_path = '',  // Default value
    this.is_verified = false, // Default value
    this.review = 0,         // Default value
    this.verfication_status = 'pending', // Default value
  });

  factory Tailor.fromMap(Map<String, dynamic> map) {
    return Tailor(
      tailor_id: map['tailor_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      full_address: map['full_address'] as String? ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      availibility_status: map['availibility_status'] as bool? ?? true,
      category: List<String>.from(map['category'] ?? <String>[]),
      cnic: map['cnic'] as int?,
      created_at: map['created_at'] as Timestamp?,
      updated_at: map['updated_at'] as Timestamp?,
      experience: map['experience'] as int?,
      gender: map['gender'] as String?,
      image_path: map['image_path'] as String? ?? '',
      is_verified: map['is_verified'] as bool? ?? false,
      review: map['review'] as int? ?? 0,
      verfication_status: map['verfication_status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tailor_id': tailor_id,
      'name': name,
      'email': email,
      'phone': phone,
      'full_address': full_address,
      'latitude': latitude,
      'longitude': longitude,
      'availibility_status': availibility_status,
      'category': category,
      'cnic': cnic,
      'created_at': created_at,
      'updated_at': updated_at,
      'experience': experience,
      'gender': gender,
      'image_path': image_path,
      'is_verified': is_verified,
      'review': review,
      'verfication_status': verfication_status,
    };
  }

  Tailor copyWith({
    String? tailor_id,
    String? name,
    String? email,
    String? phone,
    String? full_address,
    double? latitude,
    double? longitude,
    bool? availibility_status,
    List<String>? category,
    int? cnic,
    Timestamp? created_at,
    Timestamp? updated_at,
    int? experience,
    String? gender,
    String? image_path,
    bool? is_verified,
    int? review,
    String? verfication_status,
  }) {
    return Tailor(
      tailor_id: tailor_id ?? this.tailor_id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      full_address: full_address ?? this.full_address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availibility_status: availibility_status ?? this.availibility_status,
      category: category ?? this.category,
      cnic: cnic ?? this.cnic,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
      experience: experience ?? this.experience,
      gender: gender ?? this.gender,
      image_path: image_path ?? this.image_path,
      is_verified: is_verified ?? this.is_verified,
      review: review ?? this.review,
      verfication_status: verfication_status ?? this.verfication_status,
    );
  }
}