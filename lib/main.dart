import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_masters/data_manager.dart';
import 'package:coffee_masters/pages/menu.dart';
import 'package:coffee_masters/pages/order.dart';
import 'package:coffee_masters/pages/profile_page.dart';
import 'package:coffee_masters/pages/login_page.dart';
import 'package:coffee_masters/pages/register_page.dart';
import 'package:coffee_masters/pages/orders_history_page.dart';
import 'package:coffee_masters/pages/offers_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';

// Global reference to data manager for easy access
late DataManager globalDataManager;

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite based on platform
  if (kIsWeb) {
    // For web platform
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isAndroid || Platform.isIOS) {
    // For mobile platforms, use the default sqflite implementation
    // No need to set databaseFactory as it uses the default one
  } else {
    // For desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize global data manager
  globalDataManager = DataManager();
  
  // Wait for initialization to complete
  while (!globalDataManager.isInitialized) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

void main() async {
  await initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (context) => DataManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Coffee Masters',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<bool>(
        future: Provider.of<DataManager>(context, listen: false).isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.data == true) {
            return const MainScreen();
          } else {
            return LoginPage(
              dataManager: Provider.of<DataManager>(context, listen: false),
              onLogin: () {
                Navigator.pushReplacementNamed(context, '/main');
              },
            );
          }
        },
      ),
      routes: {
        '/main': (context) => const MainScreen(),
        '/login': (context) => LoginPage(
          dataManager: Provider.of<DataManager>(context, listen: false),
          onLogin: () {
            Navigator.pushReplacementNamed(context, '/main');
          },
        ),
        '/register': (context) => RegisterPage(
          dataManager: Provider.of<DataManager>(context, listen: false),
          onRegister: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        '/profile': (context) => ProfilePage(
          dataManager: Provider.of<DataManager>(context, listen: false),
          onLogout: () {
            Provider.of<DataManager>(context, listen: false).logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const OffersPage(),
    MenuPage(dataManager: Provider.of<DataManager>(navigatorKey.currentContext!, listen: false)),
    OrderPage(dataManager: Provider.of<DataManager>(navigatorKey.currentContext!, listen: false)),
    OrdersHistoryPage(dataManager: Provider.of<DataManager>(navigatorKey.currentContext!, listen: false)),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Masters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Orders',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.brown[200],
        onTap: _onItemTapped,
      ),
    );
  }
}

// Add this at the top of the file with other imports
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
