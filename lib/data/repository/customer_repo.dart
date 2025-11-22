import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for managing customer data operations
class CustomerRepo {
  final CollectionReference _customersCol =
      FirebaseFirestore.instance.collection('customer');

  /// Fetch customer name by customer ID
  /// Returns the customer's name, trying 'name' field first, then 'full_name'
  /// Returns null if customer doesn't exist or has no name field
  Future<String?> getCustomerName(String customerId) async {
    try {
      final doc = await _customersCol.doc(customerId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      return data['name'] as String? ?? data['full_name'] as String?;
    } catch (e) {
      // Log error or handle appropriately
      return null;
    }
  }

  /// Fetch complete customer data by customer ID
  Future<Map<String, dynamic>?> getCustomer(String customerId) async {
    try {
      final doc = await _customersCol.doc(customerId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        data['customer_id'] = customerId;
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Stream customer data for real-time updates
  Stream<Map<String, dynamic>?> streamCustomer(String customerId) {
    return _customersCol.doc(customerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        data['customer_id'] = customerId;
      }
      return data;
    });
  }
}

