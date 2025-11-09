# 🚀 QUICK START - Delivery Flow Integration

## ⚡ In 3 Steps

### Step 1: Import Dialog
```dart
import 'package:stichanda_tailor/view/base/delivery_method_dialog.dart';
```

### Step 2: Listen to OrderCubit
Add this in your Order Detail/Item widget:
```dart
BlocListener<OrderCubit, OrderState>(
  listener: (context, state) {
    if (state is OrderUpdated && state.orderDetail.status == 5) {
      Future.delayed(const Duration(milliseconds: 300), () {
        showDeliveryMethodDialog(
          context: context,
          orderDetail: state.orderDetail,
          tailorId: tailorId,
          onDismiss: () { /* refresh */ },
        );
      });
    }
  },
  child: YourOrderWidget(),
)
```

### Step 3: Add Mark Completed Button
```dart
if (order.status == 4) {
  PrimaryButton(
    label: 'Mark as Completed',
    onPressed: () {
      context.read<OrderCubit>().tailorMarkCompleted(
        detailsId: order.detailsId,
        tailorId: tailorId,
      );
    },
  );
}
```

## ✅ That's It!

The entire delivery workflow is now automated:
1. User clicks "Mark as Completed"
2. Dialog appears with two options
3. User chooses delivery method
4. Everything else happens automatically

---

## 📊 What Happens Automatically

### Option 1: "Book a Ride"
- [x] Request driver (status 5→6)
- [x] Fetch drivers from Firestore
- [x] Show driver selection screen
- [x] Assign selected driver (status 6→7)
- [x] Navigate to ride status
- [x] Show timeline and driver details
- [x] Confirm pickup (status 7→8)
- [x] Mark delivered (status 8→9)

### Option 2: "Customer Will Pick"
- [x] Mark order (status 5→11)
- [x] Close dialog
- [x] Show success message

---

## 🎯 Files You Need to Know

1. **`delivery_method_dialog.dart`** - The dialog component
2. **`ride_request_screen.dart`** - Driver selection
3. **`ride_status_screen.dart`** - Ride tracking
4. **`EXAMPLE_ORDER_ITEM_INTEGRATION.dart`** - See how to integrate

---

## 🔍 Key Status Codes

| Status | Meaning |
|--------|---------|
| 4 | Received by tailor |
| 5 | Completed by tailor ← **Dialog shows here** |
| 6 | Driver requested |
| 7 | Driver assigned |
| 8 | Picked up |
| 9 | Delivered |
| 11 | Self-delivered (customer pickup) |

---

## 💡 Example: Complete Order Item Widget

```dart
class OrderItemWidget extends StatelessWidget {
  final OrderDetail order;
  final String tailorId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderCubit, OrderState>(
      listener: (context, state) {
        // ✅ Show dialog when status becomes 5
        if (state is OrderUpdated && state.orderDetail.status == 5) {
          Future.delayed(Duration(milliseconds: 300), () {
            showDeliveryMethodDialog(
              context: context,
              orderDetail: state.orderDetail,
              tailorId: tailorId,
              onDismiss: () {},
            );
          });
        }
      },
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${order.orderId}'),
              SizedBox(height: 16),
              
              // Show different button based on status
              if (order.status == 4)
                PrimaryButton(
                  label: 'Mark as Completed',
                  onPressed: () {
                    context.read<OrderCubit>().tailorMarkCompleted(
                      detailsId: order.detailsId,
                      tailorId: tailorId,
                    );
                  },
                )
              else if (order.status == 5)
                Text('Select delivery method...'),
              else if (order.status >= 6)
                Text('Status: ${order.status}'),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🎨 Dialog Screenshot Description

When tailor marks order complete:
1. Beautiful dialog appears
2. Two large option buttons with icons
3. "Book a Ride" (caramel color)
4. "Customer Will Pick" (deepBrown color)
5. Loading spinners while processing
6. Cancel button at bottom

---

## 🧪 Quick Test

1. Go to your orders screen
2. Find order with status 4 (Received)
3. Click "Mark as Completed"
4. Dialog should appear
5. Click "Book a Ride"
6. Driver selection screen appears
7. Select a driver
8. Ride status screen appears with timeline

---

## ❓ FAQ

**Q: Where does the dialog appear?**  
A: After tailor marks order complete (status 5)

**Q: What if there are no drivers available?**  
A: Error message appears, user can retry

**Q: Can user cancel the dialog?**  
A: Yes, Cancel button is always available

**Q: What if network fails?**  
A: Error message shows, user can retry

**Q: Do I need to change existing screens?**  
A: No, just add the dialog listener and button

---

## 🚨 Common Issues & Solutions

**Issue**: Dialog doesn't appear
- **Solution**: Make sure OrderCubit listener is added correctly
- **Check**: Is status really becoming 5?

**Issue**: Drivers not loading
- **Solution**: Check Firestore has drivers with `availability: true`
- **Check**: Network connection working?

**Issue**: Import error
- **Solution**: Make sure file path is correct
- **Check**: `lib/view/base/delivery_method_dialog.dart` exists?

---

## 📞 Need More Help?

1. Read `DELIVERY_FLOW_INTEGRATION.md` for detailed guide
2. See `EXAMPLE_ORDER_ITEM_INTEGRATION.dart` for complete example
3. Check `DELIVERY_FLOW_COMPLETE_SUMMARY.md` for full overview

---

✅ **You're all set!**

Just import, add listener, add button. Everything else is automatic!

