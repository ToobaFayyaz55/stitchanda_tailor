import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import '../base/custom_bottom_nav_bar.dart';
import 'orders_screen.dart';
import 'order_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        child: Builder(
          builder: (context) {
            final authState = context.watch<AuthCubit>().state;
            if (authState is! AuthSuccess) {
              return const Center(child: Text('Please login'));
            }
            final tailor = authState.tailor;
            // Stream all orders; we'll filter client-side to avoid whereIn >10 limit
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<OrderCubit>().streamOrdersForTailorWithCustomerNames(tailor.tailor_id),
              builder: (context, snapshot) {
                final loading = snapshot.connectionState == ConnectionState.waiting;
                final allOrders = snapshot.data ?? [];

                // Filter only accepted and onward (exclude unaccepted -2 and rejected -3)
                final acceptedOnwardOrders = allOrders.where((o) {
                  final raw = o['status'];
                  final status = raw is int ? raw : int.tryParse(raw.toString()) ?? -999;
                  // Exclude only unaccepted (-2), rejected (-3), and customer confirmed (10)
                  return status != OrderCubit.statusUnaccepted &&
                         status != OrderCubit.statusRejected &&
                         status != OrderCubit.statusCustomerConfirmed; // keep status 8 visible
                }).toList();

                // Sort by delivery date (soonest first)
                acceptedOnwardOrders.sort((a, b) {
                  final aDue = _calculateDaysLeft(a['delivery_date']);
                  final bDue = _calculateDaysLeft(b['delivery_date']);
                  return aDue.compareTo(bDue);
                });

                // Stats based on filtered list
                final activeOrders = acceptedOnwardOrders.where((o) {
                  final raw = o['status'];
                  final status = raw is int ? raw : int.tryParse(raw.toString()) ?? -999;
                  return OrderCubit.inProgressStatuses.contains(status);
                }).length;
                final completedOrders = acceptedOnwardOrders.where((o) {
                  final raw = o['status'];
                  final status = raw is int ? raw : int.tryParse(raw.toString()) ?? -999;
                  return OrderCubit.completedStatuses.contains(status);
                }).length;
                final earnings = acceptedOnwardOrders.fold<double>(0.0, (sum, o) {
                  final price = (o['total_price'] as num?)?.toDouble() ?? 0.0;
                  return sum + price;
                });
                final avgRating = tailor.review.toDouble();

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

                      // Accepted & Ongoing Orders section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Orders',
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
                      if (loading)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                      else if (acceptedOnwardOrders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: const [
                                Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.textGrey),
                                SizedBox(height: 12),
                                Text('No Orders Yet', style: TextStyle(fontSize: 16, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: acceptedOnwardOrders.length > 6 ? 6 : acceptedOnwardOrders.length,
                          itemBuilder: (context, index) {
                            final order = acceptedOnwardOrders[index];
                            return _OrderCard(
                              order: order,
                              daysLeft: _calculateDaysLeft(order['delivery_date']),
                              daysLeftColor: _getDaysLeftColor(_calculateDaysLeft(order['delivery_date'])),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 80), // Space for bottom nav
                    ],
                  ),
                );
              },
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

// Replace _PendingOrderCard with a generalized _OrderCard
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final int daysLeft;
  final Color daysLeftColor;
  final VoidCallback? onTap;
  const _OrderCard({
    required this.order,
    required this.daysLeft,
    required this.daysLeftColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = (order['order_id'] as String?) ?? '';
    final customerName = (order['customer_name'] as String?) ?? 'Customer';
    final totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;

    // Extract locations
    final drop = order['dropoff_location'] as Map<String, dynamic>?; // tailor location per schema
    final pick = order['pickup_location'] as Map<String, dynamic>?;   // customer location per schema
    final dropLat = (drop?['latitude'] as num?)?.toDouble();
    final dropLng = (drop?['longitude'] as num?)?.toDouble();
    final dropAddr = drop?['full_address'] as String? ?? '';
    final pickLat = (pick?['latitude'] as num?)?.toDouble();
    final pickLng = (pick?['longitude'] as num?)?.toDouble();

    // Handle status
    int status = -999;
    final statusValue = order['status'];
    if (statusValue is int) {
      status = statusValue;
    } else if (statusValue is String) {
      status = int.tryParse(statusValue) ?? -999;
    }

    final dueDate = order['delivery_date'];
    final shouldShowDeadline = status != OrderCubit.statusRejected &&
        !OrderCubit.completedStatuses.contains(status);

    // Status-based action flags
    final isDeliveredToTailor = status == OrderCubit.statusCompletedCustomer; // 3
    final isTailorWorking = status == OrderCubit.statusReceivedTailor;        // 4
    final isStitchingDone = status == OrderCubit.statusCompletedTailor;       // 5
    final isSelfDelivery = status == OrderCubit.statusCompletedToCustomer;    // 9 (per current mapping)
    final isCallRider = status == OrderCubit.statusCallRiderTailor;           // 6
    final isRiderAssigned = status == OrderCubit.statusRiderAssignedTailor;   // 7
    final isPickedFromTailor = status == OrderCubit.statusPickedFromTailor;   // 8

    // Show distance/fare for stitching done, rider flow, and self delivery
    final bool showDistanceFare = (isStitchingDone || isCallRider || isRiderAssigned || isSelfDelivery || isPickedFromTailor) &&
        dropLat != null && dropLng != null && pickLat != null && pickLng != null;

    double? km;
    double? fare;
    if (showDistanceFare) {
      km = _haversineKm(dropLat!, dropLng!, pickLat!, pickLng!);
      fare = km * 50.0;
    }

    // Rider details
    final incomingRiderId = order['rider_id'] as String?;
    final returnRiderId = order['drop_off_rider_id'] as String?;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
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
                    _StatusBadge(status: status),
                  ],
                ),

                const SizedBox(height: 14),

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
                          const Icon(Icons.currency_rupee, size: 16, color: AppColors.caramel),
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

                // Distance & Fare block for statuses 5,6,7,9
                if (showDistanceFare) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.caramel.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.route, color: AppColors.caramel, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dropAddr.isNotEmpty ? dropAddr : 'Tailor location',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textBlack),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${km!.toStringAsFixed(1)} km  •  Est. Fare Rs ${fare!.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on, color: AppColors.caramel),
                          tooltip: 'Open route',
                          onPressed: () => _openMaps(dropLat!, dropLng!, pickLat!, pickLng!),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons (status-based)
                if (isDeliveredToTailor || isTailorWorking || isStitchingDone) ...[
                  const SizedBox(height: 14),
                  if (isDeliveredToTailor)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmReceiving(context, orderId),
                        icon: const Icon(Icons.check_box, size: 20),
                        label: const Text('Confirm Receiving'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (isTailorWorking)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _markCompleted(context, orderId),
                        icon: const Icon(Icons.done_all, size: 20),
                        label: const Text('Order Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.caramel,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  if (isStitchingDone) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.read<OrderCubit>().markSelfDelivery(orderId: orderId),
                            icon: const Icon(Icons.directions_walk),
                            label: const Text('Self Delivery'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textBlack,
                              side: BorderSide(color: AppColors.textGrey.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callRider(context, orderId),
                            icon: const Icon(Icons.delivery_dining, size: 20),
                            label: const Text('Book a Ride'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                // Rider detail button for incoming rider (1,2,3)
                if (isDeliveredToTailor || status == OrderCubit.statusRiderAssignedCustomer || status == OrderCubit.statusPickedUpCustomer)
                  if (incomingRiderId != null && incomingRiderId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRiderSheet(context, incomingRiderId, false),
                        icon: const Icon(Icons.directions_bike),
                        label: const Text('Pickup Rider Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.caramel,
                          side: BorderSide(color: AppColors.caramel.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],

                // Rider detail button for return rider (7,8,9)
                if (status == OrderCubit.statusRiderAssignedTailor || status == OrderCubit.statusPickedFromTailor || status == OrderCubit.statusCompletedToCustomer)
                  if (returnRiderId != null && returnRiderId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRiderSheet(context, returnRiderId, true),
                        icon: const Icon(Icons.delivery_dining),
                        label: const Text('Return Rider Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Action handlers
  void _confirmReceiving(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Material Receipt'),
        content: const Text('Have you received the materials for this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<OrderCubit>().confirmMaterialReceived(orderId: orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material receipt confirmed'), backgroundColor: Colors.green));
      }
    }
  }

  void _markCompleted(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Order Completed'),
        content: const Text('Have you finished stitching this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramel),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<OrderCubit>().markOrderCompleted(orderId: orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked completed'), backgroundColor: Colors.green));
      }
    }
  }

  void _callRider(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Call Rider for Pickup'),
        content: const Text('Send rider request for this completed order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Call Rider'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<OrderCubit>().callRider(orderId: orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rider request sent'), backgroundColor: Colors.blue));
      }
    }
  }

  Future<void> _showRiderSheet(BuildContext context, String riderId, bool isReturn) async {
    final snap = await FirebaseFirestore.instance.collection('driver').doc(riderId).get();
    final data = snap.data();
    if (data == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rider not found')));
      }
      return;
    }
    final name = data['name']?.toString() ?? 'Rider';
    final phone = data['phone']?.toString() ?? '';
    final image = data['profile_image_path']?.toString() ?? '';
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              Text(isReturn ? 'Return Ride Details' : 'Pickup Rider Details', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                backgroundColor: AppColors.beige,
                child: image.isEmpty ? const Icon(Icons.person, size: 42, color: AppColors.deepBrown) : null,
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textBlack)),
              const SizedBox(height: 6),
              Text(isReturn ? 'Return Rider' : 'Pickup Rider', style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Estimated Arrival', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                          SizedBox(height: 4),
                          Text('1 min', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 42, color: Colors.orange.shade200),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Distance', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                        SizedBox(height: 4),
                        Text('0.0 km', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final me = FirebaseAuth.instance.currentUser?.uid;
                        if (me == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
                          return;
                        }
                        try {
                          final conv = await context.read<ChatCubit>().startConversation(me, riderId);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat error: $e')));
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot launch dialer')));
                        }
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Open maps with Google Maps query
  Future<void> _openMaps(double startLat, double startLng, double endLat, double endLng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Haversine distance in km
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);
}

class _StatusBadge extends StatelessWidget {
  final int status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = OrderCubit.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        OrderCubit.getStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DeadlineIndicator extends StatelessWidget {
  final int daysLeft;
  final bool hasDate;
  const _DeadlineIndicator({required this.daysLeft, required this.hasDate});

  @override
  Widget build(BuildContext context) {
    if (!hasDate) return const SizedBox.shrink();

    final isUrgent = daysLeft <= 3 && daysLeft >= 0;
    final isOverdue = daysLeft < 0;

    Color bgColor;
    Color textColor;
    IconData icon;

    if (isOverdue) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.error_outline;
    } else if (isUrgent) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            isOverdue ? 'Overdue' : '${daysLeft.abs()} ${daysLeft == 1 ? 'day' : 'days'} left',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }
}
