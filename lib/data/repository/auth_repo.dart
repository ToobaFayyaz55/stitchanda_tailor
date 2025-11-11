import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stichanda_tailor/data/models/tailor_model.dart';

class AuthRepo {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Update tailor availability status and return updated Tailor
  Future<Tailor> updateAvailability(String tailorId, bool available) async {
    try {
      final docRef = _firestore.collection('tailor').doc(tailorId);
      await docRef.update({
        'availibility_status': available,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Tailor not found');

      return Tailor.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'tailor_id': tailorId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Upload and set tailor profile image. Accepts a local file path.
  Future<Tailor> uploadProfileImage(String tailorId, String filePath) async {
    try {
      // Upload to Firebase Storage
      final ref = _storage.ref().child('tailor_profile/$tailorId/avatar.jpg');
      await ref.putFile(File(filePath));
      final imageUrl = await ref.getDownloadURL();

      // Update Firestore document
      final docRef = _firestore.collection('tailor').doc(tailorId);
      await docRef.update({
        'image_path': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Tailor not found');

      return Tailor.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'tailor_id': tailorId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Register a new tailor with email and password
  Future<Tailor> registerTailor({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String fullAddress,
    required String gender,
    required List<String> categories,
    required int experience,
    required int cnicNumber,
    required String imagePath,
  }) async {
    UserCredential? userCredential;

    try {
      // 1. Create Firebase Auth user
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      try {
        // 2. Upload CNIC image to Storage
        String imageUrl = '';
        if (imagePath.isNotEmpty) {
          try {
            final ref = _storage.ref().child('tailor_cnic/$userId/cnic.jpg');
            await ref.putFile(File(imagePath));
            imageUrl = await ref.getDownloadURL();
          } catch (e) {
            print('Image upload failed: $e');
          }
        }

        // 3. Create tailor document in Firestore
        final tailor = Tailor(
          tailor_id: userId,
          name: name,
          email: email,
          phone: phone,
          full_address: fullAddress,
          latitude: 0.0,
          longitude: 0.0,
          availibility_status: true,
          category: categories,
          gender: gender,
          experience: experience,
          cnic: cnicNumber,
          image_path: imageUrl,
          is_verified: false,
          verification_status: 0, // 0 = pending
          review: 0,
          created_at: Timestamp.now(),
          updated_at: Timestamp.now(),
        );

        await _firestore.collection('tailor').doc(userId).set(tailor.toMap());

        // 4. Sign out user
        await _firebaseAuth.signOut();

        return tailor;
      } catch (e) {
        // If Firestore fails, delete Auth user
        try {
          await userCredential.user?.delete();
          await _firebaseAuth.signOut();
        } catch (_) {}
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered. Please use a different email or login if you already have an account.');
      } else if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Please use a stronger password (at least 6 characters).');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address. Please check and try again.');
      }
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Update tailor profile fields and return updated Tailor
  Future<Tailor> updateTailorProfile(String tailorId, Map<String, dynamic> updatedData) async {
    try {
      final docRef = _firestore.collection('tailor').doc(tailorId);

      // Add updated_at timestamp
      updatedData['updated_at'] = FieldValue.serverTimestamp();

      await docRef.update(updatedData);

      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Tailor not found');

      return Tailor.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'tailor_id': tailorId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Login with email and password
  Future<Tailor> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      final doc = await _firestore.collection('tailor').doc(userId).get();

      if (doc.exists) {
        return Tailor.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'tailor_id': userId,
        });
      } else {
        throw Exception('Tailor profile not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }
}
