import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/ride_cubit.dart';
import 'package:stichanda_tailor/controller/order_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/theme/theme.dart';

/// Delivery Options Modal - shown when order is completed by tailor
class DeliveryOptionsModal extends StatelessWidget {
  final OrderDetail orderDetail;
  final VoidCallback onDismiss;

  const DeliveryOptionsModal({
    Key? key,
    required this.orderDetail,
    required this.onDismiss,
  }) : super(key: key);

  void _handleCallDriver(BuildContext context) {
    // Request driver first
    context.read<RideCubit>().requestDriver(
      detailsId: orderDetail.detailsId,
      tailorId: orderDetail.tailorId,
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.caramel,
          ),
        ),
      ),
    );

    // Wait a moment then navigate to driver selection
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context); // Close loading dialog
      Navigator.pushNamed(
        context,
        '/rideRequest',
        arguments: orderDetail,
      );
      onDismiss();
    });
  }

  // void _handleSelfDelivery(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Self Delivery'),
  //       content: const Text('Are you sure you want to deliver this order yourself?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             context.read<OrderCubit>().tailorSelfDeliver(
  //               detailsId: orderDetail.detailsId,
  //               tailorId: orderDetail.tailorId,
  //             );
  //             onDismiss();
  //           },
  //           child: const Text('Confirm'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBlack,
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to deliver the completed order',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Call Driver
            _buildOptionCard(
              title: 'Call a Driver',
              description: 'Request a rider to pick up and deliver the order',
              icon: Icons.two_wheeler,
              color: AppColors.caramel,
              onTap: () => _handleCallDriver(context),
            ),
            const SizedBox(height: 16),

            // Option 2: Self Delivery
            // _buildOptionCard(
            //   title: 'Deliver Myself',
            //   description: 'I will deliver this order to the customer',
            //   icon: Icons.local_shipping,
            //   color: AppColors.deepBrown,
            //   onTap: () => _handleSelfDelivery(context),
            // ),
            // const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.beige.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.beige.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.deepBrown,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Order will be marked as completed once the customer receives it.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.deepBrown.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
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
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show delivery options modal
void showDeliveryOptions({
  required BuildContext context,
  required OrderDetail orderDetail,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => DeliveryOptionsModal(
      orderDetail: orderDetail,
      onDismiss: () => Navigator.pop(context),
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

