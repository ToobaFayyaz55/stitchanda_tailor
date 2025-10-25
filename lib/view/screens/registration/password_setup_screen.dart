import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import '../login_screen.dart';

class PasswordSetupScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String address;
  final String workDescription;
  final String experience;
  final List<String> specialties;
  final File cnicFront;
  final File cnicBack;

  const PasswordSetupScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.address,
    required this.workDescription,
    required this.experience,
    required this.specialties,
    required this.cnicFront,
    required this.cnicBack,
  });

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  bool obscure = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Auth Create
      var cred = await auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: passwordController.text,
      );
      String uid = cred.user!.uid;

      // Upload CNIC
      var frontRef = storage.ref("tailors/$uid/front.jpg");
      var backRef = storage.ref("tailors/$uid/back.jpg");

      await frontRef.putFile(widget.cnicFront);
      await backRef.putFile(widget.cnicBack);

      String frontUrl = await frontRef.getDownloadURL();
      String backUrl = await backRef.getDownloadURL();

      // Firestore
      await firestore.collection("tailors").doc(uid).set({
        "fullName": widget.fullName,
        "email": widget.email,
        "phone": widget.phone,
        "gender": widget.gender,
        "address": widget.address,
        "workDescription": widget.workDescription,
        "experience": widget.experience,
        "specialties": widget.specialties,
        "frontCnic": frontUrl,
        "backCnic": backUrl,
        "createdAt": DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Created 🎉")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _passwordRule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.deepBrown,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Password"),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.deepBrown,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Secure your account",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.deepBrown.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.deepBrown),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.deepBrown,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                    validator: (val) =>
                    val != null && val.length >= 6
                        ? null
                        : "Min 6 characters",
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.deepBrown),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.deepBrown,
                        ),
                        onPressed: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (val) =>
                    val == passwordController.text
                        ? null
                        : "Passwords do not match",
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Password requirements:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepBrown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _passwordRule("At least 6 characters"),
                  _passwordRule("Letters & numbers included"),
                  _passwordRule("At least 1 special character"),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Sign Up"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
