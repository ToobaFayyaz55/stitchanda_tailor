import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
      emit(AuthSuccess(tailor));
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
    required String fullAddress,
    required String gender,
  }) {
    try {
      _registrationData = (_registrationData ?? Tailor(
        tailor_id: '',
        name: '',
        email: '',
        phone: '',
        full_address: '',
        latitude: 0.0,
        longitude: 0.0,
        availibility_status: true,
        category: [],
      )).copyWith(
        name: name,
        email: email,
        phone: phone,
        full_address: fullAddress,
        gender: gender,
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
        fullAddress: _registrationData!.full_address,
        gender: _registrationData!.gender ?? 'male',
        categories: _registrationData!.category,
        experience: _registrationData!.experience ?? 0,
        cnicNumber: _registrationData!.cnic ?? 0,
        imagePath: _registrationData!.image_path,
      );

      // Reset registration data
      _registrationData = null;
      emit(AuthSuccess(tailor));
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
}
