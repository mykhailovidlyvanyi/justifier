import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/currency_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String selectedCurrency;
  final bool isPaid;

  const ProfileScreen({Key? key, required this.isPaid, required this.selectedCurrency}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String selectedCurrency;
  late String accountType;

  @override
  void initState() {
    super.initState();
    selectedCurrency = widget.selectedCurrency;
    accountType = getAccountType(); // Отримати тип облікового запису користувача
  }

  String getAccountType() {
    return widget.isPaid ? 'Pro' : 'Free'; // Визначити тип облікового запису користувача в залежності від isPaid
  }

  void _navigateToCurrencySelectionScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrencySelectionScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        selectedCurrency = result;
      });
      _saveSelectedCurrency(result);
    }
  }

  void _saveSelectedCurrency(String currency) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'selectedCurrency': currency,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: 3,
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: () {
                  _navigateToCurrencySelectionScreen(context);
                },
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Currency:',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            selectedCurrency,
                            style: TextStyle(fontSize: 16.0),
                          ),
                          Icon(Icons.arrow_forward_ios),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else if (index == 1) {
              return ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account type:',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      accountType, // Відображати значення типу облікового запису
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              );
            } else if (index == 2) {
              return ListTile(
                title: Text(
                  'TBD',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              );
            } else {
              return SizedBox();
            }
          },
          separatorBuilder: (context, index) {
            return Divider(
              thickness: 1.0,
              color: Colors.grey,
            );
          },
        ),
      ),
    );
  }
}
