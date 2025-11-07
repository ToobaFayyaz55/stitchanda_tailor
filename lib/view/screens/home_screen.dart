import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch orders when screen loads
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<OrderCubit>().fetchPendingOrderDetailsForTailor(
            authState.tailor.tailor_id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Dashboard'),
        backgroundColor: AppColors.caramel,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is OrderDetailsSuccess) {
            if (state.orderDetails.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Orders Found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You don\'t have any orders yet',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orderDetails.length,
              itemBuilder: (context, index) {
                final orderDetail = state.orderDetails[index];
                return OrderDetailCard(orderDetail: orderDetail);
              },
            );
          } else if (state is OrderError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthSuccess) {
                        context.read<OrderCubit>().fetchPendingOrderDetailsForTailor(
                              authState.tailor.tailor_id,
                            );
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('No data'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.caramel,
        onPressed: () {
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthSuccess) {
            context.read<OrderCubit>().fetchPendingOrderDetailsForTailor(
                  authState.tailor.tailor_id,
                );
          }
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// ==================== ORDER DETAIL CARD WIDGET ====================

class OrderDetailCard extends StatelessWidget {
  final OrderDetail orderDetail;

  const OrderDetailCard({
    Key? key,
    required this.orderDetail,
  }) : super(key: key);

  String _getStatusLabel(int status) {
    switch (status) {
      case -1:
        return 'Pending';
      case 0:
        return 'Accepted';
      case 1:
        return 'In Progress';
      case 2:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case -1:
        return Colors.orange;
      case 0:
        return Colors.blue;
      case 1:
        return Colors.purple;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    color: _getStatusColor(orderDetail.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(orderDetail.status),
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
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textBlack,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Measurements
            if (orderDetail.measurements != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Measurements',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chest: ${orderDetail.measurements!.chest}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Waist: ${orderDetail.measurements!.waist}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Shoulder: ${orderDetail.measurements!.shoulder}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Footer with price and payment status
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.caramel,
                  ),
                  onPressed: () {
                    // Navigate to order detail screen
                  },
                  child: const Text(
                    'View',
                    style: TextStyle(color: Colors.white),
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

