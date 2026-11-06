import 'package:equatable/equatable.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/core/utils/safe_emit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'hash_store_orders_state.dart';

class HashStoreOrdersCubit extends Cubit<HashStoreOrdersState>
    with SafeEmit<HashStoreOrdersState> {
  HashStoreOrdersCubit() : super(HashStoreOrdersInitial());

  // shortcut: first 50 orders only, add paging when someone has more.
  Future<void> fetchOrders() async {
    if (state is! HashStoreOrdersLoaded) emit(HashStoreOrdersLoading());
    try {
      final orders = await MedusaStoreService.instance.orders(limit: 50);
      emit(HashStoreOrdersLoaded(orders: orders));
    } catch (e) {
      emit(HashStoreOrdersError(message: e.toString()));
    }
  }
}
