import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProvider with ChangeNotifier {
  final PocketBase pb;
  RecordModel? _user;

  UserProvider({required this.pb}) {
    _loadSession();

    pb.authStore.onChange.listen((_) async {
      _user = pb.authStore.model;
      await _saveSession();
      notifyListeners();
    });
  }

  bool get isLoggedIn => pb.authStore.isValid;
  RecordModel? get user => _user;

  Future<void> login(String email, String password) async {
    await pb.collection('users').authWithPassword(email, password);
  }

  Future<void> signup(String email, String password, String passwordConfirm) async {
    await pb.collection('users').create(body: {
      'email': email,
      'password': password,
      'passwordConfirm': passwordConfirm,
    });
    await login(email, password);
  }

  void logout() async {
    pb.authStore.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_auth');
    notifyListeners();
  }

  /// ✅ บันทึก session แบบ manual
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'token': pb.authStore.token,
      'model': pb.authStore.model?.toJson(),
    };
    await prefs.setString('pb_auth', jsonEncode(data));
  }

  /// ✅ โหลด session กลับเข้ามา
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('pb_auth');

    if (jsonString != null) {
      final data = jsonDecode(jsonString);

      final token = data['token'] as String?;
      final modelData = data['model'] as Map<String, dynamic>?;

      if (token != null && modelData != null) {
        pb.authStore.save(token, RecordModel.fromJson(modelData));
        _user = pb.authStore.model;
        notifyListeners();
      }
    }
  }
}
