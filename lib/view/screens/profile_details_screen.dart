import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        backgroundColor: AppColors.caramel,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final tailor = state.tailor;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailHeader(tailor: tailor),

                    const SizedBox(height: 24),

                    const Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Profile fields from Firebase
                    _EditableProfileField(
                      label: 'Name',
                      value: tailor.name,
                    ),
                    _EditableProfileField(
                      label: 'Email',
                      value: tailor.email,
                    ),
                    _EditableProfileField(
                      label: 'Phone',
                      value: tailor.phone,
                    ),
                    _EditableProfileField(
                      label: 'Address',
                      value: tailor.full_address,
                    ),
                    _EditableProfileField(
                      label: 'Gender',
                      value: tailor.gender ?? 'Not specified',
                    ),
                    _EditableProfileField(
                      label: 'Experience',
                      value: '${tailor.experience ?? 0} years',
                    ),
                    _EditableProfileField(
                      label: 'Categories',
                      value: tailor.category.join(', '),
                    ),

                    const SizedBox(height: 24),
                    _SkillsSection(categories: tailor.category),

                    const SizedBox(height: 24),
                    _ReviewSection(review: tailor.review),

                    const SizedBox(height: 40),
                  ],
                ),
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
class _DetailHeader extends StatelessWidget {
  final dynamic tailor;

  const _DetailHeader({required this.tailor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.beige,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.deepBrown,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.caramel,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tailor.name,
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            tailor.verfication_status ?? 'Not verified',
            style: Theme.of(context).textTheme.bodyMedium,
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

  const _EditableProfileField({
    required this.label,
    required this.value,
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
            Container(
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
          ],
        ),
      ),
    );
  }
}

// Skills Section - Display tailor categories
class _SkillsSection extends StatelessWidget {
  final List<String> categories;

  const _SkillsSection({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Specializations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.iconGrey,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty)
          Text(
            'No specializations added yet',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map((category) => _SkillChip(skill: category))
                .toList(),
          ),
      ],
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
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
  final int review;

  const _ReviewSection({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.beige,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star,
                color: AppColors.gold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '$review / 5',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.caramel,
                    ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    color: index < review ? AppColors.gold : AppColors.outline,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

