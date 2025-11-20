import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'password_setup_screen.dart';

class CnicUploadScreen extends StatefulWidget {
  const CnicUploadScreen({super.key});

  @override
  State<CnicUploadScreen> createState() => _CnicUploadScreenState();
}

class _CnicUploadScreenState extends State<CnicUploadScreen> {
  File? frontImage;
  File? backImage;
  final ImagePicker picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final cnicController = TextEditingController();

  @override
  void dispose() {
    cnicController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          frontImage = File(pickedFile.path);
        } else {
          backImage = File(pickedFile.path);
        }
      });
    }
  }

  void _continueToNextScreen() {
    if (_formKey.currentState!.validate()) {
      if (frontImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload CNIC front image')),
        );
        return;
      }

      // Save CNIC info to AuthCubit
      context.read<AuthCubit>().updateCNIC(
        cnicNumber: int.parse(cnicController.text),
        imagePath: frontImage!.path,
        backImagePath: backImage?.path,
      );

      // Navigate to next screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PasswordSetupScreen(),
        ),
      );
    }
  }

  Widget _uploadCard(String label, File? image, bool isFront) {
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline, width: 1.5),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file, color: AppColors.deepBrown, size: 45),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.deepBrown),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(image, fit: BoxFit.cover),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Verification",
            style: TextStyle(
                fontSize: 20
            )
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Upload your CNIC",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  "Please upload a clear picture of your CNIC front",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.deepBrown.withAlpha(179),
                      ),
                ),
                const SizedBox(height: 30),

                _uploadCard("Tap to upload CNIC Front", frontImage, true),
                const SizedBox(height: 20),
                _uploadCard("Tap to upload CNIC Back (Optional)", backImage, false),

                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: cnicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "CNIC Number",
                      hintText: "Enter 13 digit CNIC number",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your CNIC';
                      }
                      if (value.length != 13) {
                        return 'CNIC must be 13 digits';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'CNIC must contain only numbers';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.caramel,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _continueToNextScreen,
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
    );
  }
}
