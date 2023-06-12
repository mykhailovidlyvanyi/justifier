import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'userId': user.uid,
      'creationTime': DateTime.now(), // Додайте поле Creation date з поточною датою
      'expirationTime': DateTime.now(), // Додайте поле Expiration date зі значенням null
      'isPaid': false, // Додайте поле Is paid зі значенням "no"
    }).then((value) {
      print('Запис про користувача створено успішно');
    }).catchError((error) {
      print('Помилка при створенні запису про користувача: $error');
    });
  }

  void registerUser(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (!isEmailValid(email)) {
      showErrorMessage(context, 'Registration Error', 'Invalid email format. Please enter a valid email address.');
      return;
    }

    if (isRestrictedDomain(email)) {
      showErrorMessage(context, 'Registration Error', 'Registration is not allowed for this domain.');
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      print('Успішна реєстрація. User ID: ${user?.uid}');

      createUserDocument(user!);

      navigateToCurrencySelectionScreen(context);
    } catch (e) {
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
        print('Помилка реєстрації: Користувач з таким імейлом вже існує');
        showErrorMessage(context, 'Registration Error', 'User with this email already exists.');
      } else if (error.code == 'weak-password') {
        print('Помилка реєстрації: Використаний непідходящий пароль');
        showErrorMessage(context, 'Registration Error', 'Invalid password. Please choose a stronger password.');
      } else if (error.code == 'invalid-email') {
        print('Помилка реєстрації: Введений неправильний формат електронної пошти');
        showErrorMessage(context, 'Registration Error', 'Invalid email format. Please enter a valid email address.');
      } else {
        print('Помилка реєстрації: $error');
        showErrorMessage(context, 'Registration Error', 'An error occurred during registration.');
      }
    } else {
      print('Помилка реєстрації: $error');
      showErrorMessage(context, 'Registration Error', 'An error occurred during registration.');
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

  void showErrorMessage(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
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
