import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home_screen.dart';
import '../screens/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loginUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showErrorMessage(
        context,
        'Login error',
        'Please fill in all fields for successful login.',
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      User? user = userCredential.user;
      debugPrint('Успішний вхід. User ID: ${user?.uid}');

      navigateToHomeScreen(context);
    } catch (e) {
      if (!mounted) return;

      handleLoginError(context, e);
    }
  }

  void handleLoginError(BuildContext context, dynamic error) {
    String errorMessage = 'Login error';

    switch (error.code) {
      case 'invalid-email':
        errorMessage = 'Invalid email address.';
        break;
      case 'user-disabled':
        errorMessage = 'Your account has been disabled.';
        break;
      case 'user-not-found':
        errorMessage = 'Email and password combination not found.';
        break;
      case 'wrong-password':
        errorMessage = 'Email and password combination not found.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many unsuccessful login attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Login operation is not allowed.';
        break;
    }

    showErrorMessage(context, 'Login error', errorMessage);
    debugPrint('Login error: $error');
  }

  void navigateToHomeScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void navigateToRegistrationScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RegistrationScreen(),
        transitionDuration: const Duration(seconds: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  void showErrorMessage(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress, // Встановлення типу клавіатури на електронну адресу
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    keyboardType: TextInputType.visiblePassword, // Встановлення типу клавіатури на видимий пароль
                    obscureText: true,
                  ),
                  const SizedBox(height: 32.0),
                  ElevatedButton(
                    onPressed: loginUser,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => navigateToRegistrationScreen(context),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'New here? Sign up.',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}