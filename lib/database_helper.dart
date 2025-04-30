import 'dart:convert';
import 'package:coffee_masters/model/category.dart';
import 'package:coffee_masters/model/order.dart';
import 'package:coffee_masters/model/product.dart';
import 'package:coffee_masters/model/user.dart';
import 'package:coffee_masters/model/itemincart.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:path_provider/path_provider.dart' as path_provider;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static DatabaseFactory? _factory;

  // Singleton pattern
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<void> initializeWithFactory(DatabaseFactory factory) async {
    if (factory == null) {
      throw Exception('Database factory cannot be null');
    }
    _factory = factory;
    _database = null; // Reset database to force recreation with new factory
    await database; // Initialize database with new factory
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      print('Initializing database...');
      String path;
      
      if (kIsWeb) {
        path = 'coffee_masters.db';
      } else if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, use the app's documents directory
        path = join(await getDatabasesPath(), 'coffee_masters.db');
      } else {
        // For desktop platforms
        final appDir = await path_provider.getApplicationDocumentsDirectory();
        path = join(appDir.path, 'coffee_masters.db');
      }
      
      print('Database path: $path');
      
      if (_factory == null) {
        throw Exception('Database factory is not initialized');
      }
      
      var db = await _factory!.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (Database db, int version) async {
            print('Creating database tables...');
            await _createDb(db, version);
          },
          onOpen: (Database db) async {
            print('Database opened successfully');
          },
        ),
      );
      
      if (db == null) {
        throw Exception('Failed to open database');
      }
      
      print('Database initialized successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    try {
      print('Creating database tables...');
      
      // Create users table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          profileImage TEXT,
          createdAt TEXT NOT NULL
        )
      ''');

      // Create categories table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');

      // Create products table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          description TEXT,
          image TEXT NOT NULL,
          categoryId INTEGER NOT NULL,
          FOREIGN KEY (categoryId) REFERENCES categories (id)
        )
      ''');

      // Create cart items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cart_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT,
          productId INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id),
          FOREIGN KEY (productId) REFERENCES products (id)
        )
      ''');

      // Create orders table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS orders(
          id TEXT PRIMARY KEY,
          userId TEXT,
          date TEXT NOT NULL,
          items TEXT NOT NULL,
          totalAmount REAL NOT NULL,
          status TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');

      print('Database tables created successfully');
      
      // Insert initial data only if this is a new database
      if (version == 1) {
        print('Inserting initial data...');
        await _insertInitialData(db);
      }
    } catch (e) {
      print('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      print('Starting to insert initial data...');
      
      // Check if default user exists
      List<Map<String, dynamic>> existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: ['user@example.com'],
      );

      if (existingUser.isEmpty) {
        print('Creating default user...');
        // Insert default user only if it doesn't exist
        await db.insert('users', {
          'id': 'default_user',
          'name': 'Default User',
          'email': 'user@example.com',
          'password': 'password123',
          'phone': null,
          'address': null,
          'profileImage': null,
          'createdAt': DateTime.now().toIso8601String(),
        });
        print('Default user created successfully');
      } else {
        print('Default user already exists');
      }

      // Check if categories exist
      List<Map<String, dynamic>> existingCategories = await db.query('categories');
      if (existingCategories.isEmpty) {
        print('Creating categories...');
        // Insert categories only if they don't exist
        List<Map<String, dynamic>> categories = [
          {'id': 1, 'name': 'Hot Coffee'},
          {'id': 2, 'name': 'Iced Coffee'},
          {'id': 3, 'name': 'Tea'},
          {'id': 4, 'name': 'Pastries'}
        ];

        for (var category in categories) {
          await db.insert('categories', category);
        }
        print('Categories created successfully');
      } else {
        print('Categories already exist');
      }

      // Check if products exist
      List<Map<String, dynamic>> existingProducts = await db.query('products');
      if (existingProducts.isEmpty) {
        print('Creating products...');
        // Insert products only if they don't exist
        List<Map<String, dynamic>> products = [
          {
            'name': 'Black Americano',
            'price': 3.99,
            'description': 'Rich espresso with hot water',
            'image': 'blackamericano.png',
            'categoryId': 1
          },
          {
            'name': 'Cappuccino',
            'price': 4.49,
            'description': 'Espresso with steamed milk and foam',
            'image': 'cappuccino.png',
            'categoryId': 1
          },
          {
            'name': 'Cold Brew',
            'price': 4.99,
            'description': 'Slow-steeped coffee served cold',
            'image': 'coldbrew.png',
            'categoryId': 2
          },
          {
            'name': 'Flat White',
            'price': 4.29,
            'description': 'Espresso with velvety steamed milk',
            'image': 'flatwhite.png',
            'categoryId': 1
          },
          {
            'name': 'Frappuccino',
            'price': 5.49,
            'description': 'Blended coffee drink with ice',
            'image': 'frappuccino.png',
            'categoryId': 2
          },
          {
            'name': 'Iced Coffee',
            'price': 3.99,
            'description': 'Chilled coffee served over ice',
            'image': 'icedcoffee.png',
            'categoryId': 2
          },
          {
            'name': 'Macchiato',
            'price': 3.79,
            'description': 'Espresso with a dollop of foam',
            'image': 'macchiato.png',
            'categoryId': 1
          },
          {
            'name': 'Black Tea',
            'price': 3.49,
            'description': 'Classic black tea',
            'image': 'blacktea.png',
            'categoryId': 3
          },
          {
            'name': 'Green Tea',
            'price': 3.49,
            'description': 'Refreshing green tea',
            'image': 'greentea.png',
            'categoryId': 3
          },
          {
            'name': 'Croissant',
            'price': 2.99,
            'description': 'Buttery, flaky pastry',
            'image': 'croissant.png',
            'categoryId': 4
          },
          {
            'name': 'Muffin',
            'price': 2.49,
            'description': 'Freshly baked muffin',
            'image': 'muffin.png',
            'categoryId': 4
          }
        ];

        for (var product in products) {
          await db.insert('products', product);
        }
        print('Products created successfully');
      } else {
        print('Products already exist');
      }
    } catch (e) {
      print('Error inserting initial data: $e');
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    try {
      print('Attempting to insert user: ${user.email}');
      Database db = await database;
      
      // Check if user already exists
      List<Map<String, dynamic>> existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [user.email],
      );
      
      if (existing.isNotEmpty) {
        print('User with email ${user.email} already exists');
        return 0;
      }
      
      // Insert the user
      int result = await db.insert('users', user.toMap());
      print('User inserted successfully with result: $result');
      return result;
    } catch (e) {
      print('Error inserting user: $e');
      return 0;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) {
      return null;
    }

    return User.fromMap(maps.first);
  }

  Future<User?> getUser(String? id) async {
    if (id == null) return null;
    
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return User.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Product and category operations
  Future<List<Category>> getCategories() async {
    Database db = await database;
    List<Map<String, dynamic>> categoryMaps = await db.query('categories');
    
    List<Category> categories = [];
    
    for (var categoryMap in categoryMaps) {
      List<Map<String, dynamic>> productMaps = await db.query(
        'products',
        where: 'categoryId = ?',
        whereArgs: [categoryMap['id']],
      );
      
      List<Product> products = productMaps.map((productMap) => Product(
        id: productMap['id'],
        name: productMap['name'],
        price: productMap['price'],
        image: productMap['image'],
        description: productMap['description'] ?? '',
        categoryId: productMap['categoryId'],
      )).toList();
      
      categories.add(Category(
        id: categoryMap['id'],
        name: categoryMap['name'],
        products: products,
      ));
    }
    
    return categories;
  }

  Future<Product?> getProductById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Product(
      id: maps.first['id'],
      name: maps.first['name'],
      price: maps.first['price'],
      image: maps.first['image'],
      description: maps.first['description'] ?? '',
      categoryId: maps.first['categoryId'],
    );
  }

  // Cart operations
  Future<void> addToCart(String? userId, Product product, [int quantity = 1]) async {
    Database db = await database;
    
    // Check if the product is already in the cart
    List<Map<String, dynamic>> existing = await db.query(
      'cart_items',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, product.id],
    );
    
    if (existing.isNotEmpty) {
      // Update quantity
      int currentQuantity = existing.first['quantity'];
      await db.update(
        'cart_items',
        {'quantity': currentQuantity + quantity},
        where: 'userId = ? AND productId = ?',
        whereArgs: [userId, product.id],
      );
    } else {
      // Add new item
      await db.insert('cart_items', {
        'userId': userId,
        'productId': product.id,
        'quantity': quantity,
      });
    }
  }

  Future<void> removeFromCart(String? userId, Product product) async {
    Database db = await database;
    await db.delete(
      'cart_items',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, product.id],
    );
  }

  Future<void> clearCart(String? userId) async {
    Database db = await database;
    await db.delete(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<List<ItemInCart>> getCartItems(String? userId) async {
    Database db = await database;
    List<Map<String, dynamic>> cartMaps = await db.rawQuery('''
      SELECT ci.quantity, p.* 
      FROM cart_items ci
      JOIN products p ON ci.productId = p.id
      WHERE ci.userId = ?
    ''', [userId]);
    
    return cartMaps.map((map) => ItemInCart(
      product: Product(
        id: map['id'],
        name: map['name'],
        price: map['price'],
        image: map['image'],
        description: map['description'] ?? '',
        categoryId: map['categoryId'],
      ),
      quantity: map['quantity'],
    )).toList();
  }

  Future<double> getCartTotal(String? userId) async {
    List<ItemInCart> items = await getCartItems(userId);
    double total = 0;
    for (var item in items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  // Order operations
  Future<String> createOrder(String? userId, List<ItemInCart> items, double total) async {
    Database db = await database;
    
    // Generate a unique order ID
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Convert items to JSON string
    String itemsJson = jsonEncode(items.map((item) => item.toJson()).toList());
    
    // Insert the order
    await db.insert('orders', {
      'id': orderId,
      'userId': userId,
      'date': DateTime.now().toIso8601String(),
      'items': itemsJson,
      'totalAmount': total,
      'status': 'Processing', // Default status
    });
    
    return orderId; // Return the orderId for status updates
  }

  Future<List<Order>> getOrderHistory(String? userId) async {
    Database db = await database;
    List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    
    return orderMaps.map((map) {
      // Parse items from JSON string
      List<dynamic> itemsJson = jsonDecode(map['items']);
      List<ItemInCart> items = itemsJson.map((item) => ItemInCart.fromJson(item)).toList();
      
      return Order(
        id: map['id'],
        date: DateTime.parse(map['date']),
        items: items,
        totalAmount: map['totalAmount'],
        status: map['status'],
        userId: map['userId'],
      );
    }).toList();
  }

  Future<int> updateOrderStatus(String orderId, String status) async {
    Database db = await database;
    print('Updating order $orderId to status: $status'); // Debug log
    int result = await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    print('Update result: $result'); // Debug log
    return result;
  }

  Future<void> insertCategories(List<Category> categories) async {
    Database db = await database;
    for (var category in categories) {
      await db.insert('categories', {
        'id': category.id,
        'name': category.name,
      });

      for (var product in category.products) {
        await db.insert('products', {
          'name': product.name,
          'price': product.price,
          'description': product.description,
          'image': product.image,
          'categoryId': category.id,
        });
      }
    }
  }

  Future<void> updateCartItemQuantity(String? userId, int productId, int quantity) async {
    Database db = await database;
    await db.update(
      'cart_items',
      {'quantity': quantity},
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
  }
}