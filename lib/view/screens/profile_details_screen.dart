import 'package:flutter/material.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/data/models/tailor_dummy.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DetailHeader(),

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

              // ✅ Using dummy model data
              _EditableProfileField(label: 'Name', value: currentTailor.name),
              _EditableProfileField(label: 'Address', value: currentTailor.address),
              _EditableProfileField(label: 'Gender', value: currentTailor.gender),
              _EditableProfileField(label: 'Experience', value: currentTailor.experience),
              _EditableProfileField(label: 'Category', value: currentTailor.category),

              const SizedBox(height: 24),
              const _SkillsSection(),

              const SizedBox(height: 24),
              const _ProjectsSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Profile Avatar + Name from Dummy Data
class _DetailHeader extends StatelessWidget {
  const _DetailHeader();

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
                child: Icon(Icons.person, size: 50, color: AppColors.deepBrown),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.caramel,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentTailor.name,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            currentTailor.role,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ✅ Reusable Editable Field Widget
class _EditableProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _EditableProfileField({required this.label, required this.value});

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.deepBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: AppColors.textBlack,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.caramel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Skills Section using dummy data
class _SkillsSection extends StatelessWidget {
  const _SkillsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Skills', style: Theme.of(context).textTheme.titleLarge),
            Icon(Icons.edit_outlined, size: 20, color: AppColors.iconGrey),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: currentTailor.skills.map((s) => _SkillChip(skill: s)).toList(),
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
      label: Text(skill,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: AppColors.deepBrown,
            fontWeight: FontWeight.w500,
          )),
      backgroundColor: AppColors.beige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outline),
      ),
    );
  }
}

// ✅ Dummy Project Gallery
class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Projects', style: Theme.of(context).textTheme.titleLarge),
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.caramel,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: currentTailor.projects.length,
          itemBuilder: (context, i) => _ProjectCard(project: currentTailor.projects[i]),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final TailorProject project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: project.coverColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 40, color: Colors.white54),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.title,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(project.rating, style: Theme.of(context).textTheme.bodyMedium),
                    const Spacer(),
                    Text(project.price,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.deepBrown,
                        )),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
