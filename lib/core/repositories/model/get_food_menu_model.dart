import 'package:hash/core/repositories/model/food_menu_model.dart';

class GetFoodMenuModel {
  final List<FoodMenuModel> categories;

  GetFoodMenuModel({required this.categories});

  factory GetFoodMenuModel.fromJson(Map<String, dynamic> json) =>
      GetFoodMenuModel(
        categories: (json['categories'] as List<dynamic>)
            .map((e) => FoodMenuModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
