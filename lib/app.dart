import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class MyApp extends StatelessWidget {
  final String databasePath;

  const MyApp({Key? key, required this.databasePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Justifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(databasePath: databasePath),
    );
  }
}