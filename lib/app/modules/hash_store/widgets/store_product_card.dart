import 'package:flutter/material.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// Compact 2-column grid tile, Myntra style: the whole tile opens the
/// product; the bag button adds it, or opens the bag once it is in there.
class StoreProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool inCart;
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onAdd;
  const StoreProductCard({
    super.key,
    required this.product,
    required this.onDetails,
    required this.onAdd,
    this.inCart = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final soldOut =
        product['available'] != null && storeNum(product['available']) <= 0;
    final title = '${product['title'] ?? 'Hash product'}';
    final service = product['kind'] == 'service';
    return Material(
      color: StoreColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: StoreColors.border),
      ),
      child: InkWell(
        onTap: onDetails,
        child: Semantics(
          button: true,
          label: 'View $title',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    StoreImage(url: product['thumbnail'] as String?, radius: 0),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: StoreStatusChip(
                        soldOut
                            ? 'Sold out'
                            : service
                            ? 'Session'
                            : 'Gear',
                        color: soldOut
                            ? StoreColors.muted
                            : StoreColors.purpleSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product['vendor_name'] ?? 'Hash partner'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: storeBody(size: 10, color: StoreColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: storeBody(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              storeMoney(product['price_inr']),
                              style: storeTitle(16),
                            ),
                          ),
                          if (!soldOut)
                            IconButton(
                              tooltip: inCart ? 'Go to bag' : 'Add to bag',
                              visualDensity: VisualDensity.compact,
                              onPressed: busy && !inCart ? null : onAdd,
                              icon: Icon(
                                inCart
                                    ? Icons.shopping_bag_rounded
                                    : Icons.add_shopping_cart_rounded,
                                size: 20,
                                color: inCart
                                    ? StoreColors.greenSoft
                                    : Colors.white,
                              ),
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
      ),
    );
  }
}
