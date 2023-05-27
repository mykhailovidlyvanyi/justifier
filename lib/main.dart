import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/registration_screen.dart';
import '../app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String databasesPath = await getDatabasesPath();
  String dbPath = join(databasesPath, 'items.db');

  print('Шлях до бази даних: $dbPath');

  runApp(MyApp(
    databasePath: dbPath,
  ));
}