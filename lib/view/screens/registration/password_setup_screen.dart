import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import '../pending_approval_screen.dart';

// Assuming AppColors is defined in theme.dart, using a placeholder class here
// for runnable completeness.
// class AppColors {
//   static const background = Colors.white;
//   static const caramel = Colors.brown;
// }

class PasswordSetupScreen extends StatefulWidget {
  const PasswordSetupScreen({super.key});

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Optional: password strength
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  String _getPasswordStrength() {
    int strength = 0;
    if (_hasMinLength) strength++;
    if (_hasUpperCase) strength++;
    if (_hasLowerCase) strength++;
    if (_hasNumber) strength++;

    if (strength <= 1) return 'Weak';
    if (strength == 2) return 'Fair';
    if (strength == 3) return 'Good';
    return 'Strong';
  }

  Color _getPasswordStrengthColor() {
    final strength = _getPasswordStrength();
    if (strength == 'Weak') return Colors.red;
    if (strength == 'Fair') return Colors.orange;
    if (strength == 'Good') return Colors.yellow[700]!;
    return AppColors.green;
  }

  double _getPasswordStrengthProgress() {
    int strength = 0;
    if (_hasMinLength) strength++;
    if (_hasUpperCase) strength++;
    if (_hasLowerCase) strength++;
    if (_hasNumber) strength++;
    return strength / 4;
  }

  void _handleRegistration(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().completeRegistration(
      _passwordController.text,
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 20,
          color: met ? AppColors.green : AppColors.grey,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: met ? AppColors.green : AppColors.darkgrey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _getPasswordStrength();
    final strengthColor = _getPasswordStrengthColor();
    final strengthProgress = _getPasswordStrengthProgress();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
            "Create Password",
            style: TextStyle(
                fontSize: 20
            )
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          // *** CRITICAL CORRECTION: Navigation should typically be on a SUCCESS state.
          // Assuming AuthState has a successful state like 'RegistrationSuccess'.
          // If RegistrationInProgress IS your final success state, you can revert this.
          listener: (context, state) {
            // Check for a dedicated success state (or whatever state signals completion)
            if (state is RegistrationInProgress) {
              final tailor = state.registrationData;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => PendingApprovalScreen(
                    email: tailor.email,
                    name: tailor.name,
                  ),
                ),
                    (route) => false,
              );
            } else if (state is AuthError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(state.message);
              });
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        if (value.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Password Strength
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password strength',
                          style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                        ),
                        Text(
                          passwordStrength,
                          style: TextStyle(
                            fontSize: 14,
                            color: strengthColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: strengthProgress,
                        backgroundColor: AppColors.grey,
                        valueColor: AlwaysStoppedAnimation(strengthColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRequirement('At least 8 characters', _hasMinLength),
                    const SizedBox(height: 12),
                    _buildRequirement('Contains uppercase letter', _hasUpperCase),
                    const SizedBox(height: 12),
                    _buildRequirement('Contains lowercase letter', _hasLowerCase),
                    const SizedBox(height: 12),
                    _buildRequirement('Contains number', _hasNumber),
                    const SizedBox(height: 32),
                    // Confirm Password Field
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Confirm your password',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _handleRegistration(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.caramel,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.surface),
                          ),
                        )
                            : const Text(
                          'Complete Registration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}