import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/utils/app_logger.dart';

part 'hash_store_cart_state.dart';

class HashStoreCartCubit extends Cubit<HashStoreCartState> {
  HashStoreCartCubit() : super(HashStoreCartInitial()){
    AppLogger.d('🟩 HashStoreCartCubit created');
  }

  Future<void> fetchCart() async {
    emit(HashStoreCartLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final cartItems = [
        {
          'title': 'Monster x Hash',
          'description': 'Premium quality leather with foam cushion for maximum comfort.',
          'price': '149.00',
          'productImage': 'assets/hash_store_images/monster_can.png',
          'quantity': 1, // Changed to int
        },
        {
          'title': 'Protein Bar',
          'description': 'Premium quality leather with foam cushion for maximum comfort.',
          'price': '99.00',
          'productImage': 'assets/hash_store_images/protein_bar.png',
          'quantity': 1, // Changed to int
        },
      ];
      emit(HashStoreCartLoaded(cartItems: cartItems));
    } catch (e) {
      emit(HashStoreCartError(message: e.toString()));
    }
  }

  void incrementQuantity(int index) {
    if (state is HashStoreCartLoaded) {
      final current = (state as HashStoreCartLoaded).cartItems
          .map((item) => Map<String, dynamic>.from(item))
          .toList(); // Deep copy

      current[index]['quantity'] = (current[index]['quantity'] as int) + 1;

      emit(HashStoreCartLoaded(cartItems: current));
    }
  }

  void decrementQuantity(int index) {
    if (state is HashStoreCartLoaded) {
      final current = (state as HashStoreCartLoaded).cartItems
          .map((item) => Map<String, dynamic>.from(item))
          .toList(); // Deep copy

      if ((current[index]['quantity'] as int) > 1) {
        current[index]['quantity'] = (current[index]['quantity'] as int) - 1;
        emit(HashStoreCartLoaded(cartItems: current));
      }
    }
  }

}