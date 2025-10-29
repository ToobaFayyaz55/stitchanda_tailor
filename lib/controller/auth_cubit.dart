import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stichanda_tailor/data/repository/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;

  AuthCubit(this.authRepo) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepo.login(email, password);
      if (user != null) {
        emit(AuthSuccess());
      } else {
        emit(AuthError("Invalid Credentials"));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await authRepo.logout();
    emit(AuthInitial());
  }
}
