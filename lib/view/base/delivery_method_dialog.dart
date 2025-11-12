import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/ride_cubit.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/screens/ride_request_screen.dart';
import 'package:stichanda_tailor/view/screens/ride_status_screen.dart';

/// Delivery Method Selection Dialog
/// Shown after tailor marks order as completed (status 5)
/// Allows tailor to choose between booking a ride or customer self-pickup
class DeliveryMethodDialog extends StatefulWidget {
  final OrderDetail orderDetail;
  final String tailorId;
  final VoidCallback onDismiss;

  const DeliveryMethodDialog({
    Key? key,
    required this.orderDetail,
    required this.tailorId,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<DeliveryMethodDialog> createState() => _DeliveryMethodDialogState();
}

class _DeliveryMethodDialogState extends State<DeliveryMethodDialog> {
  bool _isLoadingRide = false;
  bool _isLoadingCustomerPickup = false;

  void _handleBookRide() async {
    setState(() => _isLoadingRide = true);

    try {
      // Step 1: Request driver (status 5 → 6)
      await context.read<RideCubit>().requestDriver(
        detailsId: widget.orderDetail.detailsId,
        tailorId: widget.tailorId,
      );

      // Close dialog
      if (mounted) Navigator.pop(context);

      // Step 2: Navigate to driver selection screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideRequestScreen(
              orderDetail: widget.orderDetail,
              onDriverAssigned: () {
                // After driver assigned, navigate to ride status screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RideStatusScreen(
                      orderDetail: widget.orderDetail,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRide = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleCustomerPickup() async {
    setState(() => _isLoadingCustomerPickup = true);

    try {
      // Mark order as customer self-pickup (status 5 → 11)
      // await context.read<OrderCubit>().tailorSelfDeliver(
      //   detailsId: widget.orderDetail.detailsId,
      //   tailorId: widget.tailorId,
      // );

      // Close dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked - Customer will pick up'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onDismiss();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCustomerPickup = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Delivery Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How would you like to deliver this order?',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Book a Ride
            _buildOptionButton(
              title: 'Book a Ride',
              description: 'Request a driver to pickup and deliver',
              icon: Icons.two_wheeler,
              color: AppColors.caramel,
              isLoading: _isLoadingRide,
              onPressed: _isLoadingCustomerPickup ? null : _handleBookRide,
            ),
            const SizedBox(height: 16),

            // Option 2: Customer Will Pick
            _buildOptionButton(
              title: 'Customer Will Pick',
              description: 'Customer will pickup the order themselves',
              icon: Icons.store,
              color: AppColors.deepBrown,
              isLoading: _isLoadingCustomerPickup,
              onPressed: _isLoadingRide ? null : _handleCustomerPickup,
            ),
            const SizedBox(height: 24),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoadingRide || _isLoadingCustomerPickup
                    ? null
                    : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textGrey,
                  side: const BorderSide(color: AppColors.outline),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                  ),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLoading ? Icons.hourglass_empty : Icons.arrow_forward_ios,
                  size: 16,
                  color: isLoading ? AppColors.textGrey : color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show delivery method dialog
void showDeliveryMethodDialog({
  required BuildContext context,
  required OrderDetail orderDetail,
  required String tailorId,
  required VoidCallback onDismiss,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => DeliveryMethodDialog(
      orderDetail: orderDetail,
      tailorId: tailorId,
      onDismiss: onDismiss,
    ),
  );
}

