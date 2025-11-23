import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/view/screens/login_screen.dart';
import 'package:stichanda_tailor/view/screens/home_screen.dart';
import 'package:stichanda_tailor/view/screens/pending_approval_screen.dart';
import 'package:stichanda_tailor/view/screens/rejected_screen.dart';
import 'package:stichanda_tailor/view/screens/splash_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<AuthCubit>().bootstrapSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {},
      builder: (context, state) {
        // Show splash only while actively loading (bootstrap or other blocking ops)
        if (state is AuthBootstrapLoading) {
          return const SplashScreen();
        }
        if (state is AuthLoading) {
          // Keep user on current screen; decide based on prior authenticated state
          // Fallback to Login if initial
          return const LoginScreen();
        }
        // If no session and not loading -> go to Login
        if (state is AuthInitial) {
          return const LoginScreen();
        }
        if (state is RegistrationInProgress) {
          return PendingApprovalScreen(email: state.registrationData.email, name: state.registrationData.name);
        }
        if (state is AuthError) {
          return const LoginScreen();
        }
        if (state is PasswordResetEmailSent || state is PasswordResetError) {
          // Stay on login screen for password reset states
          return const LoginScreen();
        }
        if (state is PendingApproval) {
          return PendingApprovalScreen(email: state.email, name: state.name);
        }
        if (state is VerificationRejected) {
          return RejectedScreen(email: state.email, name: state.name);
        }
        if (state is AuthSuccess) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
