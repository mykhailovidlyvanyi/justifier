import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/login_screen.dart';
import '../screens/currency_selection_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void createUserDocument(User user) {
    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'userId': user.uid,
      'creationTime': DateTime.now(), // Додайте поле Creation date з поточною датою
      'expirationTime': DateTime.now(), // Додайте поле Expiration date зі значенням null
      'isPaid': false, // Додайте поле Is paid зі значенням "no"
    }).then((value) {
      debugPrint('Запис про користувача створено успішно');
    }).catchError((error) {
      debugPrint('Помилка при створенні запису про користувача: $error');
    });
  }

  Future<void> registerUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (!isEmailValid(email)) {
      showErrorMessage(
        context,
        'Registration Error',
        'Invalid email format. Please enter a valid email address.',
      );
      return;
    }

    if (isRestrictedDomain(email)) {
      showErrorMessage(
        context,
        'Registration Error',
        'Registration is not allowed for this domain.',
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      User? user = userCredential.user;
      debugPrint('Успішна реєстрація. User ID: ${user?.uid}');

      if (user == null) return;

      createUserDocument(user);
      navigateToCurrencySelectionScreen(context);
    } catch (e) {
      if (!mounted) return;

      handleRegistrationError(context, e);
    }
  }

  bool isEmailValid(String email) {
    return RegExp(r'^[\w-]+(\.[\w-]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool isRestrictedDomain(String email) {
    return email.endsWith('.ru') || email.endsWith('.by');
  }

  void handleRegistrationError(BuildContext context, dynamic error) {
    if (error is FirebaseAuthException) {
      if (error.code == 'email-already-in-use') {
        debugPrint('Registration Error: User with this email already exists.');
        showErrorMessage(context, 'Registration Error', 'User with this email already exists.');
      } else if (error.code == 'weak-password') {
        debugPrint('Registration Error: Invalid password used.');
        showErrorMessage(context, 'Registration Error', 'Invalid password. Please choose a stronger password.');
      } else if (error.code == 'invalid-email') {
        debugPrint('Invalid email address.');
        showErrorMessage(context, 'Registration Error', 'Invalid email format. Please enter a valid email address.');
      } else {
        debugPrint('Помилка реєстрації: $error');
        showErrorMessage(context, 'Registration Error', 'An error occurred during registration.');
      }
    } else {
      debugPrint('Помилка реєстрації: $error');
      showErrorMessage(context, 'Registration Error', 'An error occurred during registration.');
    }
  }

  void navigateToCurrencySelectionScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CurrencySelectionScreen()),
    );
  }

  void navigateToLoginScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
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
        title: const Text('Registration'),
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
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                  ),
                  const SizedBox(height: 32.0),
                  ElevatedButton(
                    onPressed: registerUser,
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => navigateToLoginScreen(context),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Already have an account? Sign in here.',
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
