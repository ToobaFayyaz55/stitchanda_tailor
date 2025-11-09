# Ride Booking Feature - Integration Guide

## Overview
This document outlines how to integrate the Ride Booking feature into existing screens and workflows.

## Files Created

### Models
- `lib/data/models/driver_model.dart` - Driver data model

### Repository
- `lib/data/repository/ride_repo.dart` - Ride booking and driver management logic

### Business Logic (Cubit)
- `lib/controller/ride_cubit.dart` - RideCubit with states and methods

### UI Components
- `lib/view/base/common_widgets.dart` - Reusable widgets (buttons, badges, loaders)
- `lib/view/base/driver_card_widget.dart` - Driver card and list tile widgets
- `lib/view/base/delivery_options_modal.dart` - Delivery options modal

### Screens
- `lib/view/screens/ride_request_screen.dart` - Driver selection screen (status 6 → 7)
- `lib/view/screens/ride_status_screen.dart` - Ride status and tracking (status 7+)

## Integration Steps

### 1. Update main.dart ✅ (DONE)
RideCubit is now registered in MultiBlocProvider.

### 2. Add Route Navigation
Update your navigation/routing to include new screens:

```dart
// In your route navigation setup:
'/rideRequest': (context) => RideRequestScreen(
  orderDetail: args as OrderDetail,
  onDriverAssigned: () {
    // Callback when driver assigned
  },
),
'/rideStatus': (context) => RideStatusScreen(
  orderDetail: args as OrderDetail,
  assignedDriver: context.read<RideCubit>().state is DriverAssigned
      ? (context.read<RideCubit>().state as DriverAssigned).driver
      : null,
),
```

### 3. Update Order Detail Screen
Show action buttons based on order status:

```dart
// In order details or order item tile:

if (order.status == 5) {
  // Show "Call Driver" button
  PrimaryButton(
    label: 'Call Driver',
    onPressed: () {
      showDeliveryOptions(
        context: context,
        orderDetail: order,
      );
    },
    icon: Icons.phone,
  );
} else if (order.status == 6) {
  // Show "Searching for Drivers"
  StatusBadge(
    label: 'Searching for Drivers',
    backgroundColor: Colors.blue,
    textColor: Colors.blue,
    icon: Icons.search,
  );
} else if (order.status == 7) {
  // Show "Waiting for Pickup"
  StatusBadge(
    label: 'Waiting for Driver Pickup',
    backgroundColor: AppColors.caramel,
    textColor: AppColors.caramel,
    icon: Icons.schedule,
  );
} else if (order.status == 8) {
  StatusBadge(
    label: 'Driver Picked Up',
    backgroundColor: AppColors.success,
    textColor: AppColors.success,
    icon: Icons.check_circle,
  );
} else if (order.status == 9) {
  StatusBadge(
    label: 'Delivered',
    backgroundColor: AppColors.success,
    textColor: AppColors.success,
    icon: Icons.check_circle,
  );
}
```

### 4. Integrate Delivery Options Modal
Show when order is marked as completed:

```dart
import 'package:stichanda_tailor/view/base/delivery_options_modal.dart';

// When tailor marks order as completed (status 5):
void _handleOrderCompleted(OrderDetail order) {
  // First mark as completed in DB
  context.read<OrderCubit>().tailorMarkCompleted(
    detailsId: order.detailsId,
    tailorId: tailorId,
  );

  // Then show delivery options modal
  Future.delayed(const Duration(milliseconds: 500), () {
    showDeliveryOptions(
      context: context,
      orderDetail: order,
    );
  });
}
```

## Order Status Flow

```
Status 3 (Sent to Tailor)
    ↓
Status 4 (Received by Tailor) - "Receive Order" button
    ↓
Status 5 (Completed by Tailor) - "Mark as Completed" button
    ↓
    ├─→ "Call Driver" → Status 6 (Driver Requested)
    │       ↓
    │   Driver Selection Screen
    │       ↓
    │   Status 7 (Driver Assigned)
    │       ↓
    │   "Waiting for Pickup" status
    │       ↓
    │   Status 8 (Picked Up)
    │       ↓
    │   Status 9 (Delivered)
    │
    └─→ "Self Delivery" → Status 11 (Self Delivered)
```

