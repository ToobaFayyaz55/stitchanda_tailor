import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/data/models/verification_status.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import '../base/custom_bottom_nav_bar.dart';
import 'orders_screen.dart';
import 'package:stichanda_tailor/modules/chat/cubit/chat_cubit.dart';
import 'package:stichanda_tailor/modules/chat/screens/chat_screen.dart';

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
        title: const Text('Home Screen', style: TextStyle(color: AppColors.textBlack)),
        backgroundColor: AppColors.caramel,
        automaticallyImplyLeading: false,
        // removed logout action; logout should be in profile screen only
      ),
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, authState) {
            if (authState is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authState.message), backgroundColor: Colors.red),
              );
            }
          },
          child: BlocConsumer<OrderCubit, OrderState>(
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
              final authState = context.watch<AuthCubit>().state;

              // prepare metrics based on order data
              List<OrderDetail> allOrders = [];
              if (state is OrderDetailsSuccess) {
                allOrders = state.orderDetails;
              }

              final activeOrders = allOrders.where((o) => o.status == -1).length;
              final completedOrders = allOrders.where((o) => o.status == 2).length;
              final avgRating = (authState is AuthSuccess) ? authState.tailor.review.toDouble() : 0.0;
              final earnings = allOrders.fold<double>(0.0, (sum, o) => sum + (o.totalPrice));

              if (state is OrderLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with avatar + availability (arranged to match screenshot)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.outline, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage('assets/images/logo2.png'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (authState is AuthSuccess) ? authState.tailor.name : 'Tailor',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.verified, color: Colors.green, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    (authState is AuthSuccess)
                                        ? VerificationStatus.getStatusName(authState.tailor.verification_status)
                                        : 'unverified',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Availability toggle (aligned top-right)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text('Available', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 6),
                            // Show spinner while availability is being updated
                            if (authState is AuthLoading)
                              const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            else
                              Switch(
                                value: (authState is AuthSuccess) ? authState.tailor.availibility_status : true,
                                onChanged: (v) {
                                  context.read<AuthCubit>().updateAvailability(v);
                                },
                                thumbColor: WidgetStateProperty.resolveWith((states) => AppColors.caramel),
                                trackColor: WidgetStateProperty.resolveWith((states) => const Color.fromRGBO(216, 150, 75, 0.3)),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 4 Stats cards implemented as two rows to avoid overflow on small screens
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                // increased height to prevent bottom overflow on tight layouts
                                height: 86,
                                child: _StatCard(title: 'Active Orders', value: activeOrders.toString(), accent: AppColors.beige),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 86,
                                child: _StatCard(title: 'Completed', value: completedOrders.toString(), accent: AppColors.beige),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 86,
                                child: _StatCard(title: 'Avg. Rating', value: avgRating.toStringAsFixed(1), accent: AppColors.beige),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 86,
                                child: _StatCard(title: 'Earnings', value: '${earnings.toStringAsFixed(0)} Pkr', accent: AppColors.beige),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // In-progress Orders (show top 3 nearest to deadline)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'In Progress',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            // Push OrdersScreen (orders tab) so user can navigate back
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OrdersScreen()),
                            );
                          },
                          child: const Text('View All', style: TextStyle(color: AppColors.caramel)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // compute in-progress and nearest-deadline orders
                    Builder(builder: (context) {
                      // Filter in-progress statuses (0,1)
                      final inProgress = allOrders.where((o) => o.status == 0 || o.status == 1).toList();

                      // Sort by dueDate ascending (nulls last)
                      inProgress.sort((a, b) {
                        final aDue = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(8640000000000000);
                        final bDue = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(8640000000000000);
                        return aDue.compareTo(bDue);
                      });

                      // Take top 3 nearest deadlines
                      final visibleOrders = inProgress.take(3).toList();

                      if (visibleOrders.isEmpty) {
                        return Center(
                          child: Column(
                            children: const [
                              SizedBox(height: 20),
                              Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textGrey),
                              SizedBox(height: 12),
                              Text('No In-Progress Orders', style: TextStyle(color: AppColors.textGrey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: visibleOrders.length,
                        itemBuilder: (context, index) {
                          final od = visibleOrders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: OrderDetailCard(orderDetail: od),
                          );
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 2),
    );
  }
}

// Small stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? accent; // used as background color for the card

  const _StatCard({Key? key, required this.title, required this.value, this.accent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = accent ?? AppColors.beige; // card background (beige)
    final actionColor = AppColors.caramel; // icon box color (caramel)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(216, 150, 75, 0.12)),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Title + Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textBlack)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textBlack,
                  ),
                ),
              ],
            ),
          ),

          // Icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: actionColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.bar_chart, color: Colors.white, size: 16),
            ),
          ),
        ],
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

  void _openChat(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again to use chat')),
      );
      return;
    }
    final me = authState.tailor.tailor_id;
    final other = orderDetail.customerId;
    if (other.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer id unavailable for this order')),
      );
      return;
    }
    try {
      final conv = await context.read<ChatCubit>().startConversation(me, other);
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start chat: $e')),
      );
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
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Chat with customer',
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: AppColors.caramel,
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
