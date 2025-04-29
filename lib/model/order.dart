import 'package:coffee_masters/model/itemincart.dart';

class Order {
  final String id;
  final String userId;
  final DateTime date;
  final List<ItemInCart> items;
  final double totalAmount;
  final String status;

  Order({
    required this.id,
    required this.userId,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.status,
  });

  // Create an Order from a JSON map
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      items: (json['items'] as List)
          .map((item) => ItemInCart.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      status: json['status'],
    );
  }

  // Convert an Order to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
    };
  }

  // Convert an Order to a map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': itemsToJson(),
      'totalAmount': totalAmount,
      'status': status,
      'userId': userId,
    };
  }

  // Helper method to convert items to JSON string
  String itemsToJson() {
    final itemList = items.map((item) => item.toJson()).toList();
    return itemList.toString();
  }

  // Create a copy of this Order with given fields replaced with new values
  Order copyWith({
    String? id,
    String? userId,
    DateTime? date,
    List<ItemInCart>? items,
    double? totalAmount,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
    );
  }
}
