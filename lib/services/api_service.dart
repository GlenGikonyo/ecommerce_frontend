import 'dart:convert';
import 'package:ecommerce_app/models/cart_item.dart';
import 'package:http/http.dart' as http;
// import '../config.dart';

class ApiService {
  static const String baseUrl =
      "https://ecommerce-flutter-6ybv.onrender.com/api";
  static Future<Map<String, dynamic>?> initiatePayment({
    required int orderId,
    required double amount,
    required String email,
    required String phone,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/payments/intasend/initiate"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // VERY IMPORTANT
      },
      body: jsonEncode({
        "orderId": orderId,
        "amount": amount,
        "email": email,
        "phone": phone,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(response.body);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> placeOrder({
    required List<CartItem> items,
    required String token,
    required double totalAmount,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/orders"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "items": items.map((e) => e.toJson()).toList(),
        "totalAmount": totalAmount,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> addToCart({
    required int productId,
    required int quantity,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/cart/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"productId": productId, "quantity": quantity}),
    );

    return response.statusCode == 200;
  }

  static Future<List<CartItem>> getCart(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/cart"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map(
            (item) => CartItem(
              id: item['id'],
              name: item['name'],
              price: double.parse(item['price'].toString()),
              quantity: item['quantity'],
              stock: 999,
              image: '',
            ),
          )
          .toList();
    }

    return [];
  }

  static Future<void> updateCartItem({
    required int productId,
    required int quantity,
    required String token,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/cart/update"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"productId": productId, "quantity": quantity}),
    );

    if (response.statusCode != 200) {
      print("Failed to update cart: ${response.body}");
    }
  }

  static Future<void> removeCartItem({
    required int productId,
    required String token,
  }) async {
    await http.delete(
      Uri.parse("$baseUrl/cart/remove/$productId"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

static Future<String?> createPaymentSession({
  required int orderId,
  required double amount,
  required String email,
  required String phone,
  required String token,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/payments/intasend/initiate"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "orderId": orderId,
      "amount": amount,
      "email": email,
      "phone": phone,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["checkoutUrl"];
  }

  return null;
}
}
