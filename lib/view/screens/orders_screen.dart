// lib/view/orders/orders_screen.dart

import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../data/mock_data.dart';
import '../base/custom_bottom_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus _selectedStatus = OrderStatus.inProgress; // ✅ Default = Active (in progress + completed)

  List<Order> _getFilteredOrders() {
    switch (_selectedStatus) {
      case OrderStatus.pending:
        return mockOrders.where((o) => o.status == OrderStatus.pending).toList();

      case OrderStatus.inProgress:
        return mockOrders.where((o) => o.status == OrderStatus.inProgress).toList();

      case OrderStatus.completed:
        return mockOrders.where((o) => o.status == OrderStatus.completed).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: const [
          Icon(Icons.settings_outlined),
          SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),

          // ✅ Filter Tabs
          _buildFilterTabs(context),

          // ✅ Order Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total: ${filteredOrders.length}',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // ✅ Orders List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) =>
                  OrderListItem(
                    order: filteredOrders[index],
                    showActions: filteredOrders[index].status == OrderStatus.pending,
                  ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 3),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TabButton(
              label: 'Pending',
              status: OrderStatus.pending,
              isSelected: _selectedStatus == OrderStatus.pending,
              onPressed: () => setState(() => _selectedStatus = OrderStatus.pending),
            ),
            _TabButton(
              label: 'In Progress',
              status: OrderStatus.inProgress,
              isSelected: _selectedStatus == OrderStatus.inProgress,
              onPressed: () => setState(() => _selectedStatus = OrderStatus.inProgress),
            ),
            _TabButton(
              label: 'Completed',
              status: OrderStatus.completed,
              isSelected: _selectedStatus == OrderStatus.completed,
              onPressed: () => setState(() => _selectedStatus = OrderStatus.completed),
            ),
          ],
        ),
      ),
    );
  }
}

// 📌 Tab Button Component
class _TabButton extends StatelessWidget {
  final String label;
  final OrderStatus status;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.status,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isSelected ? AppColors.caramel : AppColors.outline,
          foregroundColor:
          isSelected ? Colors.white : AppColors.textBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isSelected
                ? BorderSide.none
                : const BorderSide(color: AppColors.outline),
          ),
          textStyle: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

// ✅ Order Item UI
class OrderListItem extends StatelessWidget {
  final Order order;
  final bool showActions;

  const OrderListItem({
    super.key,
    required this.order,
    this.showActions = false,
  });

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.inProgress:
        return AppColors.caramel;
      default:
        return AppColors.textGrey;
    }
  }

  String _statusText() {
    return order.status == OrderStatus.completed ? 'Completed' : 'In Progress';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.id, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(order.title,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Client: ${order.client}'),
              ],
            ),
            trailing: Text(
              order.price,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.deepBrown,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  _statusText(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (order.status != OrderStatus.completed)
                  Text(
                    order.daysLeft,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          if (showActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
