import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import '../base/custom_bottom_nav_bar.dart';
import 'order_details_screen.dart';
import 'package:stichanda_tailor/data/repository/order_repo.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late String _tailorId;
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      _tailorId = authState.tailor.tailor_id;
    } else {
      _tailorId = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is AuthSuccess) {
                context.read<OrderCubit>().fetchPendingOrdersForTailor(authState.tailor.tailor_id);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is RequestAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted'), backgroundColor: Colors.green));
          } else if (state is RequestRejected) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order rejected'), backgroundColor: Colors.orange));
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: _tailorId.isEmpty
            ? const Center(child: Text('Not authenticated'))
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: context.read<OrderCubit>().streamOrdersForTailor(_tailorId, statuses: [OrderRepo.STATUS_UNACCEPTED]),
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
                          Icon(Icons.mail_outline, size: 80, color: AppColors.textGrey),
                          const SizedBox(height: 16),
                          Text('No new requests', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('New order requests will appear here', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderRequestCard(order: order, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                        );
                      });
                    },
                  );
                },
              ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 1),
    );
  }
}

class _OrderRequestCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderRequestCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pickup = order['pickup_location'] as Map<String, dynamic>?;
    final dropoff = order['dropoff_location'] as Map<String, dynamic>?;
    final price = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final orderId = (order['order_id'] as String?) ?? '';

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
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
                        Text(
                          'Pickup: ${pickup?['full_address'] ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dropoff: ${dropoff?['full_address'] ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: Rs. ${price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.caramel, fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      _AcceptButton(orderId: orderId),
                      const SizedBox(width: 8),
                      _RejectButton(orderId: orderId),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  final String orderId;
  const _AcceptButton({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      onPressed: () {
        final auth = context.read<AuthCubit>().state;
        if (auth is AuthSuccess) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Accept Order Request?'),
              content: const Text('Customer will arrange rider pickup after acceptance.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<OrderCubit>().acceptOrderById(orderId: orderId, tailorId: auth.tailor.tailor_id);
                  },
                  child: const Text('Accept'),
                ),
              ],
            ),
          );
        }
      },
      icon: const Icon(Icons.check),
      label: const Text('Accept'),
    );
  }
}

class _RejectButton extends StatelessWidget {
  final String orderId;
  const _RejectButton({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: () {
        final auth = context.read<AuthCubit>().state;
        if (auth is AuthSuccess) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Reject Order Request?'),
              content: const Text('This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<OrderCubit>().rejectOrderById(orderId: orderId, tailorId: auth.tailor.tailor_id);
                  },
                  child: const Text('Reject'),
                ),
              ],
            ),
          );
        }
      },
      icon: const Icon(Icons.close),
      label: const Text('Reject'),
    );
  }
}
