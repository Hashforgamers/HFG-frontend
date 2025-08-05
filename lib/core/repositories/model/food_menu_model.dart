class FoodMenuModel {
  String description;
  int id;
  String name;
  double price;

  FoodMenuModel({
    required this.description,
    required this.id,
    required this.name,
    required this.price,
  });

  factory FoodMenuModel.fromJson(Map<String, dynamic> json) {
    return FoodMenuModel(
      description: json['description'],
      id: json['id'],
      name: json['name'],
      price: json['price'],
    );
  }
}
