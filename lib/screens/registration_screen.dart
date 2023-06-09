import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Додано імпорт для Firestore
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/currency_selection_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String databasePath = '';

  @override
  void initState() {
    super.initState();
    getDatabasePath();
  }

  void getDatabasePath() async {
    String databasesPath = await getDatabasesPath();
    setState(() {
      databasePath = join(databasesPath, 'items.db');
    });
  }

  void createUserDocument(User user) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'email': user.email,
      'userId': user.uid, // Додано поле "userId" зі значенням користувача
      // Додайте інші дані про користувача, які вам потрібні
    })
        .then((value) {
      print('Запис про користувача створено успішно');
    })
        .catchError((error) {
      print('Помилка при створенні запису про користувача: $error');
    });
  }

  void registerUser(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      print('Успішна реєстрація. User ID: ${user?.uid}');

      createUserDocument(user!); // Створення запису про користувача у Firestore

      navigateToCurrencySelectionScreen(context);
    } catch (e) {
      print('Помилка реєстрації: $e');
    }
  }

  void navigateToCurrencySelectionScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CurrencySelectionScreen()),
    );
  }

  void navigateToLoginScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionDuration: Duration(seconds: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                  ),
                  SizedBox(height: 32.0),
                  ElevatedButton(
                    onPressed: () => registerUser(context),
                    child: Text('Register'),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => navigateToLoginScreen(context),
                child: Padding(
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
