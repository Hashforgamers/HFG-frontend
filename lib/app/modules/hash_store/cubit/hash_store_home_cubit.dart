import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'hash_store_home_state.dart'; // adjust filename

class HashStoreHomeCubit extends Cubit<HashStoreHomeState> {
  HashStoreHomeCubit() : super(HashStoreHomeInitial());

  Future<void> fetchProducts() async {
    emit(HashStoreHomeLoading());
    try {
      // For now: static mock data
      final products = [
        {
          'title': 'Monster x Hash',
          'description': 'Premium quality leather with foam cushion for maximum comfort.',
          'price': '149.00',
          'backgroundImage': 'assets/hash_store_images/bg_monster_1.jpg',
          'productImage': null,
        },
        {
          'title': 'Monster x Hash',
          'description': 'Premium quality leather with foam cushion for maximum comfort.',
          'price': '149.00',
          'backgroundImage': 'assets/hash_store_images/bg_monster_2.jpg',
          'productImage': null,
        },
        {
          'title': 'Hash Headphones',
          'description': 'Premium quality leather with foam cushion for maximum comfort.',
          'price': null,
          'backgroundImage': 'assets/hash_store_images/bg_headphones.jpg',
          'productImage': null,
        },
      ];

      await Future.delayed(const Duration(milliseconds: 800)); // simulate load
      emit(HashStoreHomeLoaded(products: products));
    } catch (e) {
      emit(HashStoreHomeError(message: e.toString()));
    }
  }
}
