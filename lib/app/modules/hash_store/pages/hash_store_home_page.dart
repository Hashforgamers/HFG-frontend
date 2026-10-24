import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_home_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_product_page.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/core/localization/app_region.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

/// Shop home, per the Figma "Home" frame: profile header, a title, then one
/// full-width banner card per listing.
class HashStoreHomePage extends StatelessWidget {
  const HashStoreHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HashStoreHomeCubit()..fetchProducts(),
      child: const _CatalogBody(),
    );
  }
}

bool _soldOut(Map<String, dynamic> p) =>
    p['available'] != null && storeNum(p['available']) <= 0;

class _CatalogBody extends StatelessWidget {
  const _CatalogBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HashStoreHomeCubit>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<HashStoreHomeCubit, HashStoreHomeState>(
        builder: (context, state) {
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 400) cubit.loadMore();
              return false;
            },
            child: RefreshIndicator(
              color: StoreColors.green,
              backgroundColor: StoreColors.surface,
              onRefresh: () => cubit.fetchProducts(vendorId: state.vendorId),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const HashStoreAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
                      child: Text(
                        'Buy our Exclusive Hash Products',
                        textAlign: TextAlign.center,
                        style: storeDisplay(16),
                      ),
                    ),
                  ),
                  ..._content(context, state),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 96,
                      child: state.loadingMore
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: StoreColors.green,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(BuildContext context, HashStoreHomeState state) {
    final cubit = context.read<HashStoreHomeCubit>();
    if (state.loading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 28),
            itemBuilder: (_, _) => const AspectRatio(
              aspectRatio: _BannerCard.aspectRatio,
              child: StoreSkeleton(height: double.infinity, radius: 22),
            ),
          ),
        ),
      ];
    }
    if (state.error != null) {
      return [
        SliverToBoxAdapter(
          child: StoreMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Store is offline',
            body: state.error,
            actionLabel: 'Try again',
            onAction: () => cubit.fetchProducts(vendorId: state.vendorId),
          ),
        ),
      ];
    }
    if (state.products.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: StoreMessage(
            icon: Icons.storefront_outlined,
            title: 'Nothing here yet',
            body: 'New Hash products appear here as soon as they are approved.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: state.products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 28),
          itemBuilder: (context, i) => StoreEntrance(
            index: i % 6,
            child: _BannerCard(product: state.products[i]),
          ),
        ),
      ),
    ];
  }
}

/// Figma product banner: tinted art background, copy and an "Add to Cart"
/// pill on the left, the product image on the right.
class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _BannerCard({required this.product});

  /// 662 × 328 in the Figma frame.
  static const aspectRatio = 2.02;

  @override
  Widget build(BuildContext context) {
    final thumbnail = product['thumbnail'] as String?;
    final hasImage = thumbnail != null && thumbnail.isNotEmpty;
    final description = '${product['description'] ?? ''}';
    return StoreTilt(
      maxAngle: 0.06,
      child: BounceTap(
        onTap: () => openStoreProduct(context, product),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The product's own art, blurred, gives each card its tint.
                  if (hasImage)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Transform.scale(
                        scale: 1.4,
                        child: CachedNetworkImage(
                          imageUrl: thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    )
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1325), Color(0xFF5B1C8C)],
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.72),
                          Colors.black.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                  ),
                  if (hasImage)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: MediaQuery.sizeOf(context).width * 0.42,
                      child: ShaderMask(
                        // Fades the photo into the card on its left edge.
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          stops: [0, 0.35],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: StoreImage(url: thumbnail, radius: 0),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: FractionallySizedBox(
                      widthFactor: 0.68,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product['title'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: storeDisplay(19),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: storeBody(
                                size: 11.5,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            Money.format(
                              storeNum(product['price_inr']),
                              decimals: 2,
                            ),
                            style: storeBody(size: 14, weight: FontWeight.w600),
                          ),
                          const Spacer(),
                          _AddToCartPill(product: product),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Green outline "Add to Cart"; turns white once the item is in the cart.
class _AddToCartPill extends StatelessWidget {
  final Map<String, dynamic> product;
  const _AddToCartPill({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<HashStoreCartCubit>().state;
    final inCart = cart.items.any(
      (i) => i['variant_id'] == product['variant_id'],
    );
    final soldOut = _soldOut(product);
    final label = soldOut
        ? 'Sold Out'
        : inCart
        ? 'In Cart'
        : 'Add to Cart';
    return Semantics(
      button: true,
      enabled: !soldOut && !cart.busy,
      label: '$label, ${product['title']}',
      excludeSemantics: true,
      child: BounceTap(
        onTap: soldOut || cart.busy
            ? null
            : inCart
            ? () => openShopTab(context, 2)
            : () => addProductToCart(context, product),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: inCart ? Colors.white : Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: inCart
                  ? Colors.white
                  : soldOut
                  ? Colors.white38
                  : StoreColors.green,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inCart) ...[
                const Icon(Icons.check_rounded, size: 16, color: Colors.black),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: storeBody(
                  size: 13,
                  weight: FontWeight.w700,
                  color: inCart
                      ? Colors.black
                      : soldOut
                      ? Colors.white54
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
