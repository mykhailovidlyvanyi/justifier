import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String databasesPath = await getDatabasesPath();
  String dbPath = join(databasesPath, 'items.db');

  print('Шлях до бази даних: $dbPath');

  runApp(MyApp(databasePath: dbPath));
}