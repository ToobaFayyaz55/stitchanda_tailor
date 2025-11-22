import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/base/custom_bottom_nav_bar.dart';
import 'package:stichanda_tailor/view/screens/profile_details_screen.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';

import '../gate/session_gate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final tailor = state.tailor;


            return SafeArea(
              child: Stack(
                children: [
                  // scrollable main content
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Top header with background image (without avatar)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/Tailor_reg.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Avatar - positioned to overlap header and white background
                        Transform.translate(
                          offset: const Offset(0, -80), // Move up to overlap more into coffee background
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              key: ValueKey(tailor.image_path),
                              radius: 60,
                              backgroundColor: AppColors.beige,
                              backgroundImage: tailor.image_path.isNotEmpty
                                  ? NetworkImage('${tailor.image_path}?v=${DateTime.now().millisecondsSinceEpoch}')
                                  : null,
                              child: tailor.image_path.isEmpty
                                  ? const Icon(Icons.person, size: 50, color: AppColors.deepBrown)
                                  : null,
                            ),
                          ),
                        ),

                        // Name and Role (adjust spacing due to overlapping avatar)
                        Transform.translate(
                          offset: const Offset(0, -80),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Text(
                                  tailor.name,
                                  style: const TextStyle(
                                    fontSize: 20,
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
                          ),
                        ),

                        Transform.translate(
                          offset: const Offset(0, -62),
                          child: Column(
                            children: [
                              const Divider(height: 1),

                              // Contact Information
                              _ContactRow(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: tailor.phone,
                              ),
                              const Divider(height: 1, indent: 56),
                              _ContactRow(
                                icon: Icons.mail,
                                label: 'Mail',
                                value: tailor.email,
                              ),

                              const Divider(height: 1),

                              // Menu Items
                              _ProfileMenuItem(
                                icon: Icons.person_outline,
                                label: 'Profile Details',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ProfileDetailsScreen()),
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              _ProfileMenuItem(
                                icon: Icons.settings_outlined,
                                label: 'Settings',
                                onTap: () {},
                              ),
                              const Divider(height: 1, indent: 56),
                              _ProfileMenuItem(
                                icon: Icons.description_outlined,
                                label: 'Terms and Conditions',
                                onTap: () {},
                              ),
                              const Divider(height: 1, indent: 56),
                              _ProfileMenuItem(
                                icon: Icons.logout,
                                label: 'Logout',
                                isDestructive: false,
                                onTap: () {
                                  showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirm Logout'),
                                      content: const Text('Are you sure you want to logout?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Logout'),
                                        ),
                                      ],
                                    ),
                                  ).then((confirmed) async {
                                    if (confirmed == true) {
                                      await context.read<AuthCubit>().logout();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You have been logged out')),
                                      );
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SessionGate()),
                                        (route) => false,
                                      );
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 80), // Space for bottom nav
                      ],
                    ),
                  ),

                  // uploading overlay
                  if (context.watch<AuthCubit>().state is AuthLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            );
          } else if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AuthError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Unable to load profile'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Retry by navigating back to login
                      await context.read<AuthCubit>().logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SessionGate()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            );
          } else {
            // AuthInitial state
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),

      // Profile Tab Active
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 1),
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.textBlack),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textBlack,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w400,
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
    final color = isDestructive ? AppColors.error : AppColors.textBlack;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}
