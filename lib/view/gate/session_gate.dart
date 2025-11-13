import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/view/screens/login_screen.dart';
import 'package:stichanda_tailor/view/screens/home_screen.dart';
import 'package:stichanda_tailor/view/screens/pending_approval_screen.dart';
import 'package:stichanda_tailor/view/screens/rejected_screen.dart';

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
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is RegistrationInProgress) {
          return PendingApprovalScreen(email: state.registrationData.email, name: state.registrationData.name);
        }
        if (state is AuthInitial || state is AuthError) {
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

