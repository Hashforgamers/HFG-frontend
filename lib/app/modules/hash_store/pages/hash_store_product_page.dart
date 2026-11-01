import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_checkout_page.dart';
import 'package:hash/app/modules/hash_store/widgets/store_reviews.dart';
import 'package:hash/app/modules/hash_store/widgets/store_specs.dart';
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

  Map<String, Map> _defs = const {};

  /// Selected option per key; starts on the default SKU.
  late Map<String, Object?> _options = Map<String, Object?>.from(
    (_variants.firstWhere(
              (v) => v['id'] == widget.product['variant_id'],
              orElse: () => _variants.firstOrNull ?? const {},
            )['options']
            as Map?) ??
        const {},
  );

  List<Map> get _variants => storeVariants(widget.product);

  bool _matches(Map v, Map<String, Object?> options) =>
      options.entries.every((e) => (v['options'] as Map?)?[e.key] == e.value);

  Map? get _variant =>
      _variants.where((v) => _matches(v, _options)).firstOrNull;

  /// The product as its selected SKU: price, stock, offers and variant_id.
  Map<String, dynamic> get _sku => _variant == null
      ? widget.product
      : storeWithVariant(widget.product, _variant!);

  /// Option keys and values present in the actual SKUs, in first-seen order.
  Map<String, List<Object?>> get _optionValues {
    final out = <String, List<Object?>>{};
    for (final v in _variants) {
      for (final e in ((v['options'] as Map?) ?? const {}).entries) {
        final values = out['${e.key}'] ??= [];
        if (!values.contains(e.value)) values.add(e.value);
      }
    }
    return out;
  }

  void _pick(String key, Object? value) {
    final wanted = {..._options, key: value};
    // Keep the other choices when that SKU exists; otherwise jump to the
    // closest SKU with this value, preferring one that can be bought.
    final candidates = _variants
        .where((v) => (v['options'] as Map?)?[key] == value)
        .toList();
    final next =
        candidates.where((v) => _matches(v, wanted)).firstOrNull ??
        candidates
            .where((v) => storeSkuBuyable(storeWithVariant(widget.product, v)))
            .firstOrNull ??
        candidates.firstOrNull;
    if (next == null) return;
    setState(() {
      _options = Map<String, Object?>.from((next['options'] as Map?) ?? wanted);
      _qty = 1;
    });
  }

  @override
  void initState() {
    super.initState();
    // Labels only; raw keys show until (or if) categories load.
    MedusaStoreService.instance
        .categories()
        .then((c) {
          if (mounted) setState(() => _defs = storeSpecDefs(c));
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _sku;
    final optionValues = _optionValues;
    final specs = ((widget.product['specifications'] as Map?) ?? const {})
        .entries
        .where((e) => e.value != null && '${e.value}'.isNotEmpty)
        .toList();
    final available = p['available'] == null
        ? null
        : storeNum(p['available']).toInt();
    final soldOut = available != null && available <= 0;
    final buyable = _variant != null || _variants.isEmpty
        ? storeSkuBuyable(p)
        : false;
    final price = storeCardPrice(p);
    final maxQty = available ?? 10;
    final busy = context.select((HashStoreCartCubit c) => c.state.busy);
    final inCart = context.select(
      (HashStoreCartCubit c) =>
          c.state.items.any((item) => item['variant_id'] == p['variant_id']),
    );
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
                        // The fade moves with the image: parallax slides the
                        // image below this box, and a fixed fade left a hard
                        // edge across the title.
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            StoreImage(
                              url: p['thumbnail'] as String?,
                              radius: 0,
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
                        Text('${p['title'] ?? ''}', style: storeTitle(28)),
                        const SizedBox(height: 6),
                        StoreRatingLine(p['rating_summary'], size: 14),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: StoreColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${p['vendor_name'] ?? 'Hash partner'}',
                                style: storeBody(color: StoreColors.muted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    price.price == null
                                        ? 'Price unavailable'
                                        : storeMoney(price.price),
                                    style: storeTitle(
                                      30,
                                    ).copyWith(color: StoreColors.greenSoft),
                                  ),
                                  if (price.off > 0)
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: storeMoney(price.was),
                                            style: const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                '  ${price.off}% off · Save ${storeMoney(price.save)}',
                                          ),
                                        ],
                                      ),
                                      style: storeBody(
                                        size: 13,
                                        color: StoreColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (buyable && !inCart)
                              StoreQtyStepper(
                                value: _qty,
                                onMinus: _qty > 1
                                    ? () => setState(() => _qty--)
                                    : null,
                                onPlus: _qty < maxQty
                                    ? () => setState(() => _qty++)
                                    : null,
                              ),
                          ],
                        ),
                        for (final o in storeCouponOffers(p)) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Code ${o['code']}: pay ${storeMoney(o['price_after_discount'])} — apply it in your bag',
                            style: storeBody(
                              size: 13,
                              color: StoreColors.purpleSoft,
                            ),
                          ),
                        ],
                        for (final option in optionValues.entries) ...[
                          const SizedBox(height: 20),
                          Text(
                            '${storeSpecLabel(option.key, _defs)}: '
                            '${storeSpecValue(_options[option.key], _defs[option.key])}',
                            style: storeBody(
                              size: 13,
                              color: StoreColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final value in option.value)
                                Builder(
                                  builder: (_) {
                                    final match = _variants
                                        .where(
                                          (v) => _matches(v, {
                                            ..._options,
                                            option.key: value,
                                          }),
                                        )
                                        .firstOrNull;
                                    return StoreOptionChip(
                                      label: storeSpecValue(
                                        value,
                                        _defs[option.key],
                                      ),
                                      selected: _options[option.key] == value,
                                      // Dimmed: not sold with the other
                                      // choices, or that SKU can't be bought.
                                      muted:
                                          match == null ||
                                          !storeSkuBuyable(
                                            storeWithVariant(
                                              widget.product,
                                              match,
                                            ),
                                          ),
                                      onTap: () => _pick(option.key, value),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                        if (specs.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          StoreSection(
                            title: 'Specifications',
                            child: StorePanel(
                              child: Column(
                                children: [
                                  for (final e in specs)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              storeSpecLabel('${e.key}', _defs),
                                              style: storeBody(
                                                size: 13,
                                                color: StoreColors.muted,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              storeSpecValue(
                                                e.value,
                                                _defs['${e.key}'],
                                              ),
                                              style: storeBody(size: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                        if (p['product_id'] is String) ...[
                          const SizedBox(height: 28),
                          StoreProductReviews(
                            productId: p['product_id'] as String,
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
                                  body:
                                      'Review your cart, delivery and payment options.',
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
      // Amazon/Myntra pattern: add in place (the button becomes "Go to bag"),
      // or Buy now straight into checkout.
      bottomNavigationBar: StoreBottomBar(
        child: !buyable
            ? StoreButton(label: soldOut ? 'Sold out' : 'Unavailable')
            : Row(
                children: [
                  Expanded(
                    child: StoreButton(
                      label: inCart ? 'Go to bag' : 'Add to bag',
                      icon: inCart
                          ? Icons.arrow_forward_rounded
                          : Icons.shopping_bag_outlined,
                      filled: false,
                      loading: busy && !inCart,
                      onTap: busy
                          ? null
                          : inCart
                          ? () => openShopTab(context, 2)
                          : () async {
                              if (await addProductToCart(
                                context,
                                p,
                                quantity: _qty,
                              )) {
                                storeToast('Added to your bag');
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StoreButton(
                      label: 'Buy now',
                      icon: Icons.bolt_rounded,
                      onTap: busy
                          ? null
                          : () async {
                              if (!inCart &&
                                  !await addProductToCart(
                                    context,
                                    p,
                                    quantity: _qty,
                                  )) {
                                return;
                              }
                              if (context.mounted) openStoreCheckout(context);
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
