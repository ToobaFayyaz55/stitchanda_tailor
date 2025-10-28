import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/screens/home_screen.dart';
import 'registration/personal_info_screen.dart';

// ✅ Dummy Tailor Login Credentials
const String dummyEmail = "laiba@gmail.com";
const String dummyUsername = "laiba";
const String dummyPassword = "123456";

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

  void _login() async {
    final input = emailController.text.trim();
    final password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    await Future.delayed(const Duration(seconds: 1)); // fake loading

    bool isValidEmail = input == dummyEmail;
    bool isValidUsername = input.toLowerCase() == dummyUsername.toLowerCase();
    bool isCorrectPassword = password == dummyPassword;

    if ((isValidEmail || isValidUsername) && isCorrectPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email/username or password")),
      );
    }

    setState(() => loading = false);
  }

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

              Center(
                child: Image.asset(
                  "assets/images/logo2.png",
                  height: 120,
                ),
              ),

              const SizedBox(height: 25),

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

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email / Username",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 16),

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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
                ),
              ),

              const SizedBox(height: 35),

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
                              const PersonalInfoScreen(),
                            ),
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
