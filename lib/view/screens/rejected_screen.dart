import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'login_screen.dart';

class RejectedScreen extends StatelessWidget {
  final String email;
  final String name;

  const RejectedScreen({
    required this.email,
    required this.name,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Red X Icon - Rejection icon
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    size: 80,
                    color: Colors.red[600],
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                const Text(
                  'Verification Rejected',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBlack,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Personalized greeting
                Text(
                  'Hello $name,',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBlack,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Rejection Info Box - Light Pink background
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0), // Light pink
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFDDDD), // Lighter pink border
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your registration could not be verified',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'After reviewing your application and documents, we were unable to verify your information at this time.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Common reasons for rejection:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRejectionReason('Invalid or unclear CNIC image'),
                      const SizedBox(height: 6),
                      _buildRejectionReason('Information mismatch'),
                      const SizedBox(height: 6),
                      _buildRejectionReason('Incomplete documentation'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // What you can do section - Light blue background
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF), // Light blue
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE0EBFF), // Lighter blue border
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What you can do?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildOption(
                        'Contact Support',
                        'Reach out to our support team to discuss your application',
                      ),
                      const SizedBox(height: 12),
                      _buildOption(
                        'Reapply Later',
                        'You can create a new account with updated information after 30 days',
                      ),
                      const SizedBox(height: 12),
                      _buildOption(
                        'Appeal',
                        'Contact our team to appeal this decision with additional documents',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Contact Support Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.caramel,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support contact feature coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                      'Contact Support Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Return to Login Button - Outlined
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.caramel, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      context.read<AuthCubit>().logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Return to Login',
                      style: TextStyle(
                        color: AppColors.caramel,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildRejectionReason(String reason) {
    return Row(
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            reason,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildOption(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.caramel.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.caramel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

