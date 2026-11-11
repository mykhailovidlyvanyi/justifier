class SubItem {
  final String subitemId;
  final String subitemType;
  final String subitemName;
  final double subitemPurchasePrice;
  final DateTime subitemPurchaseDate;

  SubItem({
    required this.subitemId,
    required this.subitemType,
    required this.subitemName,
    required this.subitemPurchasePrice,
    required this.subitemPurchaseDate,
  });

}

class Item {
  final String? id;
  final String userId;
  List<SubItem> subitems;

  Item({
    this.id,
    required this.userId,
    this.subitems = const [],
  });

  Item.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        userId = map['userId'],
        subitems = (map['subitems'] as List<dynamic>?)
            ?.map((subitemMap) => SubItem(
          subitemId: subitemMap['subitemId'],
          subitemType: subitemMap['subitemType'],
          subitemName: subitemMap['subitemName'],
          subitemPurchasePrice: subitemMap['subitemPurchasePrice'].toDouble(),
          subitemPurchaseDate:
          DateTime.parse(subitemMap['subitemPurchaseDate']),
        ))
            .toList() ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subitems': subitems.map((subitem) => {
        'subitemId': subitem.subitemId,
        'subitemType': subitem.subitemType,
        'subitemName': subitem.subitemName,
        'subitemPurchasePrice': subitem.subitemPurchasePrice,
        'subitemPurchaseDate':
        subitem.subitemPurchaseDate.toIso8601String(),
      }).toList(),
    };
  }

  double calculateDailyPrice() {
    final now = DateTime.now();
    double totalPrice = 0.0;

    for (final subitem in subitems) {
      final daysSincePurchase = now.difference(subitem.subitemPurchaseDate).inDays;
      totalPrice += subitem.subitemPurchasePrice / (daysSincePurchase + 1);
    }

    return totalPrice;
  }
}
