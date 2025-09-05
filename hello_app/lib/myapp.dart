import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myapp/page/player_selection.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // ใช้ GetMaterialApp เพื่อใช้ GetX dialog/snackbar
      debugShowCheckedModeBanner: false,
      title: 'Pokémon Team Builder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PlayerSelection(title: 'Pokémon Team'),
    );
  }
}
