import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import '../screens/create_item_screen.dart';
import '../screens/edit_item_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Item> items = [];
  double dailyPayment = 0.0;
  String currencySymbol = '\$'; // Default currency symbol
  bool isPaid = false; // Added isPaid variable

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchSelectedCurrencySymbol();
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
        builder: (context) => CreateItemScreen(isPaid: isPaid), // Pass isPaid to CreateItemScreen
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
        builder: (context) => EditItemScreen(item: item, isPaid: isPaid), // Pass isPaid to EditItemScreen
      ),
    );
    if (result == false) {
      // Remove the item from the list if it was deleted
      deleteItem(item);
    }
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
    }

    setState(() {
      dailyPayment = total;
    });
  }

  void _fetchSelectedCurrencySymbol() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((snapshot) {
        final userData = snapshot.data();
        if (userData != null && userData['selectedCurrency'] != null) {
          final selectedCurrency = userData['selectedCurrency'];
          currencySymbol = getCurrencySymbol(selectedCurrency);
          setState(() {});
        }
        if (userData != null && userData['isPaid'] != null) {
          isPaid = userData['isPaid']; // Update isPaid value
        }
      });
    }
  }

  String getCurrencySymbol(String currencyCode) {
    final format =
    NumberFormat.simpleCurrency(locale: 'en_US', name: currencyCode);
    final symbol = format.currencySymbol;
    return symbol;
  }

  void navigateToProfileScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          selectedCurrency: currencySymbol,
          isPaid: isPaid, // Pass isPaid to ProfileScreen
        ),
      ),
    );
    if (result != null) {
      // Handle the result if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    items.sort((a, b) {
      final subitemA = a.subitems.firstWhere((subitem) => subitem.subitemType == 'main');
      final subitemB = b.subitems.firstWhere((subitem) => subitem.subitemType == 'main');
      return subitemB.subitemPurchaseDate.compareTo(subitemA.subitemPurchaseDate);
    });

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
                'Daily payment: $currencySymbol${dailyPayment.toStringAsFixed(2)}',
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
                final subitem = items[index].subitems.firstWhere((subitem) => subitem.subitemType == 'main');

                return GestureDetector(
                  onTap: () {
                    navigateToEditItemScreen(context, items[index]);
                  },
                  child: ListTile(
                    title: Text('${subitem.subitemName}'),
                    subtitle: Text('Purchase Date: ${DateFormat.yMd().format(subitem.subitemPurchaseDate)}'),
                    trailing: Text('${currencySymbol}${items[index].calculateDailyPrice().toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navigateToCreateItemScreen(context);
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                iconSize: 32.0, // Задаємо бажаний розмір іконки
                icon: const Icon(Icons.account_circle_sharp),
                onPressed: () {
                  navigateToProfileScreen(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
