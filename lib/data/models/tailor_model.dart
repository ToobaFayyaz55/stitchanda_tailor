import 'package:cloud_firestore/cloud_firestore.dart';

class TailorAddress {
  final String full_address;
  final double latitude;
  final double longitude;
  const TailorAddress({
    required this.full_address,
    required this.latitude,
    required this.longitude,
  });
  factory TailorAddress.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TailorAddress(full_address: '', latitude: 0.0, longitude: 0.0);
    return TailorAddress(
      full_address: map['full_address'] as String? ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
    );
  }
  Map<String, dynamic> toMap() => {
        'full_address': full_address,
        'latitude': latitude,
        'longitude': longitude,
      };
  TailorAddress copyWith({String? full_address, double? latitude, double? longitude}) => TailorAddress(
        full_address: full_address ?? this.full_address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}

class Tailor {
  final String tailor_id;
  final String name;
  final String email;
  final String phone;
  final int cnic;
  final String gender; // 'male' | 'female' | 'other'
  final List<String> category; // ('male' | 'female' | 'both')[]
  final int experience;
  final double review; // review rating (can be decimal like 4.5)
  final bool availibility_status;
  final bool is_verified;
  final int verification_status; // 0 | 1 | 2
  final TailorAddress address;
  final String image_path; // profile avatar only
  final String cnic_front_image_path; // new field
  final String cnic_back_image_path; // new field
  final String stripe_account_id; // non-null, empty if not yet created
  final Timestamp created_at;
  final Timestamp updated_at;

  const Tailor({
    required this.tailor_id,
    required this.name,
    required this.email,
    required this.phone,
    required this.cnic,
    required this.gender,
    required this.category,
    required this.experience,
    required this.review,
    required this.availibility_status,
    required this.is_verified,
    required this.verification_status,
    required this.address,
    required this.image_path,
    required this.cnic_front_image_path,
    required this.cnic_back_image_path,
    required this.stripe_account_id,
    required this.created_at,
    required this.updated_at,
  });

  factory Tailor.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic>? addressMap = map['address'] as Map<String, dynamic>? ?? {
      'full_address': map['full_address'],
      'latitude': map['latitude'],
      'longitude': map['longitude'],
    };
    return Tailor(
      tailor_id: map['tailor_id'] as String? ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      cnic: (map['cnic'] is int)
          ? map['cnic'] as int
          : int.tryParse(map['cnic']?.toString() ?? '') ?? 0,
      gender: map['gender'] as String? ?? 'male',
      category: (map['category'] is List)
          ? List<String>.from((map['category'] as List).map((e) => e.toString()))
          : <String>[],
      experience: (map['experience'] is int) ? map['experience'] as int : int.tryParse(map['experience']?.toString() ?? '') ?? 0,
      review: (map['review'] is num) ? (map['review'] as num).toDouble() : double.tryParse(map['review']?.toString() ?? '') ?? 0.0,
      availibility_status: map['availibility_status'] as bool? ?? true,
      is_verified: map['is_verified'] as bool? ?? false,
      verification_status: map['verification_status'] as int?
          ?? map['verfication_status'] as int?
          ?? 0,
      address: TailorAddress.fromMap(addressMap),
      image_path: map['image_path'] as String? ?? '',
      cnic_front_image_path: map['cnic_front_image_path'] as String? ?? map['cnic_front_url'] as String? ?? '',
      cnic_back_image_path: map['cnic_back_image_path'] as String? ?? map['cnic_back_url'] as String? ?? '',
      stripe_account_id: map['stripe_account_id'] as String? ?? '',
      created_at: map['created_at'] is Timestamp ? map['created_at'] as Timestamp : Timestamp.now(),
      updated_at: map['updated_at'] is Timestamp ? map['updated_at'] as Timestamp : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'tailor_id': tailor_id,
        'name': name,
        'email': email,
        'phone': phone,
        'cnic': cnic,
        'gender': gender,
        'category': category,
        'experience': experience,
        'review': review,
        'availibility_status': availibility_status,
        'is_verified': is_verified,
        'verification_status': verification_status,
        'address': address.toMap(),
        'image_path': image_path,
        'cnic_front_image_path': cnic_front_image_path,
        'cnic_back_image_path': cnic_back_image_path,
        'stripe_account_id': stripe_account_id,
        'created_at': created_at,
        'updated_at': updated_at,
      };

  Tailor copyWith({
    String? tailor_id,
    String? name,
    String? email,
    String? phone,
    int? cnic,
    String? gender,
    List<String>? category,
    int? experience,
    double? review,
    bool? availibility_status,
    bool? is_verified,
    int? verification_status,
    TailorAddress? address,
    String? image_path,
    String? cnic_front_image_path,
    String? cnic_back_image_path,
    String? stripe_account_id,
    Timestamp? created_at,
    Timestamp? updated_at,
  }) {
    return Tailor(
      tailor_id: tailor_id ?? this.tailor_id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      experience: experience ?? this.experience,
      review: review ?? this.review,
      availibility_status: availibility_status ?? this.availibility_status,
      is_verified: is_verified ?? this.is_verified,
      verification_status: verification_status ?? this.verification_status,
      address: address ?? this.address,
      image_path: image_path ?? this.image_path,
      cnic_front_image_path: cnic_front_image_path ?? this.cnic_front_image_path,
      cnic_back_image_path: cnic_back_image_path ?? this.cnic_back_image_path,
      stripe_account_id: stripe_account_id ?? this.stripe_account_id,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}