class FoodMenuModel {
  String? description;
  int? id;
  List<FoodItem>? menus;
  String? name;

  FoodMenuModel({this.description, this.id, this.menus, this.name});

  factory FoodMenuModel.fromJson(Map<String, dynamic> json) => FoodMenuModel(
    description: json['description'],
    id: json['id'],
    menus: json['menus'] != null 
        ? (json['menus'] as List<dynamic>)
            .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : null,
    name: json['name'],
  );

  Map<String, dynamic> toJson() => {
    'description': description,
    'id': id,
    'menus': menus?.map((e) => e.toJson()).toList(),
    'name': name,
  };
}

class FoodItem {
  String? description;
  int? id;
  String? imageUrl;
  String? name;
  double? price;

  FoodItem({this.description, this.id, this.imageUrl, this.name, this.price});

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    description: json['description'],
    id: json['id'],
    imageUrl: json['image_url'],
    name: json['name'],
    price: json['price'],
  );

  Map<String, dynamic> toJson() => {
    'description': description,
    'id': id,
    'image_url': imageUrl,
    'name': name,
    'price': price,
  };
}
