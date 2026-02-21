import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/product_service.dart';
import '../services/api_service.dart';
// import '../models/cart_item.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();

  List<dynamic> _products = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartCount();
  }

  // ================= LOAD PRODUCTS =================
  Future<void> _loadProducts() async {
    final data = await _productService.getProducts();

    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  // ================= LOAD CART COUNT =================
  Future<void> _loadCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null) {
      final items = await ApiService.getCart(token);

      int total = 0;
      for (var item in items) {
        total += item.quantity;
      }

      setState(() {
        _cartCount = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? const Center(child: Text("No products available"))
                      : GridView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.70,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_products[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Stylish',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= PRODUCT CARD =================
  Widget _buildProductCard(dynamic product) {
    final String name = product['name'] ?? '';
    final String price = product['price'].toString();
    final int stock = product['stock'] ?? 0;
    final String base64Image = product['image_url'] ?? '';

    Uint8List? imageBytes;

    try {
      if (base64Image.contains(',')) {
        final base64Str = base64Image.split(',').last;
        imageBytes = base64Decode(base64Str);
      }
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: imageBytes != null
                ? Image.memory(
                    imageBytes,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 140,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image, size: 50),
                  ),
          ),

          // DETAILS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stock > 0 ? "In Stock ($stock left)" : "Out of Stock",
                  style: TextStyle(
                    fontSize: 12,
                    color: stock > 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "KES $price",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    InkWell(
                      onTap: stock > 0
                          ? () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token =
                                  prefs.getString("token");

                              if (token == null) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Please login first")),
                                );
                                return;
                              }

                              final success =
                                  await ApiService.addToCart(
                                productId: product['id'],
                                quantity: 1,
                                token: token,
                              );

                              if (success) {
                                await _loadCartCount();

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "$name added to cart")),
                                );
                              }
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: stock > 0
                              ? Colors.red
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CartScreen()),
          ).then((_) {
            _loadCartCount(); // refresh when returning
          });
        }
      },
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Home'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist'),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart_outlined),
              if (_cartCount > 0)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _cartCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile'),
      ],
    );
  }
}
