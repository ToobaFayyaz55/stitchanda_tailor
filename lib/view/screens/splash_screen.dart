import 'package:flutter/material.dart';
import 'package:stichanda_tailor/theme/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/Stitchanda_Tailor_Logo.png'),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.caramel),
          ],
        ),
      ),
    );
  }
}
