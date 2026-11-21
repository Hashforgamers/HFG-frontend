import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/widgets/store_specs.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

void main() {
  final product = <String, dynamic>{
    'variant_id': 'variant_black',
    'price_inr': 1499,
    'compare_at_price_inr': 1999,
    'available': 8,
    'variants': [
      {
        'id': 'variant_black',
        'options': {'color': 'Black'},
        'available': 8,
        'prices': [
          {'currency_code': 'inr', 'amount': 1499},
        ],
      },
      {
        'id': 'variant_white',
        'options': {'color': 'White'},
        'available': 0,
        'prices': [
          {'currency_code': 'inr', 'amount': 1599},
        ],
      },
      {
        'id': 'variant_red',
        'options': {'color': 'Red'},
        'available': 3,
        'prices': [
          {'currency_code': 'usd', 'amount': 20},
        ],
      },
    ],
  };

  test('selected SKU drives price, stock and variant_id', () {
    final variants = storeVariants(product);
    final white = storeWithVariant(product, variants[1]);
    expect(white['variant_id'], 'variant_white');
    expect(storeCardPrice(white).price, 1599);
    expect(white.containsKey('compare_at_price_inr'), isFalse);
    expect(storeSkuBuyable(white), isFalse); // no stock
    expect(storeSkuBuyable(storeWithVariant(product, variants[2])), isFalse);
    expect(storeSkuBuyable(storeWithVariant(product, variants[0])), isTrue);
  });

  test('price range comes from priced SKUs only', () {
    final range = storePriceRange(product)!;
    expect((range.low, range.high), (1499, 1599));
  });

  test('spec values and labels', () {
    final defs = storeSpecDefs([
      {
        'specifications': [
          {'key': 'dpi', 'label': 'DPI', 'unit': 'dpi'},
        ],
      },
    ]);
    expect(storeSpecLabel('dpi', defs), 'DPI');
    expect(storeSpecValue(8000, defs['dpi']), '8000 dpi');
    expect(storeSpecValue(true), 'Yes');
    expect(storeSpecLabel('brand', defs), 'brand');
  });
}
