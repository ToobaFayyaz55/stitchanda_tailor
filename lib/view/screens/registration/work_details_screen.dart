import 'package:flutter/material.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'cnic_upload_screen.dart';

class WorkDetailsScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String address;

  const WorkDetailsScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.address,
  });

  @override
  State<WorkDetailsScreen> createState() => _WorkDetailsScreenState();
}

class _WorkDetailsScreenState extends State<WorkDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final workDescController = TextEditingController();
  String? selectedExperience;

  // we’ll keep track of the selected specialties here
  List<String> selectedSpecialties = [];

  final List<String> experienceOptions = [
    "Less than 1 year",
    "1 - 3 years",
    "3 - 5 years",
    "5+ years"
  ];

  final List<String> specializationOptions = ["Kids", "Men", "Women"];

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
                  "Tell us about your work",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBrown,
                  ),
                ),
                const SizedBox(height: 25),

                // Work Description
                TextFormField(
                  controller: workDescController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Describe your work or skills",
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (v) => v!.isEmpty
                      ? "Please write something about your work"
                      : null,
                ),
                const SizedBox(height: 20),

                // Years of Experience dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Years of Experience",
                    prefixIcon: Icon(Icons.timeline_outlined),
                  ),
                  value: selectedExperience,
                  items: experienceOptions
                      .map(
                        (exp) => DropdownMenuItem(
                      value: exp,
                      child: Text(exp),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedExperience = value;
                    });
                  },
                  validator: (v) =>
                  v == null ? "Please select your experience" : null,
                ),
                const SizedBox(height: 25),

                // Specialization multi-select
                const Text(
                  "What do you specialize in?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.deepBrown,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: specializationOptions.map((item) {
                    final isSelected = selectedSpecialties.contains(item);
                    return ChoiceChip(
                      label: Text(item),
                      selected: isSelected,
                      selectedColor: AppColors.caramel,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.deepBrown,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedSpecialties.add(item);
                          } else {
                            selectedSpecialties.remove(item);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 50),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (selectedSpecialties.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                              Text("Please select at least one specialty"),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CnicUploadScreen(
                              fullName: widget.fullName,
                              email: widget.email,
                              phone: widget.phone,
                              gender: widget.gender,
                              address: widget.address,
                              workDescription: workDescController.text.trim(),
                              experience: selectedExperience!,
                              specialties: selectedSpecialties,
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
