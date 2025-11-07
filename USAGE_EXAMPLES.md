# Complete Usage Examples - BLoC State Management

## 1. Login Implementation

### UI Screen (login_screen.dart)
```dart
BlocConsumer<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is AuthSuccess) {
      // Navigate to home
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (state is AuthError) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  },
  builder: (context, state) {
    bool isLoading = state is AuthLoading;
    
    return Column(
      children: [
        TextField(controller: emailController),
        TextField(controller: passwordController),
        ElevatedButton(
          onPressed: isLoading ? null : () {
            context.read<AuthCubit>().login(
              email: emailController.text,
              password: passwordController.text,
            );
          },
          child: isLoading ? CircularProgressIndicator() : Text('Login'),
        ),
      ],
    );
  },
)
```

### What Happens Behind:
1. UI calls: `context.read<AuthCubit>().login(email, password)`
2. AuthCubit emits: `AuthLoading()`
3. AuthCubit calls: `authRepo.login(email, password)`
4. AuthRepo calls: `FirebaseAuth.instance.signInWithEmailAndPassword(...)`
5. AuthRepo fetches Tailor from Firestore
6. AuthRepo returns: `Tailor` object
7. AuthCubit emits: `AuthSuccess(tailor)`
8. UI listens and navigates to HomeScreen

---

## 2. Fetch Orders Implementation

### UI Screen (home_screen.dart)
```dart
@override
void initState() {
  super.initState();
  // Get current tailor from auth state
  final authState = context.read<AuthCubit>().state;
  if (authState is AuthSuccess) {
    // Fetch orders for this tailor
    context.read<OrderCubit>().fetchOrderDetailsForTailor(
      authState.tailor.tailor_id,
    );
  }
}

@override
Widget build(BuildContext context) {
  return BlocConsumer<OrderCubit, OrderState>(
    listener: (context, state) {
      if (state is OrderError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message), backgroundColor: Colors.red),
        );
      }
    },
    builder: (context, state) {
      if (state is OrderLoading) {
        return Center(child: CircularProgressIndicator());
      } else if (state is OrderDetailsSuccess) {
        return ListView.builder(
          itemCount: state.orderDetails.length,
          itemBuilder: (context, index) {
            final order = state.orderDetails[index];
            return OrderDetailCard(orderDetail: order);
          },
        );
      } else if (state is OrderError) {
        return ErrorWidget(message: state.message);
      }
      return SizedBox.shrink();
    },
  );
}
```

### What Happens Behind:
1. UI calls: `context.read<OrderCubit>().fetchOrderDetailsForTailor(tailorId)`
2. OrderCubit emits: `OrderLoading()`
3. OrderCubit calls: `orderRepo.getOrderDetailsForTailor(tailorId)`
4. OrderRepo queries: `Firestore.collection('orderDetail').where('tailor_id', isEqualTo: tailorId)`
5. OrderRepo returns: `List<OrderDetail>`
6. OrderCubit emits: `OrderDetailsSuccess(orderDetails)`
7. BlocConsumer builder renders ListView with orders

---

## 3. Update Order Status

### UI Implementation
```dart
ElevatedButton(
  onPressed: () {
    context.read<OrderCubit>().updateOrderDetailStatus(
      detailsId: order.detailsId,
      newStatus: 0, // Mark as accepted
    );
  },
  child: Text('Accept Order'),
),
```

### State Management Flow
```
UI Button Pressed
  ↓
context.read<OrderCubit>().updateOrderDetailStatus(detailsId, 0)
  ↓
OrderCubit emits: OrderLoading()
  ↓
OrderCubit calls: orderRepo.updateOrderDetailStatus(detailsId, 0)
  ↓
OrderRepo updates: Firestore.collection('orderDetail').doc(detailsId).update({'status': 0})
  ↓
OrderRepo fetches updated: OrderDetail
  ↓
OrderCubit emits: OrderDetailUpdated(orderDetail)
  ↓
UI listens and shows success snackbar
```

---

## 4. Create New Order Detail

