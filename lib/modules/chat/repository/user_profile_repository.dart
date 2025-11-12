import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stichanda_tailor/modules/chat/models/chat_user.dart';

class UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Try driver, then customer, then tailor
  Future<ChatUser?> getUserById(String uid) async {

    // driver
    final d = await _firestore.collection('driver').doc(uid).get();
    if (d.exists) {
      final data = d.data() as Map<String, dynamic>;
      final p = (data['profile_image_path']?.toString() ?? '').trim();
      return ChatUser(
        id: uid,
        name: (data['name']?.toString() ?? data['full_name']?.toString() ?? 'Driver'),
        imageUrl: p.isNotEmpty ? p : null,
      );
    }
    // customer
    final c = await _firestore.collection('customer').doc(uid).get();
    if (c.exists) {
      final data = c.data() as Map<String, dynamic>;
      final p = (data['profile_image_path']?.toString() ?? '').trim();
      return ChatUser(
        id: uid,
        name: (data['name']?.toString() ?? data['full_name']?.toString() ?? 'Customer'),
        imageUrl: p.isNotEmpty ? p : null,
      );
    }
    // tailor
    final t = await _firestore.collection('tailor').doc(uid).get();
    if (t.exists) {
      final data = t.data() as Map<String, dynamic>;
      final p = (data['profile_image_path']?.toString() ?? '').trim();
      return ChatUser(
        id: uid,
        name: (data['name']?.toString() ?? data['shop_name']?.toString() ?? 'Tailor'),
        imageUrl: p.isNotEmpty ? p : null,
      );
    }
    return null;
  }
}
