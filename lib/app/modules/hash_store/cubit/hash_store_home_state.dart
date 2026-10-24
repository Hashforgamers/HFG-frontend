part of 'hash_store_home_cubit.dart';

class HashStoreHomeState extends Equatable {
  /// Catalog rows as returned by `/store/hash/products`.
  final List<Map<String, dynamic>> products;
  final int count;
  final String? vendorId;

  /// vendor_id -> vendor_name, collected from the unfiltered catalog.
  final Map<String, String> vendors;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const HashStoreHomeState({
    this.products = const [],
    this.count = 0,
    this.vendorId,
    this.vendors = const {},
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => products.length < count;

  @override
  List<Object?> get props => [
    products,
    count,
    vendorId,
    vendors,
    loading,
    loadingMore,
    error,
  ];
}
