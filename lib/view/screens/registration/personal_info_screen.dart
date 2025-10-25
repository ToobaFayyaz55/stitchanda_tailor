import 'package:flutter/material.dart';
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
  final addressController = TextEditingController();

  String gender = "Male"; // default selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tailor Registration"),
        backgroundColor: AppColors.caramel,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Personal Information",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBrown,
                  ),
                ),
                const SizedBox(height: 25),

                // Full Name
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                  v!.isEmpty ? "Please enter your full name" : null,
                ),
                const SizedBox(height: 15),

                // Email
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v!.contains("@")
                      ? null
                      : "Please enter a valid email address",
                ),
                const SizedBox(height: 15),

                // Phone Number
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => v!.length < 10
                      ? "Please enter a valid phone number"
                      : null,
                ),
                const SizedBox(height: 15),

                // Gender
                const Text(
                  "Gender",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.deepBrown,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile(
                        activeColor: AppColors.caramel,
                        title: const Text("Male"),
                        value: "Male",
                        groupValue: gender,
                        onChanged: (value) {
                          setState(() {
                            gender = value.toString();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        activeColor: AppColors.caramel,
                        title: const Text("Female"),
                        value: "Female",
                        groupValue: gender,
                        onChanged: (value) {
                          setState(() {
                            gender = value.toString();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Address
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) =>
                  v!.isEmpty ? "Please enter your address" : null,
                ),

                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkDetailsScreen(
                              fullName: fullNameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phoneController.text.trim(),
                              gender: gender,
                              address: addressController.text.trim(),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text("Continue"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
