import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import '../base/custom_bottom_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late String _selectedStatus; // 'pending', 'inProgress', 'completed'

  @override
  void initState() {
    super.initState();
    _selectedStatus = 'inProgress'; // Default filter

    // Fetch orders when screen loads
    _fetchOrders();
  }

  void _fetchOrders() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      // Fetch all orders for this tailor
      context.read<OrderCubit>().fetchPendingOrderDetailsForTailor(
        authState.tailor.tailor_id,
      );
    }
  }

  List<OrderDetail> _getFilteredOrders(List<OrderDetail> orders) {
    // Filter out requests (status -2), only show from -1 onwards
    final nonRequestOrders = orders.where((o) => o.status >= -1).toList();

    switch (_selectedStatus) {
      case 'pending':
        return nonRequestOrders.where((o) => o.status == -1).toList();
      case 'inProgress':
        return nonRequestOrders.where((o) => o.status >= 0 && o.status <= 3).toList();
      case 'completed':
        return nonRequestOrders.where((o) => o.status >= 4 && o.status <= 11).toList();
      default:
        return nonRequestOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        actions: const [
          Icon(Icons.settings_outlined),
          SizedBox(width: 12),
        ],
      ),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<OrderDetail> allOrders = [];
          if (state is OrderDetailsSuccess) {
            allOrders = state.orderDetails;
          }

          final filteredOrders = _getFilteredOrders(allOrders);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Pending',
                        isSelected: _selectedStatus == 'pending',
                        onPressed: () => setState(() => _selectedStatus = 'pending'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'In Progress',
                        isSelected: _selectedStatus == 'inProgress',
                        onPressed: () => setState(() => _selectedStatus = 'inProgress'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        isSelected: _selectedStatus == 'completed',
                        onPressed: () => setState(() => _selectedStatus = 'completed'),
                      ),
                    ],
                  ),
                ),
              ),

              // Orders List
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          return OrderListItem(
                            orderDetail: filteredOrders[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 4),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      selectedColor: AppColors.caramel,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textBlack,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// Order List Item Widget
class OrderListItem extends StatelessWidget {
  final OrderDetail orderDetail;

  const OrderListItem({
    required this.orderDetail,
  });

  String _getStatusLabel() {
    switch (orderDetail.status) {
      case -2:
        return 'Request';
      case -1:
        return 'Accepted (Waiting for Rider)';
      case 0:
        return 'Unassigned';
      case 1:
        return 'Rider Assigned';
      case 2:
        return 'Picked up from Customer';
      case 3:
        return 'Delivered to Tailor';
      case 4:
        return 'Received by Tailor';
      case 5:
        return 'Completed';
      case 6:
        return 'Driver Requested';
      case 7:
        return 'Driver Assigned';
      case 8:
        return 'Picked up from Tailor';
      case 9:
        return 'Delivered';
      case 11:
        return 'Self-Delivery';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor() {
    switch (orderDetail.status) {
      case -2:
        return Colors.red;
      case -1:
        return Colors.orange;
      case 0:
      case 1:
        return Colors.blue;
      case 2:
        return Colors.purple;
      case 3:
      case 4:
        return Colors.cyan;
      case 5:
      case 6:
      case 7:
      case 8:
        return Colors.amber;
      case 9:
      case 11:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderDetail.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderDetail.orderId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              orderDetail.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Price and Payment Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price: Rs. ${orderDetail.totalPrice}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.caramel,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payment: ${orderDetail.paymentStatus}',
                      style: TextStyle(
                        fontSize: 12,
                        color: orderDetail.paymentStatus == 'Pending'
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
