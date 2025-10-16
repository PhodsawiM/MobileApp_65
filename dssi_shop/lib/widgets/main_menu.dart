import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import '../screens/home/product_list_screen.dart';
import '../screens/home/cart_screen.dart';
import '../screens/auth/login_screen.dart';
import '../providers/user_provider.dart';
import '../screens/profile.dart';

class MainMenu extends StatefulWidget {
  final PocketBase pb;
  const MainMenu({Key? key, required this.pb}) : super(key: key);

  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ProductListScreen(pb: widget.pb), // 🏠 Home
      CartScreen(), // 🛒 Cart
      // Scaffold(
      //   appBar: AppBar(
      //     title: const Text('Profile'),
      //     actions: [
      //       IconButton(
      //         icon: Icon(Icons.logout),
      //         tooltip: 'Logout',
      //         onPressed: () {
      //           Provider.of<UserProvider>(context, listen: false).logout();
      //         },
      //       )
      //     ],
      //   ),
      //   body: Center(
      //       child: Consumer<UserProvider>(
      //     builder: (context, user, child) {
      //       // แก้ไข: ใช้ getDataValue เพื่อดึงค่า email จาก RecordModel
      //       final userEmail = user.user?.getDataValue<String>('email') ?? 'Guest';
      //       return Text(
      //         'Welcome, $userEmail!',
      //         style: TextStyle(fontSize: 18),
      //       );
      //     },
      //   )),
      // ),
      ProfileScreen(), // 👤 Profile
    ];
  }

  void _onTap(int index) {
    setState(() {
        _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

