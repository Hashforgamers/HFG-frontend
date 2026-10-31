import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_checkout_page.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/app/modules/hash_store/widgets/store_page_intro.dart';

class HashStoreCartView extends StatefulWidget {
  const HashStoreCartView({super.key});

  @override
  State<HashStoreCartView> createState() => _HashStoreCartViewState();
}

class _HashStoreCartViewState extends State<HashStoreCartView> {
  @override
  void initState() {
    super.initState();
    context.read<HashStoreCartCubit>().fetchCart();
  }

  /// Removes a line, then offers Undo instead of asking first.
  Future<void> _remove(Map<String, dynamic> item) async {
    final cubit = context.read<HashStoreCartCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final vendorId = await MedusaStoreService.instance.cartVendorId();
    try {
      await cubit.removeItem(item['id'] as String);
    } catch (e) {
      storeToast(e.toString(), error: true);
      return;
    }
    Haptics.light();
    final title = '${item['product_title'] ?? item['title'] ?? 'Item'}';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StoreColors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text('$title removed', style: storeBody(size: 14)),
          action: vendorId == null || item['variant_id'] == null
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  textColor: StoreColors.greenSoft,
                  onPressed: () => _guard(
                    () => cubit.addItem({
                      'variant_id': item['variant_id'],
                      'vendor_id': vendorId,
                      'title': title,
                    }, quantity: storeNum(item['quantity']).toInt()),
                  ),
                ),
        ),
      );
  }

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      storeToast(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HashStoreCartCubit>();
    return BlocBuilder<HashStoreCartCubit, HashStoreCartState>(
      builder: (context, state) {
        final items = state.items;
        final cart = state.cart;
        final hasItems = items.isNotEmpty;
        return Scaffold(
          backgroundColor: StoreColors.bg,
          bottomNavigationBar: hasItems
              ? StoreBottomBar(
                  child: Row(
                    children: [
                      StoreTotalLabel(amount: cart!['total']),
                      const SizedBox(width: 20),
                      Expanded(
                        child: StoreButton(
                          label: 'Checkout',
                          icon: Icons.lock_rounded,
                          onTap: state.busy
                              ? null
                              : () => openStoreCheckout(context),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          body: RefreshIndicator(
            color: StoreColors.green,
            backgroundColor: StoreColors.surface,
            onRefresh: cubit.fetchCart,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                const HashStoreAppBar(),
                SliverToBoxAdapter(
                  child: StorePageIntro(
                    eyebrow: 'Your bag',
                    title: 'Ready when you are.',
                    subtitle: hasItems
                        ? '${state.itemCount} item${state.itemCount == 1 ? '' : 's'} · Review your picks before checkout.'
                        : 'Your next upgrade starts here.',
                  ),
                ),
                if (state.loading && cart == null)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.list(
                      children: const [
                        StoreSkeleton(height: 112, radius: 20),
                        SizedBox(height: 12),
                        StoreSkeleton(height: 112, radius: 20),
                      ],
                    ),
                  )
                else if (state.error != null && cart == null)
                  SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load your cart',
                      body: state.error,
                      actionLabel: 'Try again',
                      onAction: cubit.fetchCart,
                    ),
                  )
                else if (!hasItems)
                  SliverToBoxAdapter(
                    child: StoreMessage(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your cart is empty',
                      body: 'Find gear and sessions from Hash partners.',
                      actionLabel: 'Browse the store',
                      onAction: () => openShopTab(context, 0),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final id = items[i]['id'] as String;
                        return StoreEntrance(
                          key: ValueKey(id),
                          index: i,
                          child: _CartRow(
                            item: items[i],
                            busy: state.busy,
                            onQty: (q) =>
                                _guard(() => cubit.setQuantity(id, q)),
                            onRemove: () => _remove(items[i]),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StoreSection(
                            title: 'Order summary',
                            child: StoreTotals(cart: cart!),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () => openShopTab(context, 0),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                            ),
                            label: const Text('Continue shopping'),
                            style: TextButton.styleFrom(
                              foregroundColor: StoreColors.purpleSoft,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: StoreColors.faint,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Delivery is chosen at checkout. Prices '
                                  'and stock are confirmed by the store.',
                                  style: storeBody(
                                    size: 11,
                                    color: StoreColors.faint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool busy;
  final ValueChanged<int> onQty;
  final Future<void> Function() onRemove;
  const _CartRow({
    required this.item,
    required this.busy,
    required this.onQty,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final qty = storeNum(item['quantity']).toInt();
    final variant = '${item['variant_title'] ?? ''}';
    final title = '${item['product_title'] ?? item['title'] ?? ''}';
    return Dismissible(
      key: ValueKey('dismiss-${item['id']}'),
      direction: busy ? DismissDirection.none : DismissDirection.endToStart,
      // Removal is async, so the row is never dismissed in place; it goes
      // away when the server cart comes back without it.
      confirmDismiss: (_) async {
        await onRemove();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: StoreColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: StoreColors.danger,
        ),
      ),
      child: StorePanel(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StoreImage(
              url: item['thumbnail'] as String?,
              width: 88,
              height: 88,
              radius: 14,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: storeBody(
                              size: 14,
                              weight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            tooltip: 'Remove $title',
                            padding: EdgeInsets.zero,
                            onPressed: busy ? null : onRemove,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: StoreColors.faint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (variant.isNotEmpty && variant != 'Default variant')
                      Text(
                        variant,
                        style: storeBody(size: 12, color: StoreColors.muted),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            storeMoney(
                              item['total'] ??
                                  storeNum(item['unit_price']) * qty,
                            ),
                            style: storeTitle(
                              16,
                            ).copyWith(color: StoreColors.greenSoft),
                          ),
                        ),
                        StoreQtyStepper(
                          compact: true,
                          value: qty,
                          onMinus: busy || qty <= 1
                              ? null
                              : () => onQty(qty - 1),
                          onPlus: busy ? null : () => onQty(qty + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
