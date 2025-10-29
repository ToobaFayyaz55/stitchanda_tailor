// lib/view/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import the cubit only (do NOT import auth_state.dart directly to avoid "part of" import errors).
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import '../../data/mock_data.dart';
import '../../data/models/tailor_dummy.dart';
import '../base/custom_bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // show orders with status = inProgress on this Home screen
    final List<Order> inProgressOrders =
    mockOrders.where((o) => o.status == OrderStatus.inProgress).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),

      // Listen to AuthCubit state and show profile when available
      body: BlocBuilder<AuthCubit, dynamic>(
        builder: (context, state) {
          // If your AuthCubit exposes specific state classes (AuthLoading/AuthSuccess),
          // these will still work if they are visible via auth_cubit.dart
          if (state != null && state.runtimeType.toString() == 'AuthLoading') {
            return const Center(child: CircularProgressIndicator());
          }

          // Try to extract a profile object from the state robustly:
          // check for common field names (userProfile / user / tailor).
          var tailorFromState;
          try {
            tailorFromState =
                (state as dynamic).userProfile ?? (state as dynamic).user ?? (state as dynamic).tailor;
          } catch (_) {
            tailorFromState = null;
          }

          // If no profile in state, fall back to dummy local currentTailor
          final tailor = tailorFromState ?? currentTailor;

          // Build content
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pass name + role to header card
                ProfileHeaderCard(
                  name: tailor.name ?? currentTailor.name,
                  role: tailor.role ?? currentTailor.role,
                ),
                const SizedBox(height: 16),

                const StatsGrid(),
                const SizedBox(height: 24),

                _buildOrdersHeader(context),
                const SizedBox(height: 8),

                // Render in-progress orders
                ...inProgressOrders
                    .map((order) => PendingOrderTile(order: order))
                    .toList(),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 2),
    );
  }

  Widget _buildOrdersHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'In Progress Orders',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: () {},
          child: const Text('View All'),
        ),
      ],
    );
  }
}

/// ---------------- Profile Header Card ----------------
class ProfileHeaderCard extends StatefulWidget {
  final String name;
  final String role;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.role,
  });

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
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
            backgroundColor: AppColors.beige,
            child: Icon(Icons.person, color: AppColors.deepBrown),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBrown,
                ),
              ),
              Text(
                widget.role,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isAvailable ? 'Available' : 'Offline',
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
                activeColor: AppColors.caramel,
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

/// ---------------- Stats Grid ----------------
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _StatCard(title: 'Active Orders', value: '3'),
        _StatCard(title: 'Completed', value: '15'),
        _StatCard(title: 'Avg. Rating', value: '4.8'),
        _StatCard(title: 'Earnings', value: '20K PKR'),
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
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style:
            Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textBlack),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppColors.textBlack,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Pending Order Tile ----------------
class PendingOrderTile extends StatelessWidget {
  final Order order;
  const PendingOrderTile({super.key, required this.order});

  Color _getDaysLeftColor(String daysLeft) {
    final int days = int.tryParse(daysLeft.split(' ')[0]) ?? 99;
    if (days <= 5) return AppColors.error;
    if (days <= 15) return AppColors.caramel;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getDaysLeftColor(order.daysLeft);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.id, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(order.title,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                )),
            const SizedBox(height: 4),
            Text('Client: ${order.client}',
                style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textGrey)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(order.daysLeft,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              Text(
                order.status == OrderStatus.completed ? 'Completed' : 'In Progress',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.deepBrown,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconGrey),
        onTap: () {
          // TODO: navigate to order details
        },
      ),
    );
  }
}
