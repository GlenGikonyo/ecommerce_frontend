import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
// import 'order_success_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null) {
      final items = await ApiService.getCart(token);

      double total = 0;
      for (var item in items) {
        total += item.price * item.quantity;
      }

      setState(() {
        cartItems = items;
        totalPrice = total;
        isLoading = false;
      });
    }
  }

  Future<void> increaseQuantity(int productId, int currentQty) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null) {
      await ApiService.updateCartItem(
        productId: productId,
        quantity: currentQty + 1,
        token: token,
      );
      await loadCart();
    }
  }

  Future<void> decreaseQuantity(int productId, int currentQty) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null && currentQty > 1) {
      await ApiService.updateCartItem(
        productId: productId,
        quantity: currentQty - 1,
        token: token,
      );
      await loadCart();
    }
  }

  Future<void> removeItem(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null) {
      await ApiService.removeCartItem(productId: productId, token: token);

      await loadCart();
    }
  }

Future<void> checkout() async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString("token");
  final email = prefs.getString("email");
  final phone = prefs.getString("phone");

  print("Token: $token");
  print("Email: $email");
  print("Phone: $phone");
  print("Cart items: ${cartItems.length}");

  if (token != null &&
      email != null &&
      cartItems.isNotEmpty) {

    final order = await ApiService.placeOrder(
      items: cartItems,
      token: token,
      totalAmount: totalPrice,
    );

    print("Order response: $order");

    if (order != null) {
      final int orderId = order["orderId"];

      final paymentUrl = await ApiService.createPaymentSession(
        orderId: orderId,
        amount: totalPrice,
        email: email,
        phone: phone ?? "0700000000",
        token: token,
      );

      print("Payment URL: $paymentUrl");

      if (paymentUrl != null) {
        await launchUrl(
          Uri.parse(paymentUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        print("Payment URL is null");
      }
    }
  } else {
    print("Checkout conditions not met");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            "KES ${item.price} x ${item.quantity}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () =>
                                    decreaseQuantity(item.id, item.quantity),
                              ),
                              Text(item.quantity.toString()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    increaseQuantity(item.id, item.quantity),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => removeItem(item.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Total: KES $totalPrice",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: checkout,
                          child: const Text("Proceed to Payment"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
