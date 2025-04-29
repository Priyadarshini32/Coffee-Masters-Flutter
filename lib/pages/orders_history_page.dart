import 'package:flutter/material.dart';
import 'package:coffee_masters/data_manager.dart';
import 'package:coffee_masters/model/order.dart';
import 'package:intl/intl.dart';

class OrdersHistoryPage extends StatefulWidget {
  final DataManager dataManager;

  const OrdersHistoryPage({Key? key, required this.dataManager}) : super(key: key);

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    widget.dataManager.addListener(_onDataManagerChanged);
  }

  @override
  void dispose() {
    widget.dataManager.removeListener(_onDataManagerChanged);
    super.dispose();
  }

  void _onDataManagerChanged() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await widget.dataManager.getOrderHistory();
      if (!mounted) return;
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.brown[300]),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
              ),
            );
          }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
            itemBuilder: (context, index) {
          final order = _orders[index];
              return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.brown[100]!, width: 1),
            ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            order.status,
                          style: const TextStyle(
                            color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ),
                        ],
                      ),
                  const SizedBox(height: 12),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy - h:mm a').format(order.date)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                      const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.product.name}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                      const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                            ),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.brown;
      case 'processing':
        return Colors.brown[300]!;
      case 'canceled':
        return Colors.brown[900]!;
      default:
        return Colors.brown[500]!;
    }
  }
}
