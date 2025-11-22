import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:image_picker/image_picker.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
            "Profile Details",
            style: TextStyle(
                fontSize: 20
            )
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final tailor = state.tailor;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar and name
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailHeader(tailor: tailor),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Details section
                        const Text(
                          'Personal Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Profile fields from Firebase - EDITABLE fields only
                        _EditableProfileField(
                          label: 'Name',
                          value: tailor.name,
                          isEditable: true,
                          onEdit: () => _showEditDialog(context, 'Name', tailor.name, (newValue) {
                            // Update name in Firebase via AuthCubit
                            context.read<AuthCubit>().updateTailorProfile({'name': newValue});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name updated successfully')),
                            );
                          }),
                        ),
                        _EditableProfileField(
                          label: 'Email',
                          value: tailor.email,
                          isEditable: false,
                        ),
                        _EditableProfileField(
                          label: 'Phone',
                          value: tailor.phone,
                          isEditable: true,
                          onEdit: () => _showEditDialog(context, 'Phone', tailor.phone, (newValue) {
                            context.read<AuthCubit>().updateTailorProfile({'phone': newValue});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Phone updated successfully')),
                            );
                          }),
                        ),
                        _EditableProfileField(
                          label: 'Address',
                          value: tailor.address.full_address,
                          isEditable: true,
                          onEdit: () => _showEditDialog(context, 'Address', tailor.address.full_address, (newValue) {
                            context.read<AuthCubit>().updateTailorProfile({'full_address': newValue});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address updated successfully')),
                            );
                          }),
                        ),
                        _EditableProfileField(
                          label: 'Gender',
                          value: tailor.gender,
                          isEditable: true,
                          onEdit: () => _showEditDialog(context, 'Gender', tailor.gender, (newValue) {
                            context.read<AuthCubit>().updateTailorProfile({'gender': newValue});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gender updated successfully')),
                            );
                          }),
                        ),
                        _EditableProfileField(
                          label: 'Experience',
                          value: '${tailor.experience} years',
                          isEditable: true,
                          onEdit: () => _showEditDialog(context, 'Experience (years)', '${tailor.experience}', (newValue) {
                            final experience = int.tryParse(newValue) ?? tailor.experience;
                            context.read<AuthCubit>().updateTailorProfile({'experience': experience});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Experience updated successfully')),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Specializations section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Specializations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textBlack,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showSpecializationsEditDialog(context, tailor.category),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.caramel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (tailor.category.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.beige.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No specializations added yet',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tailor.category
                                .where((category) => category.toLowerCase() != 'both')
                                .map((category) => _SkillChip(skill: category))
                                .toList(),
                          ),

                        const SizedBox(height: 24),

                        // Rating section
                        const Text(
                          'Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ReviewSection(review: tailor.review),


                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(
              child: Text('Unable to load profile. Please login again.'),
            );
          }
        },
      ),
    );
  }
}

// Profile Avatar + Name from Firebase
class _DetailHeader extends StatefulWidget {
  final dynamic tailor;
  const _DetailHeader({required this.tailor});

  @override
  State<_DetailHeader> createState() => _DetailHeaderState();
}

class _DetailHeaderState extends State<_DetailHeader> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final messenger = ScaffoldMessenger.maybeOf(context); // capture early to avoid context issues after dispose
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _uploading = true);
    try {
      await context.read<AuthCubit>().updateProfileImage(picked.path);
      if (mounted && messenger != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Profile image updated')));
      }
    } catch (e) {
      if (mounted && messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailor = widget.tailor;
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: CircleAvatar(
                  key: ValueKey(tailor.image_path),
                  radius: 60, // Increased from 40 to 60
                  backgroundColor: AppColors.beige,
                  backgroundImage: (tailor.image_path is String && tailor.image_path.isNotEmpty)
                      ? NetworkImage('${tailor.image_path}?v=${DateTime.now().millisecondsSinceEpoch}')
                      : null,
                  child: (tailor.image_path == null || tailor.image_path.isEmpty)
                      ? const Icon(
                          Icons.person,
                          size: 70,
                          color: AppColors.deepBrown,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.caramel,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tailor.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tailor',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Editable Field Widget
class _EditableProfileField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final bool isEditable;

  const _EditableProfileField({
    required this.label,
    required this.value,
    this.onEdit,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(
                          color: AppColors.deepBrown,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(
                          color: AppColors.textBlack,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isEditable)
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.caramel,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _SkillChip extends StatelessWidget {
  final String skill;

  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        skill,
        style: const TextStyle(
          color: AppColors.deepBrown,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.beige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outline),
      ),
    );
  }
}

// Review Section - Display tailor rating
class _ReviewSection extends StatelessWidget {
  final double review;

  const _ReviewSection({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '${review.toStringAsFixed(1)} / 5.0',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.caramel,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                color: index < review.floor() ? Colors.amber : AppColors.outline,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show edit dialog
void _showEditDialog(
  BuildContext context,
  String fieldName,
  String currentValue,
  Function(String) onSave,
) {
  final TextEditingController controller = TextEditingController(text: currentValue);

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Edit $fieldName'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Enter $fieldName',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.caramel,
          ),
          onPressed: () {
            onSave(controller.text);
            Navigator.pop(dialogContext);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// Helper function to show specializations edit dialog
void _showSpecializationsEditDialog(
  BuildContext context,
  List<String> currentSpecializations,
) {
  final List<String> allSpecializations = [
    'male',
    'female',
    'kids',
    'bridal',
    'formal',
    'casual',
    'traditional',
    'western',
  ];

  final selectedSpecializations = List<String>.from(currentSpecializations);

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit Specializations'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: allSpecializations.map((spec) {
              final isSelected = selectedSpecializations.contains(spec);
              // Capitalize first letter for display
              final displayName = spec[0].toUpperCase() + spec.substring(1);

              return CheckboxListTile(
                title: Text(displayName),
                value: isSelected,
                activeColor: AppColors.caramel,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (!selectedSpecializations.contains(spec)) {
                        selectedSpecializations.add(spec);
                      }
                    } else {
                      selectedSpecializations.remove(spec);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.caramel,
            ),
            onPressed: () {
              context.read<AuthCubit>().updateTailorProfile({'category': selectedSpecializations});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Specializations updated successfully')),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

