import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../models/currency_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  List<CurrencyInfo> currencyInfoList = currencyList;
  List<CurrencyInfo> filteredCurrencyList = [];

  CurrencyInfo? selectedCurrency;

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance; // Додано оголошення FirebaseAuth

  @override
  void initState() {
    super.initState();
    filteredCurrencyList = currencyInfoList;
  }

  TextStyle _getItemTextStyle(bool isSelected) {
    if (isSelected) {
      return const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );
    }
    return const TextStyle();
  }

  void filterCurrencyList(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredCurrencyList = currencyInfoList
            .where((currency) => currency.name.toLowerCase().contains(query.toLowerCase()) || currency.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } else {
      setState(() {
        filteredCurrencyList = currencyInfoList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
      ),
      body: GestureDetector(
        onTap: () {
          // Закриття клавіатури та зняття фокусу з поля пошуку при натисканні будь-де, окрім поля вводу
          if (!searchFocusNode.hasPrimaryFocus) {
            searchFocusNode.unfocus();
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FocusScope(
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onTap: () {
                    // Активація поля пошуку при натисканні
                    searchFocusNode.requestFocus();
                  },
                  textCapitalization: TextCapitalization.sentences, // капіталізація поля вводу
                  onChanged: (value) {
                    filterCurrencyList(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Search Currency',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCurrencyList.length,
                itemBuilder: (context, index) {
                  final currencyInfo = filteredCurrencyList[index];
                  final bool isSelected = currencyInfo == selectedCurrency;
                  return ListTile(
                    title: Text(
                      '${currencyInfo.symbol} ${currencyInfo.name} (${currencyInfo.code})',
                      style: _getItemTextStyle(isSelected),
                    ),
                    onTap: () {
                      if (currencyInfo.code == 'RUB' || currencyInfo.code == 'BYN') {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Помилка'),
                              content: const Text('Дана валюта може бути вибрана виключно після виплати усіх репарацій.'),
                              actions: [
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        setState(() {
                          selectedCurrency = currencyInfo;
                        });
                      }
                    },
                    tileColor: isSelected ? Colors.cyan : null,
                    selected: isSelected,
                    selectedTileColor: Colors.cyan,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (selectedCurrency != null && (selectedCurrency!.code == 'RUB' || selectedCurrency!.code == 'BYN')) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Помилка'),
                    content: const Text('Неможливо зберегти російський рубль або білоруський рубль.'),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              navigateToHomeScreen(context);
            }
          },
          child: const Text('Save'),
        ),
      ),
    );
  }

  void navigateToHomeScreen(BuildContext context) {
    if (selectedCurrency != null) {
      saveSelectedCurrency(selectedCurrency!.code);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Видаляє всі попередні маршрути зі стеку
    );
  }

  void saveSelectedCurrency(String currencyCode) {
    User? user = _auth.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'selectedCurrency': currencyCode})
          .then((value) {
        debugPrint('Інформацію про вибрану валюту оновлено успішно');
      })
          .catchError((error) {
        debugPrint('Помилка під час оновлення інформації про вибрану валюту: $error');
      });
    }
  }
}
