import 'dart:convert';
import 'package:coffee_masters/model/category.dart' as models;
import 'package:coffee_masters/model/itemincart.dart';
import 'package:coffee_masters/model/product.dart';
import 'package:coffee_masters/model/user.dart';
import 'package:coffee_masters/model/order.dart';
import 'package:coffee_masters/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';

class DataManager extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _currentUserId;
  User? _currentUser;
  List<ItemInCart> _cart = [];
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  List<ItemInCart> get cart => _cart;
  bool get isInitialized => _isInitialized;

  DataManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print('Starting DataManager initialization...');
      
      if (kIsWeb) {
        print('Initializing for web platform...');
        var webFactory = databaseFactoryFfiWeb;
        await _dbHelper.initializeWithFactory(webFactory);
      } else if (Platform.isAndroid || Platform.isIOS) {
        print('Initializing for mobile platform...');
        // For mobile platforms, use the default sqflite implementation
        await _dbHelper.initializeWithFactory(databaseFactory);
      } else {
        print('Initializing for desktop platforms...');
        sqfliteFfiInit();
        var desktopFactory = databaseFactoryFfi;
        await _dbHelper.initializeWithFactory(desktopFactory);
      }

      print('Database initialization completed');

      // Initialize SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      if (_currentUserId != null) {
        print('Found existing user ID: $_currentUserId');
        _currentUser = await _dbHelper.getUser(_currentUserId!);
      } else {
        print('No existing user ID found');
      }

      _isInitialized = true;
      print('DataManager initialization completed successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error initializing DataManager: $e');
      print('Stack trace: $stackTrace');
      
      // For web, we'll use in-memory storage as fallback
      if (kIsWeb) {
        print('Using in-memory storage as fallback for web');
        _isInitialized = true;
        notifyListeners();
      } else {
        print('Initialization failed for platform');
        // Set initialized to true anyway to prevent infinite loading
        _isInitialized = true;
        notifyListeners();
      }
    }
  }

  // User methods
  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  Future<bool> login(String email, String password) async {
    if (!_isInitialized) {
      print('DataManager not initialized, attempting to initialize...');
      await _initialize();
    }

    try {
      print('Attempting to login with email: $email');
      User? user = await _dbHelper.getUserByEmail(email);
      print('User found: ${user != null}');

      if (user != null && user.password == password) {
        print('Login successful for user: ${user.id}');
        _currentUserId = user.id;
        _currentUser = user;

        // Save to preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id!);

        notifyListeners();
        return true;
      }
      print('Login failed: Invalid credentials');
      return false;
    } catch (e, stackTrace) {
      print('Error logging in: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> register(User user) async {
    if (!_isInitialized) {
      print('DataManager not initialized, attempting to initialize...');
      await _initialize();
    }

    try {
      print('Attempting to register user with email: ${user.email}');
      
      // Check if user already exists
      User? existingUser = await _dbHelper.getUserByEmail(user.email);
      if (existingUser != null) {
        print('User with email ${user.email} already exists');
        return false;
      }

      // Generate a unique ID for the user
      String userId = DateTime.now().millisecondsSinceEpoch.toString();
      User userWithId = user.copyWith(
        id: userId,
        createdAt: DateTime.now().toIso8601String(),
      );

      print('Creating new user with ID: $userId');
      int result = await _dbHelper.insertUser(userWithId);
      
      if (result > 0) {
        print('User registered successfully');
        // Don't set current user here, let them login first
        return true;
      }
      
      print('Failed to register user');
      return false;
    } catch (e, stackTrace) {
      print('Error registering user: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentUser = null;
    _cart = [];

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
    } catch (e) {
      print('Error removing user ID from preferences: $e');
    }

    notifyListeners();
  }

  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      int result = await _dbHelper.updateUser(updatedUser);
      if (result > 0) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user: $e');
      // If in debug mode, update the local user object anyway
      if (kDebugMode) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  // Cart methods
  Future<void> cartAdd(Product p) async {
    try {
      await _dbHelper.addToCart(_currentUserId, p);
      await _refreshCart();
    } catch (e) {
      print('Error adding to cart: $e');
      // Handle the error gracefully - maybe use in-memory cart for web
      _addToInMemoryCart(p);
    }
  }

  void _addToInMemoryCart(Product p) {
    // Find if product is already in cart
    int index = _cart.indexWhere((item) => item.product.id == p.id);
    if (index != -1) {
      // Increase quantity
      _cart[index] = ItemInCart(
        product: p,
        quantity: _cart[index].quantity + 1,
      );
    } else {
      // Add new item
      _cart.add(ItemInCart(product: p, quantity: 1));
    }
    notifyListeners();
  }

  Future<void> cartRemove(Product p) async {
    try {
      await _dbHelper.removeFromCart(_currentUserId, p);
      await _refreshCart();
    } catch (e) {
      print('Error removing from cart: $e');
      // Handle the error gracefully - use in-memory cart for web
      _removeFromInMemoryCart(p);
    }
  }

  void _removeFromInMemoryCart(Product p) {
    _cart.removeWhere((item) => item.product.id == p.id);
    notifyListeners();
  }

  Future<void> cartClear() async {
    try {
      await _dbHelper.clearCart(_currentUserId);
      _cart = [];
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
      // Clear in-memory cart
      _cart = [];
      notifyListeners();
    }
  }

  Future<double> getCartTotal() async {
    try {
      double total = 0;
      for (var item in _cart) {
        total += item.product.price * item.quantity;
      }
      return total;
    } catch (e) {
      print('Error calculating cart total: $e');
      return 0;
    }
  }

  Future<List<ItemInCart>> getCartItems() async {
    try {
      return await _dbHelper.getCartItems(_currentUserId);
    } catch (e) {
      print('Error getting cart items: $e');
      // Return in-memory cart
      return _cart;
    }
  }

  Future<void> _refreshCart() async {
    try {
      _cart = await _dbHelper.getCartItems(_currentUserId);
      notifyListeners();
    } catch (e) {
      print('Error refreshing cart: $e');
      // No need to do anything, we'll use the in-memory cart
    }
  }

  Future<void> updateCartItemQuantity(ItemInCart item, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await cartRemove(item.product);
      } else {
        await _dbHelper.updateCartItemQuantity(
          _currentUserId,
          item.product.id,
          newQuantity,
        );
        await _refreshCart();
      }
    } catch (e) {
      print('Error updating cart item quantity: $e');
      // Update in-memory cart
      if (newQuantity <= 0) {
        _removeFromInMemoryCart(item.product);
      } else {
        int index = _cart.indexWhere((i) => i.product.id == item.product.id);
        if (index != -1) {
          _cart[index] = ItemInCart(
            product: item.product,
            quantity: newQuantity,
          );
          notifyListeners();
        }
      }
    }
  }

  Future<void> removeFromCart(ItemInCart item) async {
    await cartRemove(item.product);
  }

  Future<void> clearCart() async {
    await cartClear();
  }

  Future<void> insertCategories(List<models.Category> categories) async {
    try {
      await _dbHelper.insertCategories(categories);
      notifyListeners();
    } catch (e) {
      print('Error inserting categories: $e');
    }
  }

  // Menu methods
  Future<void> fetchMenu() async {
    try {
      const url = 'https://firtman.github.io/coffeemasters/api/menu.json';
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<models.Category> categories = [];
        var decodedData = jsonDecode(response.body) as List<dynamic>;

        for (var json in decodedData) {
          categories.add(models.Category.fromJson(json));
        }

        // Save to database
        try {
          await _dbHelper.insertCategories(categories);
        } catch (e) {
          print('Error saving menu to database: $e');
        }
      } else {
        throw Exception("Error loading data");
      }
    } catch (e) {
      print('Error fetching menu: $e');
      throw Exception("Error loading data");
    }
  }

  Future<List<models.Category>> getMenu() async {
    try {
      // Check if menu exists in database
      List<models.Category> categories = await _dbHelper.getCategories();

      if (categories.isEmpty) {
        // If not, fetch from API
        await fetchMenu();
        try {
          categories = await _dbHelper.getCategories();
        } catch (e) {
          print('Error getting menu from database: $e');
          // Try to fetch from API again and return directly
          const url = 'https://firtman.github.io/coffeemasters/api/menu.json';
          var response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            List<models.Category> apiCategories = [];
            var decodedData = jsonDecode(response.body) as List<dynamic>;

            for (var json in decodedData) {
              apiCategories.add(models.Category.fromJson(json));
            }
            return apiCategories;
          }
        }
      }

      return categories;
    } catch (e) {
      print('Error getting menu: $e');

      // Fallback - fetch directly from API
      try {
        const url = 'https://firtman.github.io/coffeemasters/api/menu.json';
        var response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          List<models.Category> categories = [];
          var decodedData = jsonDecode(response.body) as List<dynamic>;

          for (var json in decodedData) {
            categories.add(models.Category.fromJson(json));
          }
          return categories;
        } else {
          throw Exception("Error loading data");
        }
      } catch (fallbackError) {
        print('Fallback error getting menu: $fallbackError');
        throw Exception("Error loading data");
      }
    }
  }

  // Order methods
  Future<bool> placeOrder() async {
    try {
      if (_currentUserId == null) return false;

      // Get cart items
      List<ItemInCart> items = await getCartItems();
      if (items.isEmpty) return false;

      // Calculate total
      double total = await getCartTotal();

      // Save order to database and get the orderId
      String orderId = await _dbHelper.createOrder(_currentUserId!, items, total);
      
      // Schedule status update after 2 minutes
      Future.delayed(const Duration(minutes: 2), () async {
      try {
          await _dbHelper.updateOrderStatus(orderId, 'Completed');
          notifyListeners(); // Notify listeners to update UI
      } catch (e) {
          print('Error updating order status: $e');
        }
      });

      // Clear cart
      await cartClear();
      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  Future<List<Order>> getOrderHistory() async {
    if (_currentUserId == null) return [];
    try {
      return await _dbHelper.getOrderHistory(_currentUserId!);
    } catch (e) {
      print('Error getting order history: $e');
      return [];
    }
  }

  Future<void> addOrder(Order order) async {
    try {
      await _dbHelper.createOrder(
        _currentUserId!,
        order.items,
        order.totalAmount,
      );
      await clearCart();
    } catch (e) {
      print('Error adding order: $e');
      // Clear cart anyway to avoid duplicate orders
      await clearCart();
    }
  }

  // Add method to refresh orders
  Future<void> refreshOrders() async {
    notifyListeners();
  }
}
