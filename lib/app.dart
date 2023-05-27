import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/home_screen.dart';
import 'screens/registration_screen.dart';

class MyApp extends StatefulWidget {
  final String databasePath;

  const MyApp({required this.databasePath});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late User? currentUser;

  @override
  void initState() {
    super.initState();
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    setState(() {
      currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: currentUser != null ? HomeScreen(databasePath: widget.databasePath) : RegistrationScreen(),
      routes: {
        '/registration': (context) => RegistrationScreen(),
        '/home': (context) => HomeScreen(databasePath: widget.databasePath),
      },
    );
  }
}
