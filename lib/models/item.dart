import 'package:intl/intl.dart';

class Item {
  final String? id;
  final String name;
  final double purchasePrice;
  final DateTime purchaseDate;
  String userId; // Додано поле userId

  Item({
    this.id,
    required this.name,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.userId,
  });

  Item.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        purchasePrice = map['purchasePrice'],
        purchaseDate = DateTime.parse(map['purchaseDate']),
        userId = map['userId'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'userId': userId,
    };
  }

  double calculateDailyPrice() {
    final now = DateTime.now();
    final daysSincePurchase = now.difference(purchaseDate).inDays;
    return purchasePrice / (daysSincePurchase + 1);
  }
}

