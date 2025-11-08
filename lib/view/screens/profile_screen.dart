import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/base/custom_bottom_nav_bar.dart';
import 'package:stichanda_tailor/view/screens/profile_details_screen.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar replaced with a minimal top spacing because design uses a colored header block
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final tailor = state.tailor;

            // image picker instance
            final picker = ImagePicker();

            // responsive sizes
            final mq = MediaQuery.of(context);
            final isSmall = mq.size.height < 700;
            final headerHeight = isSmall ? 90.0 : 110.0;
            final avatarRadius = isSmall ? 34.0 : 40.0;

            return SafeArea(
              child: Stack(
                children: [
                  // scrollable main content
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Top caramel header
                        Container(
                          height: headerHeight,
                          color: AppColors.caramel,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            tailor.name,
                            style: const TextStyle(
                              color: AppColors.textBlack,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        // spacing to match the overlapping avatar area
                        SizedBox(height: avatarRadius + 18),

                        // Avatar and summary card (positioned visually over header)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Avatar (displayed above the summary card)
                              GestureDetector(
                                onTap: () async {
                                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                                  if (picked == null) return;
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Upload Profile Picture'),
                                      content: const Text('Do you want to upload the selected image as your profile picture?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Upload')),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  await context.read<AuthCubit>().updateProfileImage(picked.path);
                                },
                                child: Transform.translate(
                                  offset: Offset(0, -avatarRadius - 22),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundColor: AppColors.beige,
                                      backgroundImage: tailor.image_path.isNotEmpty ? NetworkImage(tailor.image_path) : null,
                                      child: tailor.image_path.isEmpty ? Icon(Icons.person, size: avatarRadius, color: AppColors.deepBrown) : null,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Name / role / verification row
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tailor.name,
                                                style: TextStyle(
                                                  fontSize: isSmall ? 16 : 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.deepBrown,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Tailor',
                                                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // small verification pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.verified, size: 14, color: Colors.green),
                                              const SizedBox(width: 6),
                                              Text(
                                                tailor.verfication_status,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // rating
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          tailor.review.toStringAsFixed(1),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Contact Card
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: Column(
                                  children: [
                                    _ContactRow(icon: Icons.phone_outlined, label: 'Phone', value: tailor.phone),
                                    const Divider(height: 1),
                                    _ContactRow(icon: Icons.mail_outline, label: 'Mail', value: tailor.email),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Menu Card
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
                                          MaterialPageRoute(builder: (context) => const ProfileDetailsScreen()),
                                        );
                                      },
                                    ),
                                    const Divider(height: 1),
                                    _ProfileMenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
                                    const Divider(height: 1),
                                    _ProfileMenuItem(icon: Icons.description_outlined, label: 'Terms & Conditions', onTap: () {}),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Logout Card (with confirmation)
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
                                    showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirm Logout'),
                                        content: const Text('Are you sure you want to logout?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Logout')),
                                        ],
                                      ),
                                    ).then((confirmed) {
                                      if (confirmed == true) {
                                        context.read<AuthCubit>().logout();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have been logged out')));
                                        Navigator.pushReplacementNamed(context, '/login');
                                      }
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // uploading overlay
                  if (context.watch<AuthCubit>().state is AuthLoading)
                    Positioned.fill(
                      child: Container(
                        color: const Color.fromRGBO(0, 0, 0, 0.25),
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
                    onPressed: () {
                      // Retry by navigating back to login
                      context.read<AuthCubit>().logout();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.iconGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
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
