import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/home_screen.dart';
import '../models/item.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();

  late String itemName;
  late double purchasePrice;
  late DateTime selectedDate;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    itemName = widget.item.name;
    purchasePrice = widget.item.purchasePrice;
    selectedDate = widget.item.purchaseDate;
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _priceController.text = purchasePrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final updatedItem = Item(
        id: widget.item.id,
        name: itemName,
        purchasePrice: purchasePrice,
        purchaseDate: selectedDate,
        userId: currentUserId,
      );

      try {
        final itemRef =
        FirebaseFirestore.instance.collection('items').doc(widget.item.id.toString());
        final currentItemSnapshot = await itemRef.get();
        final currentItemUserId = currentItemSnapshot['userId'];

        if (currentItemUserId == currentUserId) {
          await itemRef.update(updatedItem.toMap());
          Navigator.pop(context, updatedItem);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Access Denied'),
              content: Text('You do not have permission to edit this item.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          );
        }
      } catch (error) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to update item.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      }
    }
  }

  void _deleteItem(BuildContext context) async {
    try {
      final itemRef =
          FirebaseFirestore.instance.collection('items').doc(widget.item.id.toString());
      final currentItemSnapshot = await itemRef.get();
      final currentItemUserId = currentItemSnapshot['userId'];

      if (currentItemUserId == currentUserId) {
        await itemRef.delete();
        Navigator.pop(context, false);
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Access Denied'),
            content: Text('You do not have permission to delete this item.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to delete item.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
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
        title: Text('Edit Item'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Confirm Deletion'),
                  content: Text('Are you sure you want to delete this item?'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                    ),
                    TextButton(
                      child: Text(
                        'Delete',
                         style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent), // Встановити прозорий фоновий колір кнопки
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _deleteItem(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                initialValue: itemName,
                decoration: InputDecoration(
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
                  itemName = value!;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Purchase Price',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a purchase price';
                  }
                  final price = double.tryParse(value.replaceAll(',', '.'));
                  if (price == null || price <= 0) {
                    return 'Please enter a valid purchase price';
                  }
                  return null;
                },
                onSaved: (value) {
                  final parsedValue = value!.replaceAll(',', '.');
                  purchasePrice = double.parse(parsedValue);
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
                  DateFormat.yMd().format(selectedDate),
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
