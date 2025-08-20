class CategoriesModel {
  String description;
  int id;
  String name;

  CategoriesModel({
    required this.description,
    required this.id,
    required this.name,
  });

  factory CategoriesModel.fromJson(Map<String, dynamic> json) {
    return CategoriesModel(
      description: json['description'],
      id: json['id'],
      name: json['name'],
    );
  }
}
