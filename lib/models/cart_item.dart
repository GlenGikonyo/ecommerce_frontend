class CartItem {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final int stock;
  final String? image;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.stock,
    this.image,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      stock: json['stock'] ?? 0,
      image: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productId": id,
      "quantity": quantity,
      "price": price,
    };
  }
}