### UI Implementation
```dart
FloatingActionButton(
  onPressed: () {
    context.read<OrderCubit>().createOrderDetail(
      orderId: 'order123',
      tailorId: tailorId,
      customerId: customerId,
      customerName: 'Ali',
      description: 'Custom suit',
      price: 5000,
      totalPrice: 5000,
      paymentMethod: 'Cash',
      status: -1, // Pending
      measurements: Measurements(
        chest: 40,
        waist: 32,
        hips: 35,
        shoulder: 18,
        armLength: 24,
        wrist: 9,
        armpit: 20,
        fittingPreferences: 'Slim Fit',
      ),
      fabric: Fabric(
        shirtFabric: 'Silk',
        trouserFabric: 'Cotton',
        dupatFabric: 'Linen',
      ),
    );
  },
  child: Icon(Icons.add),
)
```

---

## 5. Error Handling

### UI Pattern
```dart
BlocConsumer<OrderCubit, OrderState>(
  listener: (context, state) {
    if (state is OrderError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state is OrderDetailUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  },
  builder: (context, state) {
    if (state is OrderError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: ${state.message}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Retry
                context.read<OrderCubit>().fetchOrderDetailsForTailor(tailorId);
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    // ... handle other states
  },
)
```

---

## 6. Logout Implementation

### UI Implementation
```dart
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.logout),
      onPressed: () {
        context.read<AuthCubit>().logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    ),
  ],
)
```

### Cubit Logic
```dart
Future<void> logout() async {
  try {
    await authRepo.logout(); // Calls FirebaseAuth.signOut()
    emit(const AuthInitial());
  } catch (e) {
    emit(AuthError(e.toString()));
  }
}
```

---

## 7. Multi-Cubit Coordination

### Using Both Auth and Order Cubits
```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Get current tailor from auth
    final authState = context.read<AuthCubit>().state;
    
    if (authState is AuthSuccess) {
      // Use tailor ID to fetch orders
      context.read<OrderCubit>().fetchOrderDetailsForTailor(
        authState.tailor.tailor_id,
      );
      
      // Fetch pending orders
      context.read<OrderCubit>().fetchPendingOrderDetailsForTailor(
        authState.tailor.tailor_id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          // ... render orders
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData, // Refresh
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## 8. State Transitions Visualization

### Order Detail Workflow
```
OrderInitial
    ↓
User taps "View Orders"
    ↓ fetchOrderDetailsForTailor()
OrderLoading (show spinner)
    ↓ Firebase query completes
OrderDetailsSuccess (show list)
    ↓
User taps "Accept Order"
    ↓ updateOrderDetailStatus()
OrderLoading (show spinner)
    ↓ Firebase update completes
OrderDetailUpdated (show success)
    ↓ Auto-refresh list
OrderDetailsSuccess (updated list shown)
```

---

## 9. BLoC vs Direct Firebase

### ❌ BEFORE (Direct Firebase in UI)
```dart
// BAD: Firebase logic in UI
ElevatedButton(
  onPressed: () async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('orderDetail')
          .where('tailor_id', isEqualTo: tailorId)
          .get();
      
      setState(() {
        orders = result.docs.map((doc) => OrderDetail.fromMap(doc.data())).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  },
  child: Text('Load Orders'),
)
```

### ✅ AFTER (Using Cubit)
```dart
// GOOD: No Firebase in UI
ElevatedButton(
  onPressed: () {
    context.read<OrderCubit>().fetchOrderDetailsForTailor(tailorId);
  },
  child: Text('Load Orders'),
)
```

---

## Key Takeaways

1. **UI has NO Firebase imports or operations**
2. **All Firebase logic is in Repositories**
3. **Cubits manage state and coordinate Repository calls**
4. **States are immutable and use Equatable**
5. **UI reacts to state changes via BlocBuilder/BlocConsumer**
6. **Single file format: Cubit + all States in one file**
7. **Easy to test: Mock repositories for unit tests**
8. **Scalable: Add new Cubits/Repos without changing UI**


