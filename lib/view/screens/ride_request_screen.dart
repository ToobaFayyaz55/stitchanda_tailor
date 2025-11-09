import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/controller/ride_cubit.dart';
import 'package:stichanda_tailor/data/models/order_detail_model.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/base/common_widgets.dart';
import 'package:stichanda_tailor/view/base/driver_card_widget.dart';
import 'package:stichanda_tailor/view/screens/ride_status_screen.dart';

/// Ride Request Screen - Shows when tailor completes stitching and needs to request a driver
class RideRequestScreen extends StatefulWidget {
  final OrderDetail orderDetail;
  final VoidCallback onDriverAssigned;

  const RideRequestScreen({
    Key? key,
    required this.orderDetail,
    required this.onDriverAssigned,
  }) : super(key: key);

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  String? _selectedDriverId;

  @override
  void initState() {
    super.initState();
    // Fetch available drivers when screen loads
    _loadDrivers();
  }

  void _loadDrivers() {
    context.read<RideCubit>().fetchAvailableDrivers();
  }

  void _handleAssignDriver() {
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a driver'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Assign selected driver
    context.read<RideCubit>().assignDriver(
      detailsId: widget.orderDetail.detailsId,
      driverId: _selectedDriverId!,
      tailorId: widget.orderDetail.tailorId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Driver'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textBlack,
      ),
      body: BlocListener<RideCubit, RideState>(
        listener: (context, state) {
          if (state is DriverAssigned) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Driver ${state.driver.name} assigned successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            widget.onDriverAssigned();

            // Automatically navigate to ride status screen
            Future.delayed(const Duration(milliseconds: 500), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RideStatusScreen(
                    orderDetail: widget.orderDetail,
                    assignedDriver: state.driver,
                  ),
                ),
              );
            });
          } else if (state is RideError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Order Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Ready for Pickup',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #${widget.orderDetail.orderId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer: ${widget.orderDetail.customerName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Drivers List
            Expanded(
              child: BlocBuilder<RideCubit, RideState>(
                builder: (context, state) {
                  if (state is RideSearching) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.caramel,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Finding Available Drivers...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is RideError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Retry',
                            onPressed: _loadDrivers,
                            icon: Icons.refresh,
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is AvailableDriversLoaded) {
                    final drivers = state.drivers;

                    if (drivers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 48,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Drivers Available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try again later',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              label: 'Refresh',
                              onPressed: _loadDrivers,
                              icon: Icons.refresh,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        final isSelected = _selectedDriverId == driver.driverId;

                        return DriverCard(
                          driver: driver,
                          isSelected: isSelected,
                          onSelect: () {
                            setState(() {
                              _selectedDriverId = driver.driverId;
                            });
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
            final isEnabled = _selectedDriverId != null;

            return PrimaryButton(
              label: 'Assign Driver',
              onPressed: _handleAssignDriver,
              isLoading: isLoading,
              enabled: isEnabled,
              icon: Icons.check_circle_outline,
            );
          },
        ),
      ),
    );
  }
}

