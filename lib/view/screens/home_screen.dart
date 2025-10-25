import 'package:flutter/material.dart';
import 'package:stichanda_tailor/theme/theme.dart';

// --- Dummy Data ---
class Order {
  final String id;
  final String title;
  final String client;
  final String daysLeft;

  Order({
    required this.id,
    required this.title,
    required this.client,
    required this.daysLeft,
  });
}

final List<Order> pendingOrders = [
  Order(
    id: '#12345',
    title: 'Suit Alteration',
    client: 'Atif Aslam',
    daysLeft: '2 days left',
  ),
  Order(
    id: '#12346',
    title: 'Bridal Suit',
    client: 'Justin Bieber',
    daysLeft: '10 days left',
  ),
  Order(
    id: '#12347',
    title: 'Party Dress',
    client: 'Tooba Fayyaz',
    daysLeft: '28 days left',
  ),
];
// -----------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'), // Matches the text in the image
        // The rest of the styling comes from appBarTheme in theme.dart
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileHeaderCard(),
              const SizedBox(height: 16),
              const StatsGrid(),
              const SizedBox(height: 24),
              _buildPendingOrdersHeader(context),
              const SizedBox(height: 8),
              ...pendingOrders.map((order) => PendingOrderTile(order: order)).toList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  Widget _buildPendingOrdersHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Pending Orders',
          style: Theme.of(context).textTheme.titleLarge, // Using titleLarge for section heading
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View All'), // Styled by textButtonTheme
        ),
      ],
    );
  }
}

// --- 1. Profile Header Card ---
class ProfileHeaderCard extends StatefulWidget {
  const ProfileHeaderCard({super.key});

  @override
  State<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<ProfileHeaderCard> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // From your theme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline), // Soft border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/images/laiba.png'), // Placeholder
            backgroundColor: AppColors.beige,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laiba Majeed',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBrown, // Use deepBrown for primary text
                ),
              ),
              Text(
                'Tailor',
                style: Theme.of(context).textTheme.bodyMedium, // Use bodyMedium for subtitle
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Available',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: _isAvailable ? AppColors.success : AppColors.textGrey,
                ),
              ),
              Switch(
                value: _isAvailable,
                onChanged: (bool value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: AppColors.caramel, // Main accent
                inactiveThumbColor: AppColors.iconGrey,
                inactiveTrackColor: AppColors.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 2. Stats Grid ---
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8, // Adjust for desired card shape
      physics: const NeverScrollableScrollPhysics(), // Important for nested scroll views
      children: const [
        _StatCard(title: 'Active Orders', value: '3'),
        _StatCard(title: 'Completed', value: '15'),
        _StatCard(title: 'Avg. Rating', value: '4.8'),
        _StatCard(title: 'Earnings', value: '20K Pkr'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.beige, // Lighter accent color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.deepBrown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppColors.deepBrown,
              fontSize: 28, // Slightly larger for impact
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. Pending Order Tile ---
class PendingOrderTile extends StatelessWidget {
  final Order order;

  const PendingOrderTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // Remove default card elevation
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline), // Use outline for border
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.id,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              order.title,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Client: ${order.client}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: _getDaysLeftColor(order.daysLeft)),
              const SizedBox(width: 4),
              Text(
                order.daysLeft,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: _getDaysLeftColor(order.daysLeft),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'In Progress',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.deepBrown, // A soft color for status
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.iconGrey,
        ),
        onTap: () {
          // Navigate to order details
        },
      ),
    );
  }

  // Helper to change color based on urgency
  Color _getDaysLeftColor(String daysLeft) {
    final int days = int.tryParse(daysLeft.split(' ')[0]) ?? 99;
    if (days <= 5) {
      return AppColors.error; // Red for urgent
    } else if (days <= 15) {
      return AppColors.caramel; // Caramel for getting close
    } else {
      return AppColors.success; // Green/Success for long time left
    }
  }
}

// --- 4. Custom Bottom Navigation Bar ---
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 2, // Highlight 'Home'
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.caramel, // Caramel for active item
        unselectedItemColor: AppColors.iconGrey, // IconGrey for inactive items
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // To show all labels
        selectedLabelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.caramel,
        ),
        unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 12,
          color: AppColors.iconGrey,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.content_paste), label: 'Requests'),
        ],
      ),
    );
  }
}