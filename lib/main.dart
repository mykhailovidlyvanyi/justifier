import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String databasesPath = await getDatabasesPath();
  String dbPath = join(databasesPath, 'items.db');

  print('Шлях до бази даних: $dbPath');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Justifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Justifier'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Item> items = [];
  late Database database;
  late String path;

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
  }

  void deleteItem(Item item) async {
    if (item != null) {
      final databasePath = await getDatabasesPath();
      final dbPath = join(databasePath, 'items.db');

      final database = await openDatabase(dbPath, version: 1);
      print (item.id);
      await database.delete('items', where: 'id = ?', whereArgs: [item.id]);
      await database.close();

      _initializeDatabase();

      setState(() {
        items.remove(item);
      });
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

  @override
  Widget build(BuildContext context) {
    items.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
      ]
    );
  }
}

class CreateItemScreen extends StatefulWidget {
  final Database database;

  const CreateItemScreen({Key? key, required this.database}) : super(key: key);

  @override
  _CreateItemScreenState createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();

  String? itemName;
  double? purchasePrice;
  DateTime? selectedDate;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate() && selectedDate != null) {
      _formKey.currentState!.save();
      final item = Item(
        name: itemName!,
        purchasePrice: purchasePrice!,
        purchaseDate: selectedDate!,
      );

      await widget.database.insert('items', item.toMap());

      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Item'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Item Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
                onSaved: (value) {
                  itemName = value;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Purchase Price',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a purchase price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid purchase price';
                  }
                  return null;
                },
                onSaved: (value) {
                  purchasePrice = double.parse(value!);
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Purchase Date:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : DateFormat.yMd().format(selectedDate!),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _submitForm(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Item {
  final int? id;
  final String name;
  final double purchasePrice;
  final DateTime purchaseDate;

  Item({
    this.id,
    required this.name,
    required this.purchasePrice,
    required this.purchaseDate,
  });

  Item.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        purchasePrice = map['purchasePrice'],
        purchaseDate = DateTime.parse(map['purchaseDate']);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  double calculateDailyPrice() {
    final now = DateTime.now();
    final daysSincePurchase = now.difference(purchaseDate).inDays;
    return purchasePrice / (daysSincePurchase + 1);
  }
}
