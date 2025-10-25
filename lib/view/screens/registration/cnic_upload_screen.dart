import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'password_setup_screen.dart';

class CnicUploadScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String address;
  final String workDescription;
  final String experience;
  final List<String> specialties;

  const CnicUploadScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.address,
    required this.workDescription,
    required this.experience,
    required this.specialties,
  });

  @override
  State<CnicUploadScreen> createState() => _CnicUploadScreenState();
}

class _CnicUploadScreenState extends State<CnicUploadScreen> {
  File? frontImage;
  File? backImage;
  final ImagePicker picker = ImagePicker();

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

  void _goToNext() {
    if (frontImage == null || backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both CNIC sides")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordSetupScreen(
          fullName: widget.fullName,
          email: widget.email,
          phone: widget.phone,
          gender: widget.gender,
          address: widget.address,
          workDescription: widget.workDescription,
          experience: widget.experience,
          specialties: widget.specialties,
          cnicFront: frontImage!,
          cnicBack: backImage!,
        ),
      ),
    );
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
        title: const Text("Verification"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload your CNIC",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                "Please upload a clear picture of both sides of your CNIC",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepBrown.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 30),

              _uploadCard("Tap to upload CNIC Front", frontImage, true),
              const SizedBox(height: 20),
              _uploadCard("Tap to upload CNIC Back", backImage, false),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToNext,
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
