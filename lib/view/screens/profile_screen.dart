import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/base/custom_bottom_nav_bar.dart';
import 'package:stichanda_tailor/view/screens/profile_details_screen.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';

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
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileSummaryCard(tailor: state.tailor),
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
                          context.read<AuthCubit>().logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Unable to load profile'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            );
          }
        },
      ),

      // ✅ Profile Tab Active
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 1),
    );
  }
}

// ✅ Profile Summary With Real Firebase Data
class _ProfileSummaryCard extends StatelessWidget {
  final dynamic tailor;

  const _ProfileSummaryCard({required this.tailor});

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

          /// ✅ Tailor name from Firebase
          Text(
            tailor.name,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppColors.textBlack,
              fontWeight: FontWeight.w600,
            ),
          ),

          /// ✅ Tailor verification status
          Text(
            tailor.verfication_status ?? 'Not verified',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.textGrey,
            ),
          ),

          const SizedBox(height: 14),

          /// ✅ Phone from Firebase
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: tailor.phone,
          ),

          /// ✅ Email from Firebase
          _ContactRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: tailor.email,
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

