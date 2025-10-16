import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'signup_screen.dart'; // Import SignUpScreen

class LoginScreen extends StatefulWidget {
  // แก้ไข: นำ const ออกจาก constructor
  LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        setState(() => errorText = "Invalid email or password.");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(errorText!, style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ),
            SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                  ),
            SizedBox(height: 8),
            // --- ปุ่มสำหรับนำทางไปหน้าสมัครสมาชิก ---
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}

