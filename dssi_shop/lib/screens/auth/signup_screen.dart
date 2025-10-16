import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (passwordController.text != passwordConfirmController.text) {
      setState(() {
        errorText = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.signup(
        emailController.text.trim(),
        passwordController.text.trim(),
        passwordConfirmController.text.trim(),
      );
    } catch (e) {
      // แก้ไข: แสดง error ที่ละเอียดขึ้นจาก PocketBase
      // และพิมพ์ error ทั้งหมดออกมาใน console เพื่อการดีบัก
      print('Signup Error: $e');
      if (mounted) {
        // แสดงข้อความ error ที่เฉพาะเจาะจงมากขึ้นบน UI
        setState(() => errorText = 'Signup failed: ${e.toString()}');
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
    passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
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
            SizedBox(height: 10),
            TextField(
              controller: passwordConfirmController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
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
                    onPressed: _signup,
                    child: Text('Sign Up'),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                  ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}

