import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_home_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_product_page.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/app/modules/hash_store/widgets/store_page_intro.dart';
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

class _CatalogBody extends StatelessWidget {
  final String? vendorName;
  const _CatalogBody({this.vendorName});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HashStoreHomeCubit>();
    return Scaffold(
      backgroundColor: StoreColors.bg,
      body: BlocBuilder<HashStoreHomeCubit, HashStoreHomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: StoreColors.green,
            backgroundColor: StoreColors.surface,
            onRefresh: () => cubit.fetchProducts(vendorId: state.vendorId),
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
                SliverToBoxAdapter(
                  child: StorePageIntro(
                    eyebrow: vendorName == null ? 'Hash Shop' : 'Shop partner',
                    title: vendorName ?? 'Upgrade your game.',
                    subtitle: vendorName == null
                        ? 'Gear for your setup. Sessions for your next win.'
                        : 'Explore products and sessions from this partner.',
                    trailing: const StoreCartButton(),
                  ),
                ),
                if (vendorName == null && state.vendors.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _partnerChip(context, 'All partners', null, state),
                            for (final vendor in state.vendors.entries) ...[
                              const SizedBox(width: 8),
                              _partnerChip(
                                context,
                                vendor.value,
                                vendor.key,
                                state,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                if (state.loading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.list(
                      children: const [
                        StoreSkeleton(height: 320),
                        SizedBox(height: 16),
                        StoreSkeleton(height: 320),
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
                      onAction: () =>
                          cubit.fetchProducts(vendorId: state.vendorId),
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
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Explore the collection',
                              style: storeTitle(15),
                            ),
                          ),
                          Text(
                            '${state.count} items',
                            style: storeBody(
                              size: 12,
                              color: StoreColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: state.products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, i) =>
                          BlocBuilder<HashStoreCartCubit, HashStoreCartState>(
                            builder: (context, cart) {
                              final product = state.products[i];
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

  Widget _partnerChip(
    BuildContext context,
    String label,
    String? id,
    HashStoreHomeState state,
  ) => ChoiceChip(
    label: Text(label),
    selected: state.vendorId == id,
    showCheckmark: false,
    labelStyle: storeBody(
      size: 12,
      color: state.vendorId == id ? Colors.white : StoreColors.muted,
    ),
    selectedColor: StoreColors.purple.withValues(alpha: 0.28),
    backgroundColor: StoreColors.surface,
    side: BorderSide(
      color: state.vendorId == id ? StoreColors.purpleSoft : StoreColors.border,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    onSelected: state.loading
        ? null
        : (_) => context.read<HashStoreHomeCubit>().fetchProducts(vendorId: id),
  );
}
