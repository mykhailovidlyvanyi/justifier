import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/item.dart';

class CreateItemScreen extends StatefulWidget {
  final bool isPaid; // Додайте параметр isPaid

  const CreateItemScreen({Key? key, required this.isPaid}) : super(key: key);

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) {
      return;
    }

    _formKey.currentState!.save();

    final itemId = const Uuid().v4();

    final subitem = SubItem(
      subitemId: const Uuid().v4(),
      subitemType: 'main',
      subitemName: itemName!,
      subitemPurchasePrice: double.parse(
        _priceController.text.replaceAll(',', '.'),
      ),
      subitemPurchaseDate: selectedDate!,
    );

    final item = Item(
      id: itemId,
      userId: FirebaseAuth.instance.currentUser!.uid,
      subitems: [subitem],
    );

    try {
      await FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .set(item.toMap());

      if (!mounted) return;

      Navigator.pop(context, item);
    } catch (error) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to save item.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                ),
                textCapitalization: TextCapitalization.sentences, // капіталізація поля вводу
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
                decoration: const InputDecoration(
                  labelText: 'Purchase Price',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a purchase price';
                  }
                  final price = double.tryParse(value.replaceAll(',', '.'));
                  if (price == null || price < 0) {
                    return 'Please enter a valid purchase price';
                  }
                  return null;
                },
                onSaved: (value) {
                  final parsedValue = value?.replaceAll(',', '.');
                  purchasePrice =
                  parsedValue != null ? double.parse(parsedValue) : null;
                },
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Purchase Date:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : DateFormat.yMd().format(selectedDate!),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
