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
                stream: context.read<OrderCubit>().streamOrdersForTailorWithCustomerNames(_tailorId, statuses: [OrderRepo.STATUS_UNACCEPTED]),
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
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 4),
    );
  }
}

class _OrderRequestCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderRequestCard({required this.order, required this.onTap});

  int _calculateDaysLeft(dynamic dueDate) {
    if (dueDate == null) return 0;
    DateTime? dt;
    if (dueDate is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(dueDate);
    } else if (dueDate is String) {
      dt = DateTime.tryParse(dueDate);
    } else if (dueDate.runtimeType.toString().contains('Timestamp')) {
      dt = (dueDate as dynamic).toDate();
    }
    if (dt == null) return 0;

    final now = DateTime.now();
    final difference = dt.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  Color _getDaysLeftColor(int daysLeft) {
    if (daysLeft <= 2) return Colors.red;
    if (daysLeft <= 10) return Colors.orange;
    return Colors.green;
  }

  IconData _getDeadlineIcon(int daysLeft) {
    if (daysLeft <= 2) return Icons.warning_amber_rounded;
    return Icons.access_time;
  }

  @override
  Widget build(BuildContext context) {
    final orderId = (order['order_id'] as String?) ?? '';
    final totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;
    final customerName = (order['customer_name'] as String?) ?? 'Customer';
    final dueDate = order['delivery_date'];
    final daysLeft = _calculateDaysLeft(dueDate);
    final daysLeftColor = _getDaysLeftColor(daysLeft);

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.surface.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Status Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$orderId',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.caramel.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppColors.caramel,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // NEW Badge for requests
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Deadline Container and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Deadline Indicator
                    if (dueDate != null)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: daysLeftColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: daysLeftColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getDeadlineIcon(daysLeft),
                                size: 16,
                                color: daysLeftColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$daysLeft days left',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: daysLeftColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    if (dueDate != null) const SizedBox(width: 12),

                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.caramel.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.caramel.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('PKR ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.caramel)),
                          Text(
                            totalPrice.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.caramel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Accept/Reject Buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAccept(context, orderId),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.caramel,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleReject(context, orderId),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textGrey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAccept(BuildContext context, String orderId) {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthSuccess) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Accept Order Request?'),
          content: const Text('Customer will arrange rider pickup after acceptance.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramel),
              onPressed: () {
                Navigator.pop(context);
                context.read<OrderCubit>().acceptOrderById(
                      orderId: orderId,
                      tailorId: auth.tailor.tailor_id,
                    );
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      );
    }
  }

  void _handleReject(BuildContext context, String orderId) {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthSuccess) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reject Order Request?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                context.read<OrderCubit>().rejectOrderById(
                      orderId: orderId,
                      tailorId: auth.tailor.tailor_id,
                    );
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      );
    }
  }
}
