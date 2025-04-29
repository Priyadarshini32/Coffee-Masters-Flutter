import 'package:coffee_masters/model/product.dart';

class Category {
  final int id;
  final String name;
  final List<Product> products;

  Category({
    required this.id,
    required this.name,
    required this.products,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      products: (json['products'] as List)
          .map((product) => Product.fromJson(product))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }
}
