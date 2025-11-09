# 🚗 Complete Delivery Flow - Integration Guide

## Overview
When a tailor marks an order as complete (status 5), they see a dialog with two delivery options:
1. **Book a Ride** - Full automated ride booking workflow
2. **Customer Will Pick** - Customer picks up the order (status 11)

---

## 📊 Complete Flow Diagram

```
Tailor views order (status 4)
    ↓
Tailor clicks "Mark as Completed" button
    ↓
OrderCubit.tailorMarkCompleted() executes
    ↓
Status changes: 4 → 5
    ↓
Delivery Method Dialog appears
    ├─────────────────────────────┬─────────────────────────────┐
    │                             │                             │
    ↓                             ↓
[Book a Ride]             [Customer Will Pick]
    ↓                             ↓
RideCubit.requestDriver()    OrderCubit.tailorSelfDeliver()
    ↓                             ↓
Status: 5 → 6              Status: 5 → 11
    ↓                             ↓
RideRequestScreen          Dialog closes
(Driver selection)          Success message shown
    ↓
Tailor selects driver
    ↓
RideCubit.assignDriver()
    ↓
Status: 6 → 7
    ↓
RideStatusScreen appears
(Shows timeline + driver details)
    ↓
"Confirm Driver Pickup" button
    ↓
RideCubit.markPickedFromTailor()
    ↓
Status: 7 → 8
    ↓
Delivery complete (Status 9)
```

---

## 🔧 Implementation in Order Details Screen

### Where to Show the Dialog

When the tailor marks an order as complete, you need to trigger the delivery method dialog. Here's how to integrate it:

```dart
// In your Order Details Screen or Order Item Widget

class OrderDetailScreen extends StatelessWidget {
  final OrderDetail order;
  final String tailorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, state) {
          // When order is successfully updated to status 5
          if (state is OrderUpdated && state.orderDetail.status == 5) {
            // Show the delivery method dialog
            Future.delayed(const Duration(milliseconds: 300), () {
              showDeliveryMethodDialog(
                context: context,
                orderDetail: state.orderDetail,
                tailorId: tailorId,
                onDismiss: () {
                  // Optional: Refresh orders list or navigate back
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order updated')),
                  );
                },
              );
            });
          }
        },
        child: // ... rest of UI
      ),
    );
  }
}
```

### Mark as Completed Button

```dart
// In your order item or detail screen

ElevatedButton(
  onPressed: () {
    context.read<OrderCubit>().tailorMarkCompleted(
      detailsId: order.detailsId,
      tailorId: tailorId,
    );
  },
  child: const Text('Mark as Completed'),
)
```

---

## 📱 Import the Dialog

Add this import to your screen:

```dart
import 'package:stichanda_tailor/view/base/delivery_method_dialog.dart';
```

---

## 🎯 Option 1: Book a Ride - Complete Workflow

When tailor clicks **"Book a Ride"**:

### Step 1: Request Driver (Status 5 → 6)
```dart
await rideCubit.requestDriver(
  detailsId: orderDetail.detailsId,
  tailorId: tailorId,
);
```
- Firestore updated with `driver_request_at` timestamp
- Status changes to 6

### Step 2: Show Driver Selection Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RideRequestScreen(
      orderDetail: orderDetail,
      onDriverAssigned: () { /* callback */ },
    ),
  ),
);
```
- RideRequestScreen fetches available drivers from Firestore
- Displays driver list sorted by rating
- Tailor selects a driver

### Step 3: Assign Driver (Status 6 → 7)
```dart
await rideCubit.assignDriver(
  detailsId: orderDetail.detailsId,
  driverId: selectedDriver.driverId,
  tailorId: tailorId,
);
```
- Firestore updated with `driver_id` and `driver_assigned_at`
- Status changes to 7

### Step 4: Show Ride Status Screen
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => RideStatusScreen(
      orderDetail: orderDetail,
      assignedDriver: driver,
    ),
  ),
);
```
- Shows timeline with current progress
- Displays driver details and contact options
- Shows "Confirm Driver Pickup" button

