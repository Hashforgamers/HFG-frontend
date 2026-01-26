import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'hash_store_orders_state.dart';

class HashStoreOrdersCubit extends Cubit<HashStoreOrdersState> {
  HashStoreOrdersCubit() : super(HashStoreOrdersInitial());

  Future<void> fetchOrders() async {
    emit(HashStoreOrdersLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final orders = [
        {
          'title': 'Monster x Hash',
          'price': '149.00',
          'dateOfPurchase': '25/10/25',
          'paymentMode': 'Online',
          'productImage': 'assets/hash_store_images/monster_can.png',
        },
        {
          'title': 'Protein Bar',
          'price': '99.00',
          'dateOfPurchase': '24/10/25',
          'paymentMode': 'Online',
          'productImage': 'assets/hash_store_images/protein_bar.png',
        },
        {
          'title': 'Mouse Pad',
          'price': '149.00',
          'dateOfPurchase': '23/10/25',
          'paymentMode': 'Online',
          'productImage': 'assets/hash_store_images/mouse_pad.png',
        },
        {
          'title': 'Headphones',
          'price': '2499.00',
          'dateOfPurchase': '22/10/25',
          'paymentMode': 'Online',
          'productImage': 'assets/hash_store_images/monster_can.png',
        },

      ];
      emit(HashStoreOrdersLoaded(orders: orders));
    } catch (e) {
      emit(HashStoreOrdersError(message: e.toString()));
    }
  }
}