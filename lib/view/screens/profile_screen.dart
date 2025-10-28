import 'package:flutter/material.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/base/custom_bottom_nav_bar.dart';
import 'package:stichanda_tailor/view/screens/profile_details_screen.dart';
import 'package:stichanda_tailor/data/models/tailor_dummy.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _ProfileSummaryCard(),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.person_outline,
                      label: 'Profile Details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileDetailsScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.description_outlined,
                      label: 'Terms & Conditions',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: _ProfileMenuItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: () {
                    debugPrint("Logout pressed");
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ✅ Profile Tab Active
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 1),
    );
  }
}

// ✅ Profile Summary With Dummy Data
class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.beige,
            child: Icon(Icons.person, size: 50, color: AppColors.deepBrown),
          ),
          const SizedBox(height: 12),

          /// ✅ Tailor name from dummy model
          Text(
            currentTailor.name,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppColors.textBlack,
              fontWeight: FontWeight.w600,
            ),
          ),

          /// ✅ Tailor role (Tailor)
          Text(
            currentTailor.role,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.textGrey,
            ),
          ),

          const SizedBox(height: 14),

          /// ✅ Phone from dummy model
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: currentTailor.phone,
          ),

          /// ✅ Email from dummy model
          _ContactRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: currentTailor.email,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.iconGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$label: $value",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.textBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.deepBrown;

    return ListTile(
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isDestructive
          ? null
          : Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconGrey),
      onTap: onTap,
    );
  }
}
