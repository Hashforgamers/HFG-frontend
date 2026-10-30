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

  // Bumped per filter change so a slow earlier response cannot win.
  int _request = 0;

  Future<void> fetchProducts({String? vendorId, String? categoryId}) async {
    final request = ++_request;
    final base = state;
    emit(
      HashStoreHomeState(
        vendorId: vendorId,
        categoryId: categoryId,
        vendors: base.vendors,
        categories: base.categories,
        loading: true,
      ),
    );
    if (base.categories.isEmpty) _loadCategories();
    try {
      final data = await _store.catalog(
        limit: _pageSize,
        vendorId: vendorId,
        categoryId: categoryId,
      );
      if (request != _request) return;
      final products = _rows(data);
      emit(
        HashStoreHomeState(
          products: products,
          count: (data['count'] as num?)?.toInt() ?? products.length,
          vendorId: vendorId,
          categoryId: categoryId,
          vendors: vendorId == null && categoryId == null
              ? _vendorsOf(products)
              : state.vendors,
          categories: state.categories,
        ),
      );
    } catch (e) {
      if (request != _request) return;
      emit(
        HashStoreHomeState(
          vendorId: vendorId,
          categoryId: categoryId,
          vendors: state.vendors,
          categories: state.categories,
          error: e.toString(),
        ),
      );
    }
  }

  /// Without categories the shop still works; only "All" is shown.
  Future<void> _loadCategories() async {
    try {
      final categories = await _store.categories();
      emit(_copy(state, categories: categories));
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final request = _request;
    final base = state;
    emit(_copy(base, loadingMore: true));
    try {
      final data = await _store.catalog(
        offset: base.products.length,
        limit: _pageSize,
        vendorId: base.vendorId,
        categoryId: base.categoryId,
      );
      if (request != _request) return;
      final products = [...base.products, ..._rows(data)];
      emit(
        HashStoreHomeState(
          products: products,
          count: (data['count'] as num?)?.toInt() ?? base.count,
          vendorId: base.vendorId,
          categoryId: base.categoryId,
          vendors: base.vendorId == null && base.categoryId == null
              ? _vendorsOf(products)
              : base.vendors,
          categories: state.categories,
        ),
      );
    } catch (_) {
      // Keep what is on screen; the next scroll retries.
      if (request == _request) emit(_copy(state));
    }
  }

  static HashStoreHomeState _copy(
    HashStoreHomeState s, {
    bool loadingMore = false,
    List<Map<String, dynamic>>? categories,
  }) => HashStoreHomeState(
    products: s.products,
    count: s.count,
    vendorId: s.vendorId,
    categoryId: s.categoryId,
    vendors: s.vendors,
    categories: categories ?? s.categories,
    loading: s.loading,
    error: s.error,
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
