import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_home_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_product_page.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/app/modules/hash_store/widgets/store_product_card.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

class HashStoreHomePage extends StatelessWidget {
  final String? vendorId;
  final String? vendorName;
  const HashStoreHomePage({super.key, this.vendorId, this.vendorName});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HashStoreHomeCubit()..fetchProducts(vendorId: vendorId),
    child: _CatalogBody(vendorName: vendorName),
  );
}

class _CatalogBody extends StatefulWidget {
  final String? vendorName;
  const _CatalogBody({this.vendorName});

  @override
  State<_CatalogBody> createState() => _CatalogBodyState();
}

// The backend sends no icons; unknown handles get the generic one.
const _categoryIcons = <String, IconData>{
  'accessories': Icons.headphones_rounded,
  'keyboards': Icons.keyboard_alt_outlined,
  'mouse': Icons.mouse_outlined,
  'monitors': Icons.desktop_windows_outlined,
  'chairs': Icons.chair_outlined,
};

class _CatalogBodyState extends State<_CatalogBody> {
  String _query = '';

  String? get vendorName => widget.vendorName;

  // shortcut: filters only the loaded page(s); the catalog API ignores `q`.
  // Move to server search once /store/hash/products supports it.
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> products) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where(
          (p) => [
            p['title'],
            p['vendor_name'],
            p['description'],
          ].any((v) => '${v ?? ''}'.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HashStoreHomeCubit>();
    return Scaffold(
      backgroundColor: StoreColors.bg,
      body: BlocBuilder<HashStoreHomeCubit, HashStoreHomeState>(
        builder: (context, state) {
          final products = _filter(state.products);
          final chips = [
            (id: null, name: 'All', icon: Icons.sports_esports_rounded),
            for (final c in state.categories)
              (
                id: c['id'] as String?,
                name: '${c['name'] ?? ''}',
                icon: _categoryIcons[c['handle']] ?? Icons.category_outlined,
              ),
          ];
          final categoryName = chips
              .firstWhere(
                (c) => c.id == state.categoryId,
                orElse: () => chips.first,
              )
              .name;
          return RefreshIndicator(
            color: StoreColors.green,
            backgroundColor: StoreColors.surface,
            onRefresh: () => cubit.fetchProducts(
              vendorId: state.vendorId,
              categoryId: state.categoryId,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                if (vendorName == null)
                  const HashStoreAppBar()
                else
                  SliverAppBar(
                    backgroundColor: StoreColors.bg,
                    foregroundColor: Colors.white,
                    title: Text(vendorName!, style: storeTitle(16)),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      style: storeBody(size: 14),
                      decoration: InputDecoration(
                        hintText: 'Search for gaming gear, accessories...',
                        hintStyle: storeBody(
                          size: 14,
                          color: StoreColors.muted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: StoreColors.muted,
                        ),
                        filled: true,
                        fillColor: StoreColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: StoreColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: StoreColors.border,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => _CategoryChip(
                        label: chips[i].name,
                        icon: chips[i].icon,
                        selected: chips[i].id == state.categoryId,
                        onTap: () {
                          if (chips[i].id == state.categoryId) return;
                          cubit.fetchProducts(
                            vendorId: state.vendorId,
                            categoryId: chips[i].id,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (state.loading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [
                        for (var i = 0; i < 4; i++)
                          const StoreSkeleton(
                            height: double.infinity,
                            radius: 18,
                          ),
                      ],
                    ),
                  )
                else if (state.error != null)
                  SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.wifi_off_rounded,
                      title: 'Could not load the shop',
                      body: state.error,
                      actionLabel: 'Try again',
                      onAction: () => cubit.fetchProducts(
                        vendorId: state.vendorId,
                        categoryId: state.categoryId,
                      ),
                    ),
                  )
                else if (state.products.isEmpty && state.categoryId != null)
                  SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.category_outlined,
                      title: 'Nothing in $categoryName yet',
                      body: 'Try another category or check back soon.',
                    ),
                  )
                else if (state.products.isEmpty)
                  const SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.storefront_outlined,
                      title: 'New finds are on the way',
                      body: 'Check back for products and gaming sessions.',
                    ),
                  )
                else if (products.isEmpty)
                  SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No matches for “${_query.trim()}”',
                      body: 'Try another category, name or brand.',
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Products', style: storeTitle(20)),
                          ),
                          Builder(
                            builder: (_) {
                              final n = _query.trim().isEmpty
                                  ? state.count
                                  : products.length;
                              return Text(
                                '$n item${n == 1 ? '' : 's'}',
                                style: storeBody(
                                  size: 12,
                                  color: StoreColors.muted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, i) =>
                          BlocBuilder<HashStoreCartCubit, HashStoreCartState>(
                            builder: (context, cart) {
                              final product = products[i];
                              final inCart = cart.items.any(
                                (item) =>
                                    item['variant_id'] == product['variant_id'],
                              );
                              return StoreProductCard(
                                product: product,
                                inCart: inCart,
                                busy: cart.busy,
                                onDetails: () =>
                                    openStoreProduct(context, product),
                                onAdd: () {
                                  if (inCart) {
                                    openShopTab(context, 2);
                                  } else {
                                    addProductToCart(context, product);
                                  }
                                },
                              );
                            },
                          ),
                    ),
                  ),
                  if (state.hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: StoreButton(
                          label: 'Explore more',
                          filled: false,
                          loading: state.loadingMore,
                          onTap: cubit.loadMore,
                        ),
                      ),
                    ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: ExcludeSemantics(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? StoreColors.purple : StoreColors.surface,
                  border: Border.all(
                    color: selected
                        ? StoreColors.purpleSoft
                        : StoreColors.border,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: storeBody(
                  size: 11,
                  weight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Colors.white : StoreColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 32 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: StoreColors.purpleSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
