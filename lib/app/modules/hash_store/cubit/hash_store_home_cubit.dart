import 'package:equatable/equatable.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/core/utils/safe_emit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'hash_store_home_state.dart';

class HashStoreHomeCubit extends Cubit<HashStoreHomeState>
    with SafeEmit<HashStoreHomeState> {
  HashStoreHomeCubit() : super(const HashStoreHomeState());

  final _store = MedusaStoreService.instance;
  static const _pageSize = 20;

  Future<void> fetchProducts({String? vendorId}) async {
    emit(
      HashStoreHomeState(
        vendorId: vendorId,
        vendors: state.vendors,
        loading: true,
      ),
    );
    try {
      final data = await _store.catalog(limit: _pageSize, vendorId: vendorId);
      final products = _rows(data);
      emit(
        HashStoreHomeState(
          products: products,
          count: (data['count'] as num?)?.toInt() ?? products.length,
          vendorId: vendorId,
          vendors: vendorId == null ? _vendorsOf(products) : state.vendors,
        ),
      );
    } catch (e) {
      emit(
        HashStoreHomeState(
          vendorId: vendorId,
          vendors: state.vendors,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final base = state;
    emit(_copy(base, loadingMore: true));
    try {
      final data = await _store.catalog(
        offset: base.products.length,
        limit: _pageSize,
        vendorId: base.vendorId,
      );
      final products = [...base.products, ..._rows(data)];
      emit(
        HashStoreHomeState(
          products: products,
          count: (data['count'] as num?)?.toInt() ?? base.count,
          vendorId: base.vendorId,
          vendors: base.vendorId == null ? _vendorsOf(products) : base.vendors,
        ),
      );
    } catch (_) {
      // Keep what is on screen; the next scroll retries.
      emit(_copy(base));
    }
  }

  static HashStoreHomeState _copy(
    HashStoreHomeState s, {
    bool loadingMore = false,
  }) => HashStoreHomeState(
    products: s.products,
    count: s.count,
    vendorId: s.vendorId,
    vendors: s.vendors,
    loadingMore: loadingMore,
  );

  static List<Map<String, dynamic>> _rows(Map<String, dynamic> data) =>
      (data['products'] as List? ?? [])
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();

  static Map<String, String> _vendorsOf(
    List<Map<String, dynamic>> products,
  ) => {
    for (final p in products)
      if (p['vendor_id'] != null)
        p['vendor_id'] as String: (p['vendor_name'] ?? 'Partner').toString(),
  };
}
