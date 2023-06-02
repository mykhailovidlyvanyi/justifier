import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import '../screens/create_item_screen.dart';
import '../screens/edit_item_screen.dart';
import '../screens/registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Item> items = [];
  double dailyPayment = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('userId', isEqualTo: userId)
        .get();

    final itemList = snapshot.docs.map((doc) => Item.fromMap(doc.data())).toList();

    setState(() {
      items = itemList;
    });

    calculateDailyPayment();
  }

  void addItem(Item item) {
    setState(() {
      items.add(item);
    });
    calculateDailyPayment();
  }

  void deleteItem(Item item) {
    setState(() {
      items.remove(item);
    });
    calculateDailyPayment();
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void navigateToCreateItemScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateItemScreen(),
      ),
    );
    if (result != null) {
      addItem(result);
    }
  }

  Future<void> navigateToEditItemScreen(BuildContext context, Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItemScreen(item: item),
      ),
    );
    if (result != null) {
      updateItem(result);
    }
  }

  void updateItem(Item updatedItem) {
    setState(() {
      final index = items.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        items[index] = updatedItem;
      }
    });
    calculateDailyPayment();
  }

  void calculateDailyPayment() {
    double total = 0.0;

    for (var item in items) {
      double roundedDailyItemPrice =
      double.parse(item.calculateDailyPrice().toStringAsFixed(2));
      total += roundedDailyItemPrice;
      print(total);
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
              child: const Text('Justifier'),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Daily payment: \$${dailyPayment.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14.0),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    navigateToEditItemScreen(context, items[index]);
                  },
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
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
