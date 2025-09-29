import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/product_list.dart';
// import 'pages/reviews.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "E-Commerce Shop",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Initial route
      home: const MainPage(),
      // Optional: named routes
      routes: {
        '/products': (context) => const RealTimeListPage(),
        // '/reviews': (context) => const ReviewsPage(),
      },
    );
  }
}

/// This page handles bottom navigation and page switching
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // List of pages
  final List<Widget> _pages = [
    const HomePage(),
    const RealTimeListPage(),
    // const ReviewsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Switch page
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Products',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.reviews),
          //   label: 'Reviews',
          // ),
        ],
      ),
    );
  }
}
