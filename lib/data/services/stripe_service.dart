import 'dart:convert';
import 'package:http/http.dart' as http;


class StripeService {
  static const String _secretKey = 'sk_test_51S8DVA3pBxs4GQq6miyeVaxVlQnHrTZRjv7z3ag4uPrKxMNNvALi6DQQCV2dTYUJfvtYzIIiMIBScXjeyWUTMFp500c504eNaW';

  static const String _baseUrl = 'https://api.stripe.com/v1';


  static Future<String?> createConnectedAccount({
    required String email,
    String country = 'US',
  }) async {

    try {
      final uri = Uri.parse('$_baseUrl/accounts');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
        body: {
          'type': 'express',
          'country': country,
          'email': email,
          // Request transfers capability so payouts can work.
          'capabilities[transfers][requested]': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'] as String?; // acct_xxx
      } else {
        // Log error for debugging.
        // In production, parse error body and surface a friendly message.
        // ignore: avoid_print
        print('Stripe account creation failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Stripe exception: $e');
      return null;
    }
  }
}

