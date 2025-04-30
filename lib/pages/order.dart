import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../data_manager.dart';
import '../model/itemincart.dart';
import '../model/order.dart';

class OrderPage extends StatefulWidget {
  final DataManager dataManager;

  const OrderPage({
    Key? key,
    required this.dataManager,
  }) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  double _subtotal = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartTotal();
  }

  Future<void> _loadCartTotal() async {
    final subtotal = await widget.dataManager.getCartTotal();
    setState(() {
      _subtotal = subtotal;
      _tax = subtotal * 0.1;
      _total = subtotal + _tax;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Order'),
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (dataManager.cart.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: dataManager.cart.length,
                  itemBuilder: (context, index) {
                    var item = dataManager.cart[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('\$${item.product.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () async {
                              await dataManager.updateCartItemQuantity(item, item.quantity - 1);
                              _loadCartTotal();
                            },
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              await dataManager.updateCartItemQuantity(item, item.quantity + 1);
                              _loadCartTotal();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await dataManager.removeFromCart(item);
                              _loadCartTotal();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$${_subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax (10%):'),
                        Text('\$${_tax.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:'),
                        Text('\$${_total.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (dataManager.currentUser == null) {
                          Navigator.pushNamed(context, '/login');
                          return;
                        }

                        await _processOrder(context, dataManager, _total);
                      },
                      child: const Text('Place Order'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processOrder(BuildContext context, DataManager dataManager, double total) async {
    try {
      // Create new order
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        items: List.from(dataManager.cart),
        totalAmount: total,
        status: 'Processing',
        userId: dataManager.currentUser!.id!,
      );

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
            ),
          );
        },
      );

      // Save order to database
      await dataManager.addOrder(order);
      
      // Clear cart
      dataManager.clearCart();
      
      // Close loading indicator
      Navigator.pop(context);
      
      // Show success message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Order Placed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your order has been successfully placed.'),
                const SizedBox(height: 16),
                Text('Order ID: ${order.id}'),
                Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/main');
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class CartItemWidget extends StatelessWidget {
  final ItemInCart item;

  const CartItemWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_cafe, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.description ?? 'No description available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      QuantitySelector(item: item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantitySelector extends StatelessWidget {
  final ItemInCart item;

  const QuantitySelector({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);

    return Row(
      children: [
        _buildIconButton(
          context,
          Icons.remove,
          () {
            if (item.quantity > 1) {
              dataManager.updateCartItemQuantity(item, item.quantity - 1);
            } else {
              dataManager.removeFromCart(item);
            }
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${item.quantity}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        _buildIconButton(
          context,
          Icons.add,
          () => dataManager.updateCartItemQuantity(item, item.quantity + 1),
        ),
        const SizedBox(width: 8),
        _buildIconButton(
          context,
          Icons.delete_outline,
          () => dataManager.removeFromCart(item),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Colors.black87,
          ),
        ),
      ),
    );
  }
}

class OrderSummary extends StatelessWidget {
  const OrderSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        return FutureBuilder<double>(
          future: dataManager.getCartTotal(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final subtotal = snapshot.data ?? 0.0;
            final tax = subtotal * 0.1; // 10% tax
            final total = subtotal + tax;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax (10%):'),
                      Text('\$${tax.toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _processOrder(context, dataManager, total),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _processOrder(BuildContext context, DataManager dataManager, double total) async {
    // Check if user is logged in
    if (dataManager.currentUser == null) {
      _showLoginPrompt(context);
      return;
    }

    // Create new order
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      items: List.from(dataManager.cart),
      totalAmount: total,
      status: 'Processing',
      userId: dataManager.currentUser!.id!,
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
          ),
        );
      },
    );

    try {
      // Save order to database
      await dataManager.addOrder(order);
      
      // Clear cart
      dataManager.clearCart();
      
      // Close loading indicator
      Navigator.pop(context);
      
      // Show success message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Order Placed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your order has been successfully placed.'),
                const SizedBox(height: 16),
                Text('Order ID: ${order.id}'),
                Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/main');
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to place an order.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }
}