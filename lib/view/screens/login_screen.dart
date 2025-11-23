import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/screens/forgot_password_screen.dart';
import 'package:stichanda_tailor/view/screens/registration/personal_info_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              String msg = state.message;
              msg = msg.replaceFirst(RegExp(r'^Exception:\s?'), '').trim();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is PasswordResetEmailSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset link sent to ${state.email}'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state is PasswordResetError) {
              String msg = state.message.replaceFirst('Exception: ', '').trim();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            // Do not navigate here; SessionGate rebuild will switch screens
          },
          builder: (context, state) {
            bool isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),

                  // Logo
                  Center(
                    child: Image.asset(
                      "assets/images/logo2.png",
                      height: 120,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Heading
                  const Text(
                    "Welcome back",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBlack,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Please enter your details to login",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email Field
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: "Enter your email",
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outlined),
                      hintText: "Enter your password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(
                            () => obscurePassword = !obscurePassword,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.caramel,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (emailController.text.isEmpty ||
                                  passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill all fields'),
                                  ),
                                );
                                return;
                              }

                              context.read<AuthCubit>().login(
                                    email: emailController.text,
                                    password: passwordController.text,
                                  );
                              // No navigation here; SessionGate will rebuild to target screen
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caramel,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),


                  const SizedBox(height: 24),

                  // Sign Up Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PersonalInfoScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.caramel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
