import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:stichanda_tailor/view/screens/home_screen.dart';
import 'package:stichanda_tailor/view/screens/orders_screen.dart';
import 'package:stichanda_tailor/view/screens/profile_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int activeIndex;

  const CustomBottomNavBar({super.key, required this.activeIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == activeIndex) return;

    switch (index) {
      case 0:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat Coming Soon ✨')),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: activeIndex,
      onTap: (index) => _onItemTapped(context, index),
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.caramel,
      unselectedItemColor: AppColors.iconGrey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), label: 'Orders'),
      ],
    );
  }
}