### Step 5: Confirm Pickup (Status 7 → 8)
```dart
await rideCubit.markPickedFromTailor(
  detailsId: orderDetail.detailsId,
  driverId: driver.driverId,
);
```
- Firestore updated with `picked_from_tailor_at`
- Status changes to 8

### Step 6: Delivery Complete (Status 8 → 9)
- System or driver marks delivery complete
- Status changes to 9
- Order fully delivered

---

## 🏪 Option 2: Customer Will Pick - Direct Flow

When tailor clicks **"Customer Will Pick"**:

```dart
await orderCubit.tailorSelfDeliver(
  detailsId: orderDetail.detailsId,
  tailorId: tailorId,
);
```

### What Happens:
- Status changes directly: 5 → 11
- Firestore fields updated:
  - `delivered_by: "tailor"`
  - `delivered_at: serverTimestamp()`
- Dialog closes
- Success message shown
- Order marked complete

---

## 🎨 UI Components Used

### DeliveryMethodDialog
- Shows when status transitions to 5
- Two option buttons: "Book a Ride" and "Customer Will Pick"
- Loading states with spinners
- Cancel button

### RideRequestScreen
- Header with order info
- Driver list with selection
- Assigns driver when selected
- Auto-navigates to RideStatusScreen

### RideStatusScreen
- Timeline showing order progress (5 stages)
- Driver details card with contact buttons
- Order summary
- "Confirm Driver Pickup" button

---

## 📋 Firestore Updates Timeline

```javascript
// Initial state (Status 5)
{
  status: 5,
  tailor_completed: true,
  completed_at: timestamp
}

// After "Book a Ride" clicked (Status 6)
{
  status: 6,
  driver_request_at: timestamp
}

// After driver assigned (Status 7)
{
  status: 7,
  driver_id: "driver_uid",
  driver_assigned_at: timestamp
}

// After pickup confirmed (Status 8)
{
  status: 8,
  picked_from_tailor_at: timestamp
}

// Final delivery (Status 9)
{
  status: 9,
  delivered_at: timestamp
}

// OR if customer pickup (Status 11)
{
  status: 11,
  delivered_by: "tailor",
  delivered_at: timestamp
}
```

---

## ✅ Testing Checklist

- [ ] "Mark as Completed" button triggers dialog
- [ ] Dialog shows with two options
- [ ] "Book a Ride" starts ride workflow
- [ ] Driver list loads and displays correctly
- [ ] Driver selection assigns rider
- [ ] Auto-navigates to RideStatusScreen
- [ ] Timeline shows correct progress
- [ ] "Confirm Driver Pickup" works
- [ ] "Customer Will Pick" sets status to 11
- [ ] All Firestore updates are correct
- [ ] Error messages show properly
- [ ] Loading states display correctly

---

## 🚀 Quick Start

1. **Import dialog in your screen:**
   ```dart
   import 'package:stichanda_tailor/view/base/delivery_method_dialog.dart';
   ```

2. **Listen to OrderCubit state:**
   ```dart
   if (state is OrderUpdated && state.orderDetail.status == 5) {
     showDeliveryMethodDialog(...);
   }
   ```

3. **Pass required parameters:**
   ```dart
   showDeliveryMethodDialog(
     context: context,
     orderDetail: orderDetail,
     tailorId: tailorId,
     onDismiss: () { /* handle completion */ },
   );
   ```

---

## 📞 Support

All components are error-handled:
- Network failures show user-friendly messages
- Invalid status transitions are prevented
- Loading states prevent double-taps
- All async operations have try-catch

---

## 🔑 Key Takeaway

**The entire delivery workflow is now automated:**
1. Tailor marks order as complete → Dialog appears
2. Chooses option → Automatic process begins
3. Guided through driver selection or customer pickup
4. Real-time Firestore updates
5. No manual status management needed

✅ **All integrated and ready to use!**

