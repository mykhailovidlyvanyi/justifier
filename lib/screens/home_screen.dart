import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/item.dart';
import '../screens/create_item_screen.dart';

class HomeScreen extends StatefulWidget {
  final String databasePath;

  const HomeScreen({Key? key, required this.databasePath}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Item> items = [];
  late Database database;
  late String path;
  double dailyPayment = 0.0;

  Future<void> _initializeDatabase() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'items.db');

    database = await openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT, purchasePrice REAL, purchaseDate TEXT)');
        });

    List<Map<String, dynamic>> rows = await database.query('items');
    List<Item> itemList = [];
    for (var row in rows) {
      itemList.add(Item.fromMap(row));
    }

    setState(() {
      items = itemList;
    });
    path = dbPath;
    calculateDailyPayment();
  }

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  void addItem(Item item) {
    setState(() {
      items.add(item);
    });
    calculateDailyPayment();
  }

  void deleteItem(Item item) async {
    if (item != null) {
      final databasePath = await getDatabasesPath();
      final dbPath = join(databasePath, 'items.db');

      final database = await openDatabase(dbPath, version: 1);
      print(item.id);
      await database.delete('items', where: 'id = ?', whereArgs: [item.id]);
      await database.close();

      _initializeDatabase();

      setState(() {
        items.remove(item);
      });
      calculateDailyPayment();
    }
  }

  void navigateToCreateItemScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateItemScreen(database: database),
      ),
    );
    if (result != null) {
      addItem(result);
    }
  }

  Future<void> calculateDailyPayment() async {
    double total = 0.0;

    for (var item in items) {
      double roundedDailyItemPrice =
      double.parse(item.calculateDailyPrice().toStringAsFixed(2));
      total += roundedDailyItemPrice;
    }

    setState(() {
      dailyPayment = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    items.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text('Justifier'),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Daily payment: \$${dailyPayment.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14.0),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onDoubleTap: () {
                    deleteItem(items[index]);
                  },
                  child: ListTile(
                    title: Text(items[index].name),
                    subtitle: Text(
                        'Purchase Date: ${DateFormat.yMd().format(items[index].purchaseDate)}'),
                    trailing: Text(
                        '\$${items[index].calculateDailyPrice().toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      persistentFooterButtons: [
        Center(
          child: FloatingActionButton(
            onPressed: () {
              navigateToCreateItemScreen(context);
            },
            child: Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
