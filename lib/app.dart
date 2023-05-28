import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/home_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

class MyApp extends StatefulWidget {
  final String databasePath;

  const MyApp({required this.databasePath});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkUserExistence();
  }

  Future<void> checkUserExistence() async {
    bool doesUserExist = await checkUserExistenceFirebase();
    setState(() {
      currentUser = doesUserExist ? FirebaseAuth.instance.currentUser : null;
      isLoading = false;
    });
  }

  Future<bool> checkUserExistenceFirebase() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      try {
        await user.reload();
        user = auth.currentUser;

        if (user != null) {
          return true; // Користувач існує в Firebase
        }
      } catch (e) {
        print('Помилка перевірки існування користувача: $e');
      }
    }

    return false; // Користувач не існує в Firebase
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Показати спінер або екран завантаження, поки перевіряється користувач
      return SplashScreen();
    } else {
      return MaterialApp(
        title: 'My App',
        initialRoute: '/',
        routes: {
          '/': (context) => currentUser != null ? HomeScreen(databasePath: widget.databasePath) : LoginScreen(),
          '/registration': (context) => RegistrationScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(databasePath: widget.databasePath),
        },
      );
    }
  }
}
