import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// Pushes the product page, carrying the shop's shared cart along.
void openStoreProduct(BuildContext context, Map<String, dynamic> product) {
  final cart = context.read<HashStoreCartCubit>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cart,
        child: HashStoreProductPage(product: product),
      ),
    ),
  );
}

/// Renders a `/store/hash/products` row; the catalog already carries
/// everything this page shows.
class HashStoreProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const HashStoreProductPage({super.key, required this.product});

  @override
  State<HashStoreProductPage> createState() => _HashStoreProductPageState();
}

class _HashStoreProductPageState extends State<HashStoreProductPage> {
  int _qty = 1;
  final _scroll = ScrollController();

  Map<String, dynamic> get p => widget.product;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = p['available'] == null
        ? null
        : storeNum(p['available']).toInt();
    final soldOut = available != null && available <= 0;
    final maxQty = available ?? 10;
    final busy = context.select((HashStoreCartCubit c) => c.state.busy);
    final isService = p['kind'] == 'service';
    final top = MediaQuery.paddingOf(context).top;
    final description = '${p['description'] ?? ''}';

    return Scaffold(
      backgroundColor: StoreColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      // Parallax on scroll, stretch on pull-down.
                      AnimatedBuilder(
                        animation: _scroll,
                        builder: (context, child) {
                          final offset = _scroll.hasClients
                              ? _scroll.offset
                              : 0.0;
                          return Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..translateByDouble(
                                0,
                                offset > 0 ? offset * 0.45 : offset,
                                0,
                                1,
                              )
                              ..scaleByDouble(
                                1 + (offset < 0 ? -offset / 300 : 0),
                                1 + (offset < 0 ? -offset / 300 : 0),
                                1,
                                1,
                              ),
                            child: child,
                          );
                        },
                        child: StoreImage(
                          url: p['thumbnail'] as String?,
                          radius: 0,
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0, 0.25, 0.7, 1],
                            colors: [
                              Color(0x99050506),
                              Colors.transparent,
                              Colors.transparent,
                              StoreColors.bg,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StoreEntrance(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StoreStatusChip(
                              isService ? 'Session' : 'Gear',
                              icon: isService
                                  ? Icons.sports_esports_rounded
                                  : Icons.inventory_2_outlined,
                              color: StoreColors.purpleSoft,
                            ),
                            if (available != null)
                              StoreStatusChip(
                                soldOut
                                    ? 'Sold out'
                                    : available <= 5
                                    ? 'Only $available left'
                                    : 'In stock',
                                color: soldOut
                                    ? StoreColors.faint
                                    : available <= 5
                                    ? Colors.orangeAccent
                                    : StoreColors.greenSoft,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('${p['title'] ?? ''}', style: storeDisplay(26)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: StoreColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${p['vendor_name'] ?? 'Hash partner'}',
                              style: storeBody(color: StoreColors.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          storeMoney(p['price_inr']),
                          style: storeTitle(
                            30,
                          ).copyWith(color: StoreColors.greenSoft),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            description,
                            style: storeBody(
                              size: 15,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        StoreSection(
                          title: 'How it works',
                          child: StorePanel(
                            child: Column(
                              children: [
                                const _Step(
                                  icon: Icons.shopping_bag_outlined,
                                  title: 'Order in the app',
                                  body: 'Checkout takes under a minute.',
                                ),
                                _Step(
                                  icon: isService
                                      ? Icons.sports_esports_outlined
                                      : Icons.local_shipping_outlined,
                                  title: isService
                                      ? 'Play your session'
                                      : 'Get it delivered',
                                  body: isService
                                      ? 'Show up at the partner and play.'
                                      : 'The partner ships it to your address.',
                                ),
                                const _Step(
                                  icon: Icons.verified_user_outlined,
                                  title: 'Share your completion code',
                                  body:
                                      'Only after delivery or your session, '
                                      'from the order screen.',
                                  last: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Back',
                  excludeSemantics: true,
                  child: StoreGlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                const StoreCartButton(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StoreBottomBar(
        child: Row(
          children: [
            if (!soldOut) ...[
              StoreQtyStepper(
                value: _qty,
                onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
                onPlus: _qty < maxQty ? () => setState(() => _qty++) : null,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: StoreButton(
                label: soldOut
                    ? 'Sold out'
                    : 'Add · ${storeMoney(storeNum(p['price_inr']) * _qty)}',
                icon: soldOut ? null : Icons.shopping_bag_rounded,
                loading: busy,
                onTap: soldOut
                    ? null
                    : () async {
                        final added = await addProductToCart(
                          context,
                          p,
                          quantity: _qty,
                        );
                        if (added && context.mounted) Navigator.pop(context);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool last;
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StoreColors.green.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 18, color: StoreColors.greenSoft),
            ),
            if (!last)
              Expanded(
                child: Container(
                  width: 1.5,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: StoreColors.border,
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: storeBody(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: storeBody(size: 12, color: StoreColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
