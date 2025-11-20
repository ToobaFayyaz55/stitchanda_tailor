import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'work_details_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  String gender = "Male"; // default selected

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Decorative Header Section
            Stack(
              children: [
                // Full Background Image
                Container(
                  width: double.infinity,
                  height: 225,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    image: DecorationImage(
                      image: const AssetImage('assets/images/Tailor_reg.png'),
                      fit: BoxFit.cover, // makes the image fill entire header
                    ),
                  ),
                ),

                // Dark overlay (optional — helps text visibility)
                Container(
                  width: double.infinity,
                  height: 225,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    color: Colors.black.withOpacity(0),
                  ),
                ),

                // Text + layout
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start Your Tailoring\nJourney with\nStitchanda",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontFamily: 'IMFellDWPica',
                            color: AppColors.textBlack.withOpacity(0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close Button
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.deepBrown),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            // Form Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: fullNameController,
                        decoration: InputDecoration(
                          hintText: "Full Name",
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.caramel,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Please enter your full name" : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "Email",
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.caramel,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) => v!.contains("@")
                            ? null
                            : "Please enter a valid email address",
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "Phone Number",
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.caramel,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) => v!.length < 10
                            ? "Please enter a valid phone number"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: InputDecoration(
                          hintText: "Gender",
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.caramel,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "Male", child: Text("Male")),
                          DropdownMenuItem(value: "Female", child: Text("Female")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            gender = value ?? "Male";
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.caramel,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Save personal info to AuthCubit
                              context.read<AuthCubit>().updatePersonalInfo(
                                    name: fullNameController.text.trim(),
                                    email: emailController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    gender: gender,
                                  );

                              // Navigate to next screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WorkDetailsScreen(),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

