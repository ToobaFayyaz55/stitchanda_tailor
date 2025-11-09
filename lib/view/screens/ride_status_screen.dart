import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/ride_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/data/models/driver_model.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/base/common_widgets.dart';

/// Ride Status Screen - Shows current ride status and driver details
class RideStatusScreen extends StatefulWidget {
  final OrderDetail orderDetail;
  final Driver? assignedDriver;

  const RideStatusScreen({
    Key? key,
    required this.orderDetail,
    this.assignedDriver,
  }) : super(key: key);

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  late Driver? _driver;

  @override
  void initState() {
    super.initState();
    _driver = widget.assignedDriver;

    // If no driver provided but we have driverId, fetch it
    if (_driver == null && widget.orderDetail.detailsId.isNotEmpty) {
      _loadDriverDetails();
    }
  }

  Future<void> _loadDriverDetails() async {
    // This would be called if driverId is available in the order
    // For now, we use the provided driver
  }

  void _handlePickupDone() {
    if (_driver == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: const Text('Has the driver picked up the order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RideCubit>().markPickedFromTailor(
                detailsId: widget.orderDetail.detailsId,
                driverId: _driver!.driverId,
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Status'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textBlack,
      ),
      body: BlocListener<RideCubit, RideState>(
        listener: (context, state) {
          if (state is DriverPickedUp) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pickup marked complete!'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is RideError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Status Timeline
              _buildStatusTimeline(),
              const SizedBox(height: 24),

              // Driver Details Card (if assigned)
              if (_driver != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDriverDetailsCard(),
                ),
                const SizedBox(height: 24),
              ],

              // Order Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildOrderSummary(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.orderDetail.status == 7
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.outline),
                ),
              ),
              child: BlocBuilder<RideCubit, RideState>(
                builder: (context, state) {
                  final isLoading = state is RideLoading;

                  return PrimaryButton(
                    label: 'Confirm Driver Pickup',
                    onPressed: _handlePickupDone,
                    isLoading: isLoading,
                    icon: Icons.done_all,
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildStatusTimeline() {
    final steps = [
      ('Order Completed', widget.orderDetail.status >= 5, Icons.check_circle),
      ('Driver Requested', widget.orderDetail.status >= 6, Icons.phone),
      ('Driver Assigned', widget.orderDetail.status >= 7, Icons.person_add),
      ('Picked Up', widget.orderDetail.status >= 8, Icons.local_shipping),
      ('Delivered', widget.orderDetail.status >= 9, Icons.home),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            steps.length,
            (index) {
              final (label, isComplete, icon) = steps[index];
              final isLast = index == steps.length - 1;
              final isActive = isComplete;

              return Column(
                children: [
                  Row(
                    children: [
                      // Timeline dot
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.caramel
                              : AppColors.outline.withValues(alpha: 0.3),
                        ),
                        child: Icon(
                          icon,
                          color: isActive ? Colors.white : AppColors.textGrey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Label
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? AppColors.textBlack
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                    if (!isLast) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Container(
                          width: 2,
                          height: 12,
                          color: isActive
                              ? AppColors.caramel
                              : AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetailsCard() {
    final driver = _driver!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Assigned',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 12),
          // Driver info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.beige.withValues(alpha: 0.3),
                ),
                child: driver.profileImagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          driver.profileImagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person);
                          },
                        ),
                      )
                    : const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${driver.rating.toStringAsFixed(1)} • ${driver.vehicleType}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contact buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement phone call
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.caramel,
                    side: const BorderSide(color: AppColors.caramel),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement SMS
                  },
                  icon: const Icon(Icons.sms),
                  label: const Text('SMS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.caramel,
                    side: const BorderSide(color: AppColors.caramel),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Order ID', '#${widget.orderDetail.orderId}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Customer', widget.orderDetail.customerName),
          const SizedBox(height: 8),
          _buildSummaryRow('Total Price', 'Rs. ${widget.orderDetail.totalPrice}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Status', RideCubit.getStatusText(widget.orderDetail.status)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
      ],
    );
  }
}

