import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stichanda_tailor/modules/chat/cubit/chat_cubit.dart';
import 'package:stichanda_tailor/modules/chat/screens/chat_screen.dart';
import '../base/custom_bottom_nav_bar.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'allorders'; // allorders | pending | inprogress | completed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Delay fetch until after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchOrders() {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthSuccess) {
      switch (_selectedFilter) {
        case 'allorders':
          context.read<OrderCubit>().fetchOrdersForTailorWithCustomerNames(auth.tailor.tailor_id);
          break;
        case 'pending':
          context.read<OrderCubit>().fetchOrdersForTailorWithCustomerNames(
            auth.tailor.tailor_id,
            statuses: [OrderCubit.statusUnaccepted]
          );
          break;
        case 'inprogress':
          context.read<OrderCubit>().fetchOrdersForTailorWithCustomerNames(
            auth.tailor.tailor_id,
            statuses: OrderCubit.inProgressStatuses
          );
          break;
        case 'completed':
          context.read<OrderCubit>().fetchOrdersForTailorWithCustomerNames(
            auth.tailor.tailor_id,
            statuses: OrderCubit.completedStatuses
          );
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Filter Chips
          _FilterBar(
            selected: _selectedFilter,
            onChanged: (v) {
              setState(() => _selectedFilter = v);
              _fetchOrders();
            },
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _buildOrdersStream(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allOrders = snapshot.data ?? [];

                // Filter by search query
                final orders = _searchQuery.isEmpty
                    ? allOrders
                    : allOrders.where((order) {
                        final orderId = (order['order_id'] as String? ?? '').toLowerCase();
                        final customerName = (order['customer_name'] as String? ?? '').toLowerCase();
                        return orderId.contains(_searchQuery) || customerName.contains(_searchQuery);
                      }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Total: ${orders.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),

                    // Orders List or Empty State
                    Expanded(
                      child: orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textGrey),
                                  const SizedBox(height: 16),
                                  Text('No orders', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Change filter or wait for updates'
                                        : 'No orders match your search',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: orders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _OrderCard(
                                order: orders[i],
                                isPending: _selectedFilter == 'pending',
                                onAccept: () => _handleAccept(orders[i]),
                                onReject: () => _handleReject(orders[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 3),
    );
  }

  void _handleAccept(Map<String, dynamic> order) async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthSuccess) return;

    final orderId = order['order_id'] as String;
    await context.read<OrderCubit>().acceptOrderById(
      orderId: orderId,
      tailorId: auth.tailor.tailor_id,
    );

    // Refresh the list
    _fetchOrders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted successfully')),
      );
    }
  }

  void _handleReject(Map<String, dynamic> order) async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthSuccess) return;

    final orderId = order['order_id'] as String;
    await context.read<OrderCubit>().rejectOrderById(
      orderId: orderId,
      tailorId: auth.tailor.tailor_id,
    );

    // Refresh the list
    _fetchOrders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order rejected')),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> _buildOrdersStream(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthSuccess) return const Stream.empty();

    switch (_selectedFilter) {
      case 'pending':
        return context.read<OrderCubit>().streamOrdersForTailorWithCustomerNames(
          auth.tailor.tailor_id,
          statuses: [OrderCubit.statusUnaccepted]
        );
      case 'inprogress':
        return context.read<OrderCubit>().streamOrdersForTailorWithCustomerNames(
          auth.tailor.tailor_id,
          statuses: OrderCubit.inProgressStatuses
        );
      case 'completed':
        return context.read<OrderCubit>().streamOrdersForTailorWithCustomerNames(
          auth.tailor.tailor_id,
          statuses: OrderCubit.completedStatuses
        );
      default:
        return context.read<OrderCubit>().streamOrdersForTailorWithCustomerNames(auth.tailor.tailor_id);
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
        runSpacing: 8,
        children: [
          _chip('All Orders'),
          _chip('Pending'),
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
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSel ? AppColors.caramel : AppColors.textGrey.withValues(alpha: 0.3),
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSel ? Colors.white : AppColors.textBlack,
        fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isPending;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _OrderCard({
    required this.order,
    this.isPending = false,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = (order['order_id'] as String?) ?? '';
    final totalPrice = (order['total_price'] as num?)?.toDouble() ?? 0.0;

    // Handle status - it might come as int or String from Firebase
    int status = -999;
    final statusValue = order['status'];
    if (statusValue is int) {
      status = statusValue;
    } else if (statusValue is String) {
      status = int.tryParse(statusValue) ?? -999;
    }

    // Due date is now enriched from order_details collection (earliest due_data)
    final dueDate = order['delivery_date'];

    // Customer name is now provided by the repository/controller enrichment
    final customerName = (order['customer_name'] as String?) ?? 'Customer';

    // Calculate days left
    final daysLeft = _calculateDaysLeft(dueDate);

    // Only show deadline for pending and in-progress orders, not for rejected or completed
    final shouldShowDeadline = status != OrderCubit.statusRejected &&
                               !OrderCubit.completedStatuses.contains(status);

    // Check if order is delivered to tailor (status 3 - needs confirmation)
    final isDeliveredToTailor = status == OrderCubit.statusCompletedCustomer;

    // Check if tailor is working on order (status 4 - can mark as completed)
    final isTailorWorking = status == OrderCubit.statusReceivedTailor;

    // Check if stitching is done (status 5 - can call rider)
    final isStitchingDone = status == OrderCubit.statusCompletedTailor;
    // Rider related statuses
    final isIncomingRider = status == OrderCubit.statusRiderAssignedCustomer || status == OrderCubit.statusPickedUpCustomer || status == OrderCubit.statusCompletedCustomer; // 1,2,3
    final isReturnRiderFlow = status == OrderCubit.statusRiderAssignedTailor || status == OrderCubit.statusPickedFromTailor || status == OrderCubit.statusCompletedToCustomer; // 7,8,9
    final incomingRiderId = order['rider_id'] as String?; // customer side rider
    final returnRiderId = order['drop_off_rider_id'] as String?; // tailor side rider id field per requirement

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        ),
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
                    // Deadline Indicator (only for active orders, not rejected/completed)
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

                    // Price moved to bottom right
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

                // Accept/Reject Buttons (only for pending orders)
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAccept,
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
                          onPressed: onReject,
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

                // Confirm Receiving Button (for status 3 - delivered to tailor)
                if (isDeliveredToTailor) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleConfirmReceiving(context, orderId),
                      icon: const Icon(Icons.check_box, size: 20),
                      label: const Text('Confirm Receiving'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],

                // Order Completed Button (for status 4 - tailor working on order)
                if (isTailorWorking) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleOrderCompleted(context, orderId),
                      icon: const Icon(Icons.done_all, size: 20),
                      label: const Text('Order Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caramel,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],

                // Call Rider Button (for status 5 - stitching done, ready for pickup)
                if (isStitchingDone) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCallRider(context, orderId),
                      icon: const Icon(Icons.delivery_dining, size: 20),
                      label: const Text('Call Rider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],

                // Rider Details Button (incoming rider 1,2,3)
                if (isIncomingRider && incomingRiderId != null && incomingRiderId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRiderDetails(context, incomingRiderId, false),
                      icon: const Icon(Icons.directions_bike),
                      label: const Text('Incoming Rider Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.caramel.withValues(alpha: 0.4)),
                        foregroundColor: AppColors.caramel,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],

                // Rider Details Button (return rider 7,8,9)
                if (isReturnRiderFlow && returnRiderId != null && returnRiderId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRiderDetails(context, returnRiderId, true),
                      icon: const Icon(Icons.delivery_dining),
                      label: const Text('Return Rider Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.blue.withValues(alpha: 0.4)),
                        foregroundColor: Colors.blue,
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

  int _calculateDaysLeft(dynamic date) {
    if (date == null) return 0;
    DateTime? dt;
    if (date is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(date);
    } else if (date is String) {
      dt = DateTime.tryParse(date);
    } else if (date.runtimeType.toString().contains('Timestamp')) {
      dt = (date as dynamic).toDate();
    }
    if (dt == null) return 0;

    final now = DateTime.now();
    final difference = dt.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  static void _handleConfirmReceiving(BuildContext context, String orderId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Material Receipt'),
        content: const Text('Have you received the materials for this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material receipt confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  static void _handleOrderCompleted(BuildContext context, String orderId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Order as Completed'),
        content: const Text('Have you finished stitching this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  static void _handleCallRider(BuildContext context, String orderId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Call Rider for Pickup'),
        content: const Text('Do you want to request a rider to pick up this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider request sent successfully!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showRiderDetails(BuildContext context, String riderId, bool isReturn) async {
    final doc = await FirebaseFirestore.instance.collection('driver').doc(riderId).get();
    final data = doc.data();
    if (data == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rider details not found')));
      }
      return;
    }
    final name = data['name'] ?? 'Rider';
    final phone = data['phone'] ?? '';
    final image = data['profile_image_path'] ?? '';
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 16),
              Text(isReturn ? 'Return Ride Details' : 'Pickup Rider Details', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundImage: image.toString().isNotEmpty ? NetworkImage(image) : null,
                backgroundColor: AppColors.beige,
                child: image.toString().isEmpty ? const Icon(Icons.person, size: 42, color: AppColors.deepBrown) : null,
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
                    Container(
                      width: 1,
                      height: 42,
                      color: Colors.orange.shade200,
                    ),
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat error: $e')));
                          }
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
                      label: Text(phone.isEmpty ? 'Call' : phone),
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
}

class _StatusBadge extends StatelessWidget {
  final int status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: OrderCubit.getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        OrderCubit.getStatusLabel(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DeadlineIndicator extends StatelessWidget {
  final int daysLeft;
  final bool hasDate;

  const _DeadlineIndicator({
    required this.daysLeft,
    required this.hasDate,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasDate) {
      // Show "No deadline" when date is not available
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'No deadline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

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
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            isOverdue
                ? 'Overdue'
                : '${daysLeft.abs()} ${daysLeft == 1 ? 'day' : 'days'} left',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
