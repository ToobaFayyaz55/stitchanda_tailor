import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import '../base/custom_bottom_nav_bar.dart';
import 'order_details_screen.dart';
import 'package:stichanda_tailor/data/repository/order_repo.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'accepted'; // accepted | inProgress | completed

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthSuccess) {
      switch (_selectedFilter) {
        case 'accepted':
          context.read<OrderCubit>().fetchAcceptedOrdersForTailor(auth.tailor.tailor_id);
          break;
        case 'inProgress':
          // In-progress: statuses 0..3 (after acceptance until tailor receives)
          context.read<OrderCubit>().fetchOrdersForTailor(auth.tailor.tailor_id, statuses: [0, 1, 2, 3]);
          break;
        case 'completed':
          // Completed / tail end statuses 4..11
          context.read<OrderCubit>().fetchOrdersForTailor(auth.tailor.tailor_id, statuses: [4,5,6,7,8,9,10,11]);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            selected: _selectedFilter,
            onChanged: (v) {
              setState(() => _selectedFilter = v);
              _fetchOrders();
            },
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _buildOrdersStream(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textGrey),
                        const SizedBox(height: 16),
                        Text('No orders', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Change filter or wait for updates', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 4),
    );
  }

  Stream<List<Map<String, dynamic>>> _buildOrdersStream(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthSuccess) return const Stream.empty();
    switch (_selectedFilter) {
      case 'accepted':
        return context.read<OrderCubit>().streamOrdersForTailor(auth.tailor.tailor_id, statuses: [OrderRepo.STATUS_ACCEPTED]);
      case 'inProgress':
        return context.read<OrderCubit>().streamOrdersForTailor(auth.tailor.tailor_id, statuses: [0,1,2,3]);
      case 'completed':
        return context.read<OrderCubit>().streamOrdersForTailor(auth.tailor.tailor_id, statuses: [4,5,6,7,8,9,10,11]);
      default:
        return context.read<OrderCubit>().streamOrdersForTailor(auth.tailor.tailor_id);
    }
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _chip('Accepted'),
          _chip('In Progress'),
          _chip('Completed'),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final v = label.toLowerCase().replaceAll(' ', '');
    final isSel = selected == v;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) => onChanged(v),
      selectedColor: AppColors.caramel,
      labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textBlack),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final pickup = order['pickup_location'] as Map<String, dynamic>?;
    final dropoff = order['dropoff_location'] as Map<String, dynamic>?;
    final price = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final orderId = (order['order_id'] as String?) ?? '';
    final status = (order['status'] as int?) ?? -999;

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Text('Order #$orderId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Pickup: ${pickup?['full_address'] ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                        Text('Dropoff: ${dropoff?['full_address'] ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Total: Rs. ${price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.caramel, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(int s) {
    switch (s) {
      case -1: return 'Accepted';
      case 0: return 'Unassigned';
      case 1: return 'Rider Assigned';
      case 2: return 'Picked (Cust)';
      case 3: return 'Completed (Cust)';
      case 4: return 'Received';
      case 5: return 'Tailor Done';
      case 6: return 'Call Rider';
      case 7: return 'Rider Assigned';
      case 8: return 'Picked (Tailor)';
      case 9: return 'Delivered';
      case 10: return 'Confirmed';
      case 11: return 'Self Delivery';
      case -2: return 'Pending';
      case -3: return 'Rejected';
      default: return 'Unknown';
    }
  }

  Color _statusColor(int s) {
    switch (s) {
      case -2: return Colors.red;
      case -3: return Colors.grey;
      case -1: return Colors.orange;
      case 0: return Colors.blueGrey;
      case 1: return Colors.blue;
      case 2: return Colors.purple;
      case 3: return Colors.indigo;
      case 4: return Colors.cyan;
      case 5: return Colors.green.shade700;
      case 6: return Colors.deepOrange;
      case 7: return Colors.deepPurple;
      case 8: return Colors.teal;
      case 9: return Colors.lightGreen;
      case 10: return Colors.greenAccent.shade400;
      case 11: return Colors.brown;
      default: return Colors.black45;
    }
  }
}
