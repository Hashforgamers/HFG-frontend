import 'dart:convert';

class ExtraServiceItem {
  final int categoryId;
  final int itemId;
  final int quantity;

  ExtraServiceItem({
    required this.categoryId,
    required this.itemId,
    required this.quantity,
  });

  factory ExtraServiceItem.fromJson(Map<String, dynamic> json) {
    return ExtraServiceItem(
      categoryId: json['category_id'] ?? 0,
      itemId: json['item_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'item_id': itemId,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return 'ExtraServiceItem(categoryId: $categoryId, itemId: $itemId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtraServiceItem &&
        other.categoryId == categoryId &&
        other.itemId == itemId &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return categoryId.hashCode ^ itemId.hashCode ^ quantity.hashCode;
  }
}

class ExtraServicesModel {
  final List<ExtraServiceItem> items;

  ExtraServicesModel({
    required this.items,
  });

  factory ExtraServicesModel.fromJson(List<dynamic> json) {
    return ExtraServicesModel(
      items: json.map((item) => ExtraServiceItem.fromJson(item)).toList(),
    );
  }

  factory ExtraServicesModel.fromJsonString(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return ExtraServicesModel.fromJson(jsonList);
  }

  List<Map<String, dynamic>> toJson() {
    return items.map((item) => item.toJson()).toList();
  }

  String toJsonString() {
    return json.encode(toJson());
  }

  @override
  String toString() {
    return 'ExtraServicesModel(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtraServicesModel && other.items == items;
  }

  @override
  int get hashCode => items.hashCode;
}
