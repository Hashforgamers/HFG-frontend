import 'package:flutter/material.dart';
import 'package:hash/app/modules/hash_store/widgets/store_page_intro.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/shop_new/controllers/shop_controller.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_orders_cubit.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_order_page.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

class HashStoreOrdersView extends StatefulWidget {
  const HashStoreOrdersView({super.key});

  @override
  State<HashStoreOrdersView> createState() => _HashStoreOrdersViewState();
}

class _HashStoreOrdersViewState extends State<HashStoreOrdersView> {
  final _cubit = HashStoreOrdersCubit()..fetchOrders();
  Worker? _onShow;

  @override
  void initState() {
    super.initState();
    // The shop keeps this tab mounted, so pick up new orders each time it
    // is shown again. Loaded orders refresh in place, without a skeleton.
    if (Get.isRegistered<ShopController>()) {
      _onShow = ever<int>(Get.find<ShopController>().shopMenuIndex, (i) {
        if (i == 3) _cubit.fetchOrders();
      });
    }
  }

  @override
  void dispose() {
    _onShow?.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HashStoreOrdersCubit, HashStoreOrdersState>(
        builder: (context, state) {
          final cubit = context.read<HashStoreOrdersCubit>();
          return Scaffold(
            backgroundColor: StoreColors.bg,
            body: RefreshIndicator(
              color: StoreColors.green,
              backgroundColor: StoreColors.surface,
              onRefresh: cubit.fetchOrders,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const HashStoreAppBar(),
                  const SliverToBoxAdapter(
                    child: StorePageIntro(
                      eyebrow: 'Your orders',
                      title: 'Every order. One place.',
                      subtitle:
                          'Follow your purchases, delivery and completion details.',
                    ),
                  ),
                  if (state is HashStoreOrdersLoaded && state.orders.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: state.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => StoreEntrance(
                          index: i,
                          child: _OrderCard(
                            order: state.orders[i],
                            onClosed: cubit.fetchOrders,
                          ),
                        ),
                      ),
                    )
                  else if (state is HashStoreOrdersLoaded)
                    SliverToBoxAdapter(
                      child: StoreMessage(
                        icon: Icons.receipt_long_outlined,
                        title: 'No orders yet',
                        body: 'Your Hash Store purchases show up here.',
                        actionLabel: 'Browse the store',
                        onAction: () => openShopTab(context, 0),
                      ),
                    )
                  else if (state is HashStoreOrdersError)
                    SliverToBoxAdapter(
                      child: StoreMessage(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load orders',
                        body: state.message,
                        actionLabel: 'Try again',
                        onAction: cubit.fetchOrders,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList.list(
                        children: const [
                          StoreSkeleton(height: 120, radius: 20),
                          SizedBox(height: 12),
                          StoreSkeleton(height: 120, radius: 20),
                          SizedBox(height: 12),
                          StoreSkeleton(height: 120, radius: 20),
                        ],
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
}

/// Shopper-facing label and colour for an order's fulfilment state.
(String, Color) storeOrderStatus(Map<String, dynamic> order) {
  switch ('${order['fulfillment_status'] ?? ''}') {
    case 'delivered':
      return ('Completed', StoreColors.greenSoft);
    case 'shipped':
    case 'partially_shipped':
      return ('On the way', StoreColors.purpleSoft);
    case 'canceled':
      return ('Cancelled', StoreColors.danger);
    default:
      return ('Processing', Colors.orangeAccent);
  }
}

/// Hash tracking stage for an order row; the tracker, not Medusa's
/// fulfilment status, is authoritative.
(String, Color) storeTrackingStatus(Map<String, dynamic> tracking) {
  if (tracking['cancellation'] is Map) {
    return ('Cancellation requested', Colors.orangeAccent);
  }
  if (tracking['on_hold'] == true) return ('On hold', Colors.orangeAccent);
  final status = tracking['status'];
  return (
    storeTrackingLabel(status, tracking['kind']),
    switch (status) {
      'delivered' || 'completed' => StoreColors.greenSoft,
      'canceled' => StoreColors.danger,
      _ => StoreColors.purpleSoft,
    },
  );
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onClosed;
  const _OrderCard({required this.order, required this.onClosed});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  Map<String, dynamic>? _tracking;

  Map<String, dynamic> get order => widget.order;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  @override
  void didUpdateWidget(_OrderCard old) {
    super.didUpdateWidget(old);
    // A list refresh hands in new order maps; pick up the latest stage too.
    if (!identical(old.order, widget.order)) _loadTracking();
  }

  Future<void> _loadTracking() async {
    try {
      final result = await MedusaStoreService.instance.tracking(
        '${order['id']}',
      );
      if (mounted && result['tracking'] is Map) {
        setState(
          () => _tracking = Map<String, dynamic>.from(result['tracking']),
        );
      }
    } catch (_) {
      // Keep the last known stage; a failed read is never a cancellation.
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HashStoreOrderPage(orderId: order['id'] as String),
      ),
    );
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    final first = items.isEmpty ? null : items.first;
    final more = items.length - 1;
    final t = _tracking;
    final (status, color) = t == null
        ? storeOrderStatus(order)
        : storeTrackingStatus(t);
    final active =
        t != null &&
        !const {'delivered', 'completed', 'canceled'}.contains(t['status']);
    final expected = active ? t['expected_delivery'] : null;
    return BounceTap(
      onTap: _open,
      child: StorePanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Order #${order['display_id'] ?? ''}',
                  style: storeBody(size: 12, color: StoreColors.muted),
                ),
                const Text('  ·  ', style: TextStyle(color: StoreColors.faint)),
                Text(
                  storeDate(order['created_at'], 'd MMM, h:mm a'),
                  style: storeBody(size: 12, color: StoreColors.muted),
                ),
                StoreStatusChip(status, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StoreImage(
                  url: first?['thumbnail'] as String?,
                  width: 64,
                  height: 64,
                  radius: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${first?['product_title'] ?? first?['title'] ?? 'Order'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: storeBody(size: 15, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        more > 0
                            ? '+ $more more item${more == 1 ? '' : 's'}'
                            : 'Qty ${first?['quantity'] ?? 1}',
                        style: storeBody(size: 12, color: StoreColors.muted),
                      ),
                      if (expected != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Arriving by ${storeDate(expected, 'EEE, d MMM')}',
                          style: storeBody(
                            size: 12,
                            weight: FontWeight.w600,
                            color: StoreColors.greenSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  storeMoney(order['total']),
                  style: storeTitle(16).copyWith(color: StoreColors.greenSoft),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: StoreColors.faint,
                ),
              ],
            ),
            if (active) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _open,
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Track order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: StoreColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