## Key Components Usage

### 1. PrimaryButton
```dart
PrimaryButton(
  label: 'Assign Driver',
  onPressed: () { /* action */ },
  isLoading: false,
  enabled: true,
  icon: Icons.check_circle,
)
```

### 2. DriverCard
```dart
DriverCard(
  driver: driver,
  isSelected: isSelected,
  onSelect: () { /* select logic */ },
  isLoading: isLoading,
)
```

### 3. StatusBadge
```dart
StatusBadge(
  label: 'Searching for Drivers',
  backgroundColor: Colors.blue,
  textColor: Colors.blue,
  icon: Icons.search,
)
```

### 4. DeliveryOptionsModal
```dart
showDeliveryOptions(
  context: context,
  orderDetail: orderDetail,
);
```

## State Management Flow

### RideCubit States
- `RideInitial` - Initial state
- `RideLoading` - Loading drivers or processing action
- `RideSearching` - Searching for available drivers
- `AvailableDriversLoaded` - List of drivers loaded
- `RideRequested` - Driver request sent (status 6)
- `DriverAssigned` - Driver assigned (status 7)
- `DriverPickedUp` - Driver picked up order (status 8)
- `RideCompleted` - Order delivered (status 9)
- `RideError` - Error occurred

### BlocListener Integration
```dart
BlocListener<RideCubit, RideState>(
  listener: (context, state) {
    if (state is DriverAssigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver ${state.driver.name} assigned!')),
      );
      // Navigate or update UI
    } else if (state is RideError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: YourWidget(),
)
```

## Firebase Collections & Fields

### orderDetail document fields (updated)
```
status: 6 (driver requested)
driver_request_at: timestamp
---
status: 7 (driver assigned)
driver_id: "driver_uid"
driver_assigned_at: timestamp
---
status: 8 (picked up)
picked_from_tailor_at: timestamp
---
status: 9 (delivered)
delivered_at: timestamp
```

### drivers collection fields
```
driver_id: string
name: string
phone: string
email: string
rating: number
profile_image_path: string (URL)
vehicle_type: string (motorcycle, car, van)
availability: boolean
address: object {latitude, longitude}
created_at: timestamp
updated_at: timestamp
```

## Helper Methods

### RideCubit Static Methods
```dart
// Get status text for UI
String text = RideCubit.getStatusText(7); // "Driver Assigned - Waiting for Pickup"

// Check if tailor can request driver
bool canRequest = RideCubit.canRequestDriver(5); // true if status == 5

// Check if tailor can assign driver
bool canAssign = RideCubit.canAssignDriver(6); // true if status == 6
```

## Testing Checklist

- [ ] Tailor can request a driver (status 5 → 6)
- [ ] Available drivers are fetched from Firebase
- [ ] Tailor can select and assign a driver
- [ ] Driver assignment updates Firebase (status 6 → 7, sets driver_id)
- [ ] Ride status screen shows correct status and driver info
- [ ] Tailor can confirm driver pickup (status 7 → 8)
- [ ] Self-delivery option works (status 5 → 11)
- [ ] All error states show user-friendly messages
- [ ] Loading states display properly
- [ ] Status badges update based on order status

## Common Integration Points

### Order Details Screen
Add call driver button when status == 5

### Orders List Screen
Show status badges for different ride statuses

### Home/Dashboard Screen
Show in-progress rides with driver info

### Notifications
Listen to Firestore changes for real-time updates

```dart
// Example: Listen to order status changes
context.read<RideCubit>().watchOrderStatus(detailsId);
```

## Notes
- All timestamps use Firebase Firestore server timestamps
- Driver ratings are 0-5 stars
- Vehicle types: motorcycle, car, van, truck, etc.
- Profile images are stored as URLs in Firestore
- All transitions are validated at the repository level

