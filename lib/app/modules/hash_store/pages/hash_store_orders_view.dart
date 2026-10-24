import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_orders_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_order_page.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';

class HashStoreOrdersView extends StatelessWidget {
  const HashStoreOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HashStoreOrdersCubit()..fetchOrders(),
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
                  const StoreTabTitle('Your Orders'),
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

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onClosed;
  const _OrderCard({required this.order, required this.onClosed});

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List? ?? [])
        .map((i) => Map<String, dynamic>.from(i as Map))
        .toList();
    final first = items.isEmpty ? null : items.first;
    final more = items.length - 1;
    final (status, color) = storeOrderStatus(order);
    return BounceTap(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HashStoreOrderPage(orderId: order['id'] as String),
          ),
        );
        onClosed();
      },
      child: StorePanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
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
                const Spacer(),
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
          ],
        ),
      ),
    );
  }
}
