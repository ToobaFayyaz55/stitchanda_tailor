import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'registration/personal_info_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              ///  Center Logo (replace image with your logo)
              Center(
                child: Image.asset(
                  "assets/images/logo2.png",
                  height: 120,
                ),
              ),

              const SizedBox(height: 25),

              /// Header Text
              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please enter your details to login",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textBlack.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 35),

              /// Email Field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              /// Password Field
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),


              /// Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.caramel,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {},
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
                ),
              ),

              const SizedBox(height: 35),

              /// Footer Text
              RichText(
                text: TextSpan(
                  text: "Don’t have an account? ",
                  style: const TextStyle(
                    color: AppColors.textBlack,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: "Sign up",
                      style: const TextStyle(
                        color: AppColors.caramel,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const PersonalInfoScreen()),
                          );
                        },
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
