import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stichanda_tailor/data/models/tailor_model.dart';
import 'package:stichanda_tailor/data/services/stripe_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stichanda_tailor/helper/upload_image.dart';

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
      // First try Supabase helper
      String? imageUrl;
      try {
        imageUrl = await uploadImageToSupabase(
          role: 'tailor',
          uid: tailorId,
          type: 'avatar',
          file: XFile(filePath),
        );
      } catch (_) {
        imageUrl = null;
      }

      // Fallback to Firebase Storage if Supabase not configured or failed
      if (imageUrl == null || imageUrl.isEmpty) {
        final ref = _storage.ref().child('tailor_profile/$tailorId/avatar.jpg');
        await ref.putFile(File(filePath));
        imageUrl = await ref.getDownloadURL();
      }

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
    required String imagePath, // CNIC front (local path)
    double latitude = 0.0,
    double longitude = 0.0,
    String? cnicBackPath, // optional CNIC back (local path)
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
        // 2. Upload CNIC images (Supabase first, fallback to Firebase Storage)
        String cnicFrontUrl = '';
        String cnicBackUrl = '';

        if (imagePath.isNotEmpty) {
          try {
            cnicFrontUrl = await uploadImageToSupabase(
                  role: 'tailor',
                  uid: userId,
                  type: 'cnic_front',
                  file: XFile(imagePath),
                ) ?? '';
          } catch (_) {
            cnicFrontUrl = '';
          }

          if (cnicFrontUrl.isEmpty) {
            try {
              final ref = _storage.ref().child('tailor_cnic/$userId/cnic_front.jpg');
              await ref.putFile(File(imagePath));
              cnicFrontUrl = await ref.getDownloadURL();
            } catch (e) {
              print('CNIC front upload failed: $e');
            }
          }
        }

        if (cnicBackPath != null && cnicBackPath.isNotEmpty) {
          try {
            cnicBackUrl = await uploadImageToSupabase(
                  role: 'tailor',
                  uid: userId,
                  type: 'cnic_back',
                  file: XFile(cnicBackPath),
                ) ?? '';
          } catch (_) {
            cnicBackUrl = '';
          }

          if (cnicBackUrl.isEmpty) {
            try {
              final refBack = _storage.ref().child('tailor_cnic/$userId/cnic_back.jpg');
              await refBack.putFile(File(cnicBackPath));
              cnicBackUrl = await refBack.getDownloadURL();
            } catch (e) {
              print('CNIC back upload failed: $e');
            }
          }
        }

        // 3. Create tailor document in Firestore per schema
        final tailor = Tailor(
          tailor_id: userId,
          name: name,
          email: email,
          phone: phone,
          cnic: cnicNumber,
          gender: gender,
          category: categories,
          experience: experience,
          review: 0,
          availibility_status: true,
          is_verified: false,
          verification_status: 0, // 0 = pending
          address: TailorAddress(full_address: fullAddress, latitude: latitude, longitude: longitude),
          image_path: '', // profile avatar intentionally empty at registration
          cnic_front_image_path: cnicFrontUrl,
          cnic_back_image_path: cnicBackUrl,
          stripe_account_id: '',
          created_at: Timestamp.now(),
          updated_at: Timestamp.now(),
        );

        await _firestore.collection('tailor').doc(userId).set({
          ...tailor.toMap(),
        });

        // 4. Attempt to create Stripe connected account (non-blocking failure)
        final stripeId = await StripeService.createConnectedAccount(email: email);
        Tailor finalTailor = tailor;
        if (stripeId != null) {
          await _firestore.collection('tailor').doc(userId).update({
            'stripe_account_id': stripeId,
            'updated_at': FieldValue.serverTimestamp(),
          });
          finalTailor = tailor.copyWith(stripe_account_id: stripeId);
        }

        await _firebaseAuth.signOut();

        return finalTailor;
      } catch (e) {
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

      // Translate legacy keys to nested address keys
      final Map<String, dynamic> updates = {...updatedData};

      // Add updated_at timestamp
      updates['updated_at'] = FieldValue.serverTimestamp();

      await docRef.update(updates);

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
        throw Exception('Tailor profile not found for this account.');
      }
    } on FirebaseAuthException catch (e) {
      // Friendly messages
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.code == 'user-not-found') {
        throw Exception('No tailor account found with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is invalid.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled. Contact support.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many failed attempts. Please wait and try again later.');
      }
      throw Exception('Login failed: ${e.message}');
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

  Future<Tailor> fetchTailorById(String tailorId) async {
    final doc = await _firestore.collection('tailor').doc(tailorId).get();
    if (!doc.exists) throw Exception('Tailor not found');
    return Tailor.fromMap({...doc.data() as Map<String,dynamic>, 'tailor_id': tailorId});
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format.');
      } else if (e.code == 'missing-email') {
        throw Exception('Please enter an email address.');
      }
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Re-authenticate user with current password first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Please log out and log back in before changing password');
      }
      throw Exception('Failed to change password: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
