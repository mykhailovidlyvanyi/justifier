import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/currency_selection_screen.dart'; // Імпорт екрану вибору валюти

class ProfileScreen extends StatefulWidget {
  final String selectedCurrency; // Доданий параметр конструктора

  const ProfileScreen({Key? key, required this.selectedCurrency}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String selectedCurrency; // Видалено ініціалізацію, оскільки валюта передається через конструктор

  @override
  void initState() {
    super.initState();
    selectedCurrency = widget.selectedCurrency; // Отримати валюту з параметра конструктора
  }

  void _navigateToCurrencySelectionScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrencySelectionScreen(),
      ),
    );

    if (result != null) {
      // Оновити вибрану валюту після вибору на екрані вибору валюти
      setState(() {
        selectedCurrency = result;
      });
      _saveSelectedCurrency(result); // Зберегти вибрану валюту
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
          itemCount: 2, // Кількість елементів у списку (2 рядки)
          itemBuilder: (context, index) {
            if (index == 0) {
              // Перший рядок з текстом "Selected Currency" і символом валюти
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
              // Другий рядок з текстом "TBD"
              return ListTile(
                title: Text(
                  'TBD',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              );
            } else {
              return SizedBox(); // Якщо є більше рядків, що необхідно додати, можна використовувати подібний шаблон
            }
          },
          separatorBuilder: (context, index) {
            // Горизонтальна лінія-роздільник між рядками
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
