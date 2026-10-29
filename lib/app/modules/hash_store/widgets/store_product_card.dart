import 'package:flutter/material.dart';
import 'package:hash/app/modules/hash_store/widgets/store_reviews.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// Compact 2-column grid tile: the whole tile opens the product; the bag
/// button adds it, or opens the bag once it is in there.
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
    final price = storeNum(product['price_inr']);
    // Only a real seller-set MRP is shown struck through; never invented.
    final mrp = storeNum(product['compare_at_price_inr']);
    final off = mrp > price && price > 0
        ? ((mrp - price) / mrp * 100).round()
        : 0;
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
              // The image yields height so large text never overflows the cell.
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    StoreImage(url: product['thumbnail'] as String?, radius: 0),
                    if (soldOut)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: StoreStatusChip(
                          'Sold out',
                          color: StoreColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: storeBody(
                        size: 14,
                        weight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StoreRatingLine(
                                product['rating_summary'],
                                size: 11,
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      storeMoney(product['price_inr']),
                                      style: storeTitle(18),
                                    ),
                                    if (off > 0) ...[
                                      Text(
                                        storeMoney(mrp),
                                        style:
                                            storeBody(
                                              size: 12,
                                              color: StoreColors.muted,
                                            ).copyWith(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: StoreColors.green.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '$off% OFF',
                                          style: storeBody(
                                            size: 10,
                                            weight: FontWeight.w700,
                                            color: StoreColors.greenSoft,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!soldOut) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: inCart ? 'Go to bag' : 'Add to bag',
                            child: Material(
                              color: inCart
                                  ? StoreColors.green
                                  : StoreColors.purple,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: busy && !inCart ? null : onAdd,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    inCart
                                        ? Icons.shopping_bag_rounded
                                        : Icons.add_shopping_cart_rounded,
                                    size: 22,
                                    color: inCart ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
