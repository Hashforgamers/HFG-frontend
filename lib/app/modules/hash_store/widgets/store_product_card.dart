import 'package:flutter/material.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// Product-first catalog card. Details and purchasing are separate actions.
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StoreColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onDetails,
            child: Semantics(
              button: true,
              label: 'View $title',
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.65,
                    child: StoreImage(
                      url: product['thumbnail'] as String?,
                      radius: 0,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: StoreStatusChip(
                      service ? 'Gaming session' : 'Gear',
                      color: StoreColors.purpleSoft,
                    ),
                  ),
                  if (soldOut)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: StoreStatusChip(
                        'Sold out',
                        color: StoreColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['vendor_name'] ?? 'Hash partner'}',
                  style: storeBody(size: 11, color: StoreColors.muted),
                ),
                const SizedBox(height: 7),
                InkWell(
                  onTap: onDetails,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(title, style: storeTitle(18)),
                  ),
                ),
                if ('${product['description'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${product['description']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: storeBody(
                      size: 12,
                      color: StoreColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      Text(
                        storeMoney(product['price_inr']),
                        style: storeTitle(23),
                      ),
                      SizedBox(
                        width: 150,
                        child: StoreButton(
                          label: soldOut
                              ? 'Sold out'
                              : inCart
                              ? 'View cart'
                              : 'Add to cart',
                          icon: soldOut
                              ? null
                              : inCart
                              ? Icons.shopping_bag_outlined
                              : Icons.add_rounded,
                          height: 44,
                          filled: !inCart,
                          loading: busy && !inCart,
                          onTap: soldOut || busy ? null : onAdd,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
