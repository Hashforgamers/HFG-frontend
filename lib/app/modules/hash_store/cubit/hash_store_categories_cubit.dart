import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'hash_store_categories_state.dart';

class HashStoreCategoriesCubit extends Cubit<HashStoreCategoriesState> {
  HashStoreCategoriesCubit() : super(HashStoreCategoriesInitial());

  Future<void> fetchCategories() async {
    emit(HashStoreCategoriesLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      final categories = [
        {
          'title': 'Drinks',
          'productImage': 'assets/hash_store_images/monster_can.png',
        },
        {
          'title': 'Protein Bars',
          'productImage': 'assets/hash_store_images/protein_bar.png',
        },
        {
          'title': 'Headphones',
          'productImage': null,
        },
        {
          'title': 'Mouse Pad',
          'productImage': 'assets/hash_store_images/mouse_pad.png',
        },
        {
          'title': 'Merchandise',
          'productImage': null,
        },

      ];
      emit(HashStoreCategoriesLoaded(categories: categories));
    } catch (e) {
      emit(HashStoreCategoriesError(message: e.toString()));
    }
  }
}
