import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home/cart_screen.dart';
import 'widgets/main_menu.dart';
import 'screens/auth/login_screen.dart';
import 'screens/checkout/checkout_screen.dart';

final pb = PocketBase('http://127.0.0.1:8090');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider(pb: pb)),
      ],
      child: MaterialApp(
        title: 'Flutter PocketBase E-commerce',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoggedIn) {
              return MainMenu(pb: pb);
            } else {
              // แก้ไข: ลบ const ออกจากการเรียก LoginScreen()
              return LoginScreen();
            }
          },
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/cart': (context) => CartScreen(),
          '/checkout': (context) => CheckoutScreen(),
        },
      ),
    );
  }
}

