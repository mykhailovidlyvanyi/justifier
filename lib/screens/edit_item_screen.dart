import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/home_screen.dart';
import '../models/item.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;
  final bool isPaid;

  const EditItemScreen({Key? key, required this.isPaid, required this.item}) : super(key: key);

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();

  late String subitemId;
  late String subitemName;
  late double subitemPurchasePrice;
  late DateTime subitemSelectedDate;
  late String subitemType;
  late String currentUserId;
  late bool isPaid;

  List<SubItem> updatedSubitems = [];

  @override
  void initState() {
    super.initState();
    subitemId = widget.item.subitems.firstWhere((subitem) => subitem.subitemType == 'main').subitemId;
    subitemName = widget.item.subitems.firstWhere((subitem) => subitem.subitemType == 'main').subitemName;
    subitemPurchasePrice = widget.item.subitems.firstWhere((subitem) => subitem.subitemType == 'main').subitemPurchasePrice;
    subitemSelectedDate = widget.item.subitems.firstWhere((subitem) => subitem.subitemType == 'main').subitemPurchaseDate;
    subitemType = widget.item.subitems.firstWhere((subitem) => subitem.subitemType == 'main').subitemType;
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _priceController.text = subitemPurchasePrice.toStringAsFixed(2);
    updatedSubitems = List.from(widget.item.subitems);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: subitemSelectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        subitemSelectedDate = pickedDate;
      });
    }
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final updatedMainSubitem = SubItem(
        subitemId: subitemId,
        subitemType: 'main',
        subitemName: subitemName,
        subitemPurchasePrice: subitemPurchasePrice,
        subitemPurchaseDate: subitemSelectedDate,
      );

      final updatedSubitems = [updatedMainSubitem, ...this.updatedSubitems.where((subitem) => subitem.subitemType != 'main').toList()];

      final updatedItem = Item(
        id: widget.item.id,
        subitems: updatedSubitems,
        userId: widget.item.userId,
      );

      try {
        final itemRef = FirebaseFirestore.instance.collection('items').doc(widget.item.id.toString());
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
      final itemRef = FirebaseFirestore.instance.collection('items').doc(widget.item.id.toString());
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

  Future<void> _addSubItem(BuildContext context) async {
    String newSubitemName = '';
    double newSubitemPurchasePrice = 0.0;
    DateTime newSubitemSelectedDate = DateTime.now();
    String newSubitemType = 'upgrade';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Subitem'),
          content: SingleChildScrollView(
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Subitem Name'),
                    onChanged: (value) {
                      newSubitemName = value;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Subitem Purchase Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      newSubitemPurchasePrice = double.parse(value);
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          newSubitemSelectedDate = pickedDate;
                        });
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        Text(
                          newSubitemSelectedDate == null
                              ? 'Select Date'
                              : DateFormat('MM/dd/yyyy').format(newSubitemSelectedDate),
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                  DropdownButtonFormField(
                    value: newSubitemType,
                    decoration: InputDecoration(labelText: 'Subitem Type'),
                    items: [
                      DropdownMenuItem(
                        value: 'upgrade',
                        child: Text('Upgrade'),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('Maintenance'),
                      ),
                    ],
                    onChanged: (value) {
                      newSubitemType = value.toString();
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                setState(() {
                  final newSubitem = SubItem(
                    subitemId: DateTime.now().toString(),
                    subitemType: newSubitemType,
                    subitemName: newSubitemName,
                    subitemPurchasePrice: newSubitemPurchasePrice,
                    subitemPurchaseDate: newSubitemSelectedDate,
                  );
                  updatedSubitems.insert(0, newSubitem);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Item Name'),
                  initialValue: subitemName,
                  textCapitalization: TextCapitalization.sentences,
                  onSaved: (value) {
                    subitemName = value!;
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter an item name.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Purchase Price'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  onSaved: (value) {
                    subitemPurchasePrice = double.parse(value!);
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a purchase price.';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.0),
                SizedBox(height: 10.0),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    subitemSelectedDate == null
                        ? 'Select Date'
                        : DateFormat.yMd().format(subitemSelectedDate!),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: updatedSubitems.length,
                  itemBuilder: (ctx, index) {
                    final subitem = updatedSubitems[index];
                    if (subitem.subitemType == "main") {
                      return SizedBox.shrink(); // Не включати subitem з типом "main" до списку
                    }
                    return ListTile(
                      title: Text(subitem.subitemName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Purchase Price: \$${subitem.subitemPurchasePrice.toStringAsFixed(2)}'),
                          Text('Purchase Date: ${DateFormat.yMd().format(subitem.subitemPurchaseDate)}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            updatedSubitems.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: widget.isPaid ? () => _addSubItem(context) : null,
                ),
              ],
            ),
          ),
        ),
      ),
        bottomNavigationBar: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
            onPressed: () {
              _submitForm(context);
            },
                child: Text('Save'),
            ),
        ),
    );
  }
}
