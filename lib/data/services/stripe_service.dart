import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class StripeService {
  static String get _secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';
  static const String _baseUrl = 'https://api.stripe.com/v1';


  static Future<String?> createConnectedAccount({
    required String email,
    String country = 'US',
  }) async {

    try {
      if (_secretKey.isEmpty) {
        // ignore: avoid_print
        print('Stripe secret key is missing. Ensure STRIPE_SECRET_KEY is set in .env');
        return null;
      }
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
