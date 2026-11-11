import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp( // Додано MaterialApp
      home: Material(
        child: Center(
          child: Text(
            'Splash Screen',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}