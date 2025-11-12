import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stichanda_tailor/data/models/tailor_model.dart';
import 'package:stichanda_tailor/data/repository/auth_repo.dart';

// ==================== STATES ====================

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final Tailor tailor;

  const AuthSuccess(this.tailor);

  @override
  List<Object?> get props => [tailor];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PendingApproval extends AuthState {
  final String email;
  final String name;

  const PendingApproval({required this.email, required this.name});

  @override
  List<Object?> get props => [email, name];
}

class VerificationRejected extends AuthState {
  final String email;
  final String name;

  const VerificationRejected({required this.email, required this.name});

  @override
  List<Object?> get props => [email, name];
}

class RegistrationInProgress extends AuthState {
  final Tailor registrationData;

  const RegistrationInProgress(this.registrationData);

  @override
  List<Object?> get props => [registrationData];
}

// ==================== CUBIT ====================

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  Tailor? _registrationData;

  AuthCubit({required this.authRepo}) : super(const AuthInitial());

  // ==================== LOGIN ====================

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      emit(const AuthLoading());
      final tailor = await authRepo.login(email, password);

      // Check verification status
      if (tailor.verification_status == 0) {
        // Pending approval
        emit(PendingApproval(email: tailor.email, name: tailor.name));
      } else if (tailor.verification_status == 2) {
        // Rejected
        emit(VerificationRejected(email: tailor.email, name: tailor.name));
      } else if (tailor.verification_status == 1) {
        // Verified - can login
        emit(AuthSuccess(tailor));
      } else {
        emit(AuthError('Unknown verification status'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    try {
      await authRepo.logout();
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================== REGISTRATION STEPS ====================

  void updatePersonalInfo({
    required String name,
    required String email,
    required String phone,
    required String gender,
    String fullAddress = '', // Optional - will be set in LocationSelectionScreen
  }) {
    try {
      _registrationData = (_registrationData ?? Tailor(
        tailor_id: '',
        name: '',
        email: '',
        phone: '',
        cnic: 0,
        gender: 'male',
        category: const [],
        experience: 0,
        review: 0,
        availibility_status: true,
        is_verified: false,
        verification_status: 0,
        address: const TailorAddress(full_address: '', latitude: 0.0, longitude: 0.0),
        image_path: '',
        stripe_account_id: '',
        created_at: Timestamp.now(),
        updated_at: Timestamp.now(),
      )).copyWith(
        name: name,
        email: email,
        phone: phone,
        gender: gender,
        address: (_registrationData?.address ?? const TailorAddress(full_address: '', latitude: 0.0, longitude: 0.0))
            .copyWith(full_address: fullAddress),
      );
      emit(RegistrationInProgress(_registrationData!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void updateWorkDetails({
    required List<String> categories,
    required int experience,
  }) {
    try {
      if (_registrationData == null) {
        throw Exception('Personal info must be filled first');
      }
      _registrationData = _registrationData!.copyWith(
        category: categories,
        experience: experience,
      );
      emit(RegistrationInProgress(_registrationData!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void updateLocation({
    required double latitude,
    required double longitude,
    required String fullAddress,
  }) {
    try {
      if (_registrationData == null) {
        throw Exception('Personal info must be filled first');
      }
      _registrationData = _registrationData!.copyWith(
        address: (_registrationData!.address).copyWith(
          latitude: latitude,
          longitude: longitude,
          full_address: fullAddress,
        ),
      );
      emit(RegistrationInProgress(_registrationData!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void updateCNIC({
    required int cnicNumber,
    required String imagePath,
  }) {
    try {
      if (_registrationData == null) {
        throw Exception('Previous steps must be completed first');
      }
      _registrationData = _registrationData!.copyWith(
        cnic: cnicNumber,
        image_path: imagePath,
      );
      emit(RegistrationInProgress(_registrationData!));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ==================== COMPLETE REGISTRATION ====================

  Future<void> completeRegistration(String password) async {
    try {
      emit(const AuthLoading());

      if (_registrationData == null) {
        throw Exception('All registration steps must be completed');
      }

      // Call repository to handle all registration logic
      final tailor = await authRepo.registerTailor(
        name: _registrationData!.name,
        email: _registrationData!.email,
        password: password,
        phone: _registrationData!.phone,
        fullAddress: _registrationData!.address.full_address,
        gender: _registrationData!.gender,
        categories: _registrationData!.category,
        experience: _registrationData!.experience,
        cnicNumber: _registrationData!.cnic,
        imagePath: _registrationData!.image_path,
        latitude: _registrationData!.address.latitude,
        longitude: _registrationData!.address.longitude,
      );

      // Update registration data with the returned tailor data
      _registrationData = tailor;

      // Emit RegistrationInProgress to show PendingApprovalScreen
      emit(RegistrationInProgress(_registrationData!));
    } catch (e) {
      // Keep registration data so user can fix and retry
      emit(AuthError(e.toString()));
    }
  }

  // ==================== UTILITY ====================

  void clearRegistrationData() {
    _registrationData = null;
    emit(const AuthInitial());
  }

  /// Delete current Firebase Auth user (for cleanup of failed registrations)
  Future<void> deleteCurrentUser() async {
    try {
      final user = authRepo.getCurrentUser();
      if (user != null) {
        await user.delete();
        await authRepo.logout();
      }
      _registrationData = null;
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthError('Failed to delete user: ${e.toString()}'));
    }
  }

  /// Update availability status for current tailor
  Future<void> updateAvailability(bool available) async {
    try {
      final state = this.state;
      if (state is! AuthSuccess) {
        throw Exception('Not authenticated');
      }
      emit(const AuthLoading());
      final updated = await authRepo.updateAvailability(state.tailor.tailor_id, available);
      emit(AuthSuccess(updated));
    } catch (e) {
      emit(AuthError('Failed to update availability: ${e.toString()}'));
    }
  }

  /// Update tailor profile fields (name, phone, address, gender, experience)
  Future<void> updateTailorProfile(Map<String, dynamic> updatedData) async {
    try {
      final state = this.state;
      if (state is! AuthSuccess) {
        throw Exception('Not authenticated');
      }
      emit(const AuthLoading());
      final updated = await authRepo.updateTailorProfile(state.tailor.tailor_id, updatedData);
      emit(AuthSuccess(updated));
    } catch (e) {
      emit(AuthError('Failed to update profile: ${e.toString()}'));
    }
  }

  /// Upload and update profile image for current tailor
  Future<void> updateProfileImage(String localFilePath) async {
    try {
      final state = this.state;
      if (state is! AuthSuccess) throw Exception('Not authenticated');
      emit(const AuthLoading());
      final updated = await authRepo.uploadProfileImage(state.tailor.tailor_id, localFilePath);
      emit(AuthSuccess(updated));
    } catch (e) {
      emit(AuthError('Failed to update profile image: ${e.toString()}'));
    }
  }

}
