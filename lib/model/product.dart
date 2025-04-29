class Product {
  final int id;
  final String name;
  final double price;
  final String image;
  final String? description;
  final int? categoryId;

  String get imageUrl =>
      "https://firtman.github.io/coffeemasters/api/images/${image.toLowerCase()}";

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.description,
    this.categoryId,
  });

  // Create a Product from a JSON map
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int?,
    );
  }

  // Convert a Product to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'categoryId': categoryId,
    };
  }

  // Create a copy of this Product with given fields replaced with new values
  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? image,
    String? description,
    int? categoryId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}