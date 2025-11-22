import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import '../base/custom_bottom_nav_bar.dart';
import 'orders_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess) {
        context.read<OrderCubit>().fetchOrdersForTailorWithCustomerNames(
              authState.tailor.tailor_id,
            );
      }
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, orderState) {
            final authState = context.watch<AuthCubit>().state;

            if (authState is! AuthSuccess) {
              return const Center(child: Text('Please login'));
            }

            final tailor = authState.tailor;

            // Get orders data
            List<Map<String, dynamic>> allOrders = [];
            if (orderState is OrdersListSuccess) {
              allOrders = orderState.orders;
            }

            // Calculate stats
            final activeOrders = allOrders.where((o) {
              final status = o['status'] is int ? o['status'] : int.tryParse(o['status'].toString()) ?? -999;
              return status >= 0 && status < 5; // In progress statuses (0-4)
            }).length;

            final completedOrders = allOrders.where((o) {
              final status = o['status'] is int ? o['status'] : int.tryParse(o['status'].toString()) ?? -999;
              return status >= 5 && status <= 10; // Completed statuses (5-10)
            }).length;

            // Convert review to double (handles both int and double from Firebase)
            final avgRating = tailor.review.toDouble();

            final earnings = allOrders.fold<double>(0.0, (sum, o) {
              final price = (o['total_price'] as num?)?.toDouble() ?? 0.0;
              return sum + price;
            });

            // Filter pending orders (status -2)
            final pendingOrders = allOrders.where((o) {
              final status = o['status'] is int ? o['status'] : int.tryParse(o['status'].toString()) ?? -999;
              return status == 4;
            }).toList();

            // Sort by due date
            pendingOrders.sort((a, b) {
              final aDue = _calculateDaysLeft(a['due_date']);
              final bDue = _calculateDaysLeft(b['due_date']);
              return aDue.compareTo(bDue);
            });

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar and availability
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.beige, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.beige,
                            backgroundImage: tailor.image_path.isNotEmpty
                                ? NetworkImage(tailor.image_path)
                                : null,
                            child: tailor.image_path.isEmpty
                                ? const Icon(Icons.person, size: 30, color: AppColors.deepBrown)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name and role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tailor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tailor',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Availability toggle
                        Column(
                          children: [
                            const Text(
                              'Available',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Switch(
                              value: tailor.availibility_status,
                              onChanged: (value) {
                                context.read<AuthCubit>().updateAvailability(value);
                              },
                              activeTrackColor: AppColors.caramel.withValues(alpha: 0.5),
                              activeThumbColor: AppColors.caramel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats cards (2x2 grid)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Active Orders',
                                value: activeOrders.toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Completed',
                                value: completedOrders.toString(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Avg. Rating',
                                value: avgRating.toStringAsFixed(1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Earnings',
                                value: '${(earnings / 1000).toStringAsFixed(0)}k Pkr',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pending Orders section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OrdersScreen()),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.caramel,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Pending orders list
                  if (orderState is OrderLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (pendingOrders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: const [
                            Icon(Icons.assignment_outlined, size: 64, color: AppColors.textGrey),
                            SizedBox(height: 12),
                            Text(
                              'No Pending Orders',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pendingOrders.length > 3 ? 3 : pendingOrders.length,
                      itemBuilder: (context, index) {
                        final order = pendingOrders[index];
                        return _PendingOrderCard(
                          order: order,
                          daysLeft: _calculateDaysLeft(order['due_date']),
                          daysLeftColor: _getDaysLeftColor(_calculateDaysLeft(order['due_date'])),
                        );
                      },
                    ),

                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 2),
    );
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }
}

// Pending order card widget
class _PendingOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final int daysLeft;
  final Color daysLeftColor;

  const _PendingOrderCard({
    required this.order,
    required this.daysLeft,
    required this.daysLeftColor,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = (order['order_id'] as String?) ?? '';
    final customerName = (order['customer_name'] as String?) ?? 'Customer';
    final totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;

    // Handle status
    int status = -999;
    final statusValue = order['status'];
    if (statusValue is int) {
      status = statusValue;
    } else if (statusValue is String) {
      status = int.tryParse(statusValue) ?? -999;
    }

    final dueDate = order['due_date'];
    final shouldShowDeadline = status != OrderCubit.statusRejected &&
                               !OrderCubit.completedStatuses.contains(status);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to order details if needed
        },
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
                    _StatusBadge(status: status),
                  ],
                ),

                const SizedBox(height: 14),

                // Deadline Container and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Deadline Indicator (only for active orders)
                    if (shouldShowDeadline)
                      Flexible(
                        child: _DeadlineIndicator(
                          daysLeft: daysLeft,
                          hasDate: dueDate != null,
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    if (shouldShowDeadline) const SizedBox(width: 12),

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
                          const Icon(
                            Icons.currency_rupee,
                            size: 16,
                            color: AppColors.caramel,
                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Status Badge widget
class _StatusBadge extends StatelessWidget {
  final int status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: OrderCubit.getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: OrderCubit.getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        OrderCubit.getStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: OrderCubit.getStatusColor(status),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// Deadline Indicator widget
class _DeadlineIndicator extends StatelessWidget {
  final int daysLeft;
  final bool hasDate;

  const _DeadlineIndicator({
    required this.daysLeft,
    required this.hasDate,
  });

  Color _getDeadlineColor() {
    if (daysLeft <= 2) return Colors.red;
    if (daysLeft <= 10) return Colors.orange;
    return Colors.green;
  }

  IconData _getDeadlineIcon() {
    if (daysLeft <= 2) return Icons.warning_amber_rounded;
    return Icons.access_time;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasDate) return const SizedBox.shrink();

    final color = _getDeadlineColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDeadlineIcon(),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '$daysLeft days left',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
