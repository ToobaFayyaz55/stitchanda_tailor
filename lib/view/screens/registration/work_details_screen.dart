import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'location_selection_screen.dart';

class WorkDetailsScreen extends StatefulWidget {
  const WorkDetailsScreen({super.key});

  @override
  State<WorkDetailsScreen> createState() => _WorkDetailsScreenState();
}

class _WorkDetailsScreenState extends State<WorkDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedExperience;
  List<String> selectedSpecialties = [];

  final List<String> experienceOptions = [
    "1",
    "2",
    "3",
    "4",
    "5+"
  ];

  final List<String> specializationOptions = ["male", "female", "both"];

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

                // Years of Experience dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Years of Experience",
                    prefixIcon: Icon(Icons.timeline_outlined),
                  ),
                  initialValue: selectedExperience,
                  items: experienceOptions
                      .map((exp) => DropdownMenuItem(
                            value: exp,
                            child: Text("$exp years"),
                          ))
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.caramel,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (selectedSpecialties.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select at least one specialty"),
                            ),
                          );
                          return;
                        }

                        // Save work details to AuthCubit
                        context.read<AuthCubit>().updateWorkDetails(
                          categories: selectedSpecialties,
                          experience: int.parse(selectedExperience!.replaceAll('+', '')),
                        );

                        // Navigate to next screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocationSelectionScreen(),
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
    );
  }
}

