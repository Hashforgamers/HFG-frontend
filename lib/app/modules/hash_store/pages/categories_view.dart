import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_home_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_home_page.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/app/modules/hash_store/widgets/store_page_intro.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// Browse actual catalog partners rather than placeholder categories.
class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HashStoreHomeCubit()..fetchProducts(),
    child: BlocBuilder<HashStoreHomeCubit, HashStoreHomeState>(
      builder: (context, state) {
        final cubit = context.read<HashStoreHomeCubit>();
        return Scaffold(
          backgroundColor: StoreColors.bg,
          body: RefreshIndicator(
            color: StoreColors.green,
            onRefresh: cubit.fetchProducts,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const HashStoreAppBar(),
                const SliverToBoxAdapter(
                  child: StorePageIntro(
                    eyebrow: 'Discover',
                    title: 'Find your next upgrade.',
                    subtitle:
                        'Browse the partners behind your gear and gaming sessions.',
                  ),
                ),
                if (state.loading)
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList.list(
                      children: const [
                        StoreSkeleton(height: 110),
                        SizedBox(height: 12),
                        StoreSkeleton(height: 110),
                      ],
                    ),
                  )
                else if (state.error != null)
                  SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.wifi_off_rounded,
                      title: 'Could not load partners',
                      body: state.error,
                      actionLabel: 'Try again',
                      onAction: cubit.fetchProducts,
                    ),
                  )
                else if (state.vendors.isEmpty)
                  const SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.storefront_outlined,
                      title: 'Partners are on the way',
                      body: 'Explore new collections here when they arrive.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: state.vendors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final vendor = state.vendors.entries.elementAt(index);
                        final products = state.products
                            .where((p) => p['vendor_id'] == vendor.key)
                            .toList();
                        return Material(
                          color: StoreColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              final cart = context.read<HashStoreCartCubit>();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: cart,
                                    child: HashStoreHomePage(
                                      vendorId: vendor.key,
                                      vendorName: vendor.value,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  StoreImage(
                                    url:
                                        products.firstOrNull?['thumbnail']
                                            as String?,
                                    width: 72,
                                    height: 72,
                                    radius: 14,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vendor.value,
                                          style: storeTitle(17),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Explore collection',
                                          style: storeBody(
                                            size: 12,
                                            color: StoreColors.purpleSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: StoreColors.muted,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (state.hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: StoreButton(
                        label: 'Discover more partners',
                        filled: false,
                        loading: state.loadingMore,
                        onTap: cubit.loadMore,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    ),
  );
}
