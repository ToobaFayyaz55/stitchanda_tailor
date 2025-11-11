import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import '../base/custom_bottom_nav_bar.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  void _fetchRequests() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      // Fetch all orders for this tailor (we'll filter for -2 status)
      context.read<OrderCubit>().fetchPendingOrderDetailsForTailor(
        authState.tailor.tailor_id,
      );
    }
  }

  List<OrderDetail> _getRequestOrders(List<OrderDetail> orders) {
    // Only show status -2 orders (new requests)
    return orders.where((o) => o.status == -2).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
        automaticallyImplyLeading: false,
        actions: const [
          Icon(Icons.refresh_outlined),
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

          final requestOrders = _getRequestOrders(allOrders);

          return requestOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 80,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No new requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New order requests will appear here',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requestOrders.length,
                  itemBuilder: (context, index) {
                    return BlocListener<OrderCubit, OrderState>(
                      listener: (context, state) {
                        if (state is RequestAccepted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Order accepted! Waiting for customer to book rider.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refresh requests after accept
                          _fetchRequests();
                        } else if (state is RequestRejected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✗ Order request rejected.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          // Refresh requests after reject
                          _fetchRequests();
                        } else if (state is OrderError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: RequestCard(
                        orderDetail: requestOrders[index],
                      ),
                    );
                  },
                );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 4),
    );
  }
}

// Request Card Widget
class RequestCard extends StatelessWidget {
  final OrderDetail orderDetail;

  const RequestCard({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with NEW badge
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order ID: ${orderDetail.orderId}',
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
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description/Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    orderDetail.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estimated Price: Rs. ${orderDetail.totalPrice}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.caramel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthSuccess) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Accept Order Request?'),
                            content: Text(
                              'You are accepting an order from ${orderDetail.customerName}. The customer will then arrange rider pickup.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<OrderCubit>().tailorAcceptRequest(
                                    detailsId: orderDetail.detailsId,
                                    tailorId: authState.tailor.tailor_id,
                                  );
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthSuccess) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reject Order Request?'),
                            content: Text(
                              'You are rejecting an order from ${orderDetail.customerName}. This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<OrderCubit>().tailorRejectRequest(
                                    detailsId: orderDetail.detailsId,
                                    tailorId: authState.tailor.tailor_id,
                                  );
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

