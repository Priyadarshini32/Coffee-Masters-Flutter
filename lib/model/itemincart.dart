import 'package:coffee_masters/model/product.dart';

class ItemInCart {
  final Product product;
  final int quantity;

  ItemInCart({
    required this.product,
    required this.quantity,
  });

  // Create an ItemInCart from a JSON map
  factory ItemInCart.fromJson(Map<String, dynamic> json) {
    return ItemInCart(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }

  // Convert an ItemInCart to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  // Create a copy of this ItemInCart with given fields replaced with new values
  ItemInCart copyWith({
    Product? product,
    int? quantity,
  }) {
    return ItemInCart(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}