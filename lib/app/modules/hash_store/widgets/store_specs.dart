import 'package:flutter/material.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

/// Spec definitions by `key` across every category; a product can sit in
/// several categories and the keys are stable.
Map<String, Map> storeSpecDefs(List<Map<String, dynamic>> categories) => {
  for (final c in categories.reversed)
    for (final s in (c['specifications'] as List? ?? []).whereType<Map>())
      if (s['key'] is String) s['key'] as String: s,
};

/// Human text for a spec or option value, with the definition's unit.
String storeSpecValue(Object? value, [Map? def]) {
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) return value.map((v) => storeSpecValue(v, def)).join(', ');
  final unit = def?['unit'];
  return unit == null || '$unit'.isEmpty ? '$value' : '$value $unit';
}

String storeSpecLabel(String key, Map<String, Map> defs) =>
    '${defs[key]?['label'] ?? key}';

/// `{id, sku, options, prices, pricing, offers, available}` rows.
List<Map> storeVariants(Map product) =>
    (product['variants'] as List? ?? []).whereType<Map>().toList();

bool storeSkuBuyable(Map product) {
  final available = product['available'];
  return (storeCardPrice(product).price ?? 0) > 0 &&
      (available == null || storeNum(available) > 0);
}

/// [product] with the default-SKU fields swapped for [variant]'s, so the
/// existing price, stock and cart code works on the selected SKU.
Map<String, dynamic> storeWithVariant(
  Map<String, dynamic> product,
  Map variant,
) {
  final inr = (variant['prices'] as List? ?? []).whereType<Map>().where(
    (p) => p['currency_code'] == 'inr',
  );
  final out = {
    ...product,
    'variant_id': variant['id'],
    'available': variant['available'],
    'offers': variant['offers'] ?? const [],
    'price_inr': inr.firstOrNull?['amount'],
    'pricing': variant['pricing'],
  };
  // storeCardPrice reads `pricing` whenever the key exists.
  if (variant['pricing'] == null) out.remove('pricing');
  // The product MRP belongs to the default SKU only.
  if (variant['id'] != product['variant_id']) {
    out.remove('compare_at_price_inr');
  }
  return out;
}

/// Lowest to highest price over priced SKUs, or null for a single price.
({num low, num high})? storePriceRange(Map product) {
  final prices = [
    for (final v in storeVariants(product))
      storeCardPrice(
        storeWithVariant(Map<String, dynamic>.from(product), v),
      ).price,
  ].whereType<num>().where((p) => p > 0).toList()..sort();
  if (prices.isEmpty || prices.first == prices.last) return null;
  return (low: prices.first, high: prices.last);
}

/// A small selectable pill for SKU options and filters.
class StoreOptionChip extends StatelessWidget {
  final String label;
  final bool selected;

  /// Shown dimmed: no SKU (or no buyable SKU) matches it right now.
  final bool muted;
  final VoidCallback? onTap;
  const StoreOptionChip({
    super.key,
    required this.label,
    required this.selected,
    this.muted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? StoreColors.purple.withValues(alpha: 0.25)
              : StoreColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? StoreColors.purpleSoft : StoreColors.border,
          ),
        ),
        child: Text(
          label,
          style: storeBody(
            size: 13,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
            color: muted ? StoreColors.faint : Colors.white,
          ).copyWith(decoration: muted ? TextDecoration.lineThrough : null),
        ),
      ),
    ),
  );
}

/// Opens the filter sheet for [specs] (the category's filterable
/// definitions) and returns the new selection, or null when dismissed.
Future<Map<String, List<Object>>?> showStoreFilters(
  BuildContext context, {
  required List<Map> specs,
  required Map<String, List<Object>> current,
}) => showModalBottomSheet<Map<String, List<Object>>>(
  context: context,
  isScrollControlled: true,
  backgroundColor: StoreColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _FilterSheet(specs: specs, current: current),
);

/// Values a filter can offer: declared choices, or Yes/No for booleans.
// shortcut: number and free-text fields without `choices` get no filter;
// add range/text inputs if sellers need them.
List<Object> storeFilterChoices(Map spec) => spec['type'] == 'boolean'
    ? const [true, false]
    : (spec['choices'] as List? ?? [])
          .map((c) => c is Map ? c['value'] : c)
          .whereType<Object>()
          .toList();

class _FilterSheet extends StatefulWidget {
  final List<Map> specs;
  final Map<String, List<Object>> current;
  const _FilterSheet({required this.specs, required this.current});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final _picked = {
    for (final e in widget.current.entries) e.key: [...e.value],
  };

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
            child: Row(
              children: [
                Expanded(child: Text('Filters', style: storeTitle(20))),
                TextButton(
                  onPressed: () => setState(_picked.clear),
                  child: Text(
                    'Clear',
                    style: storeBody(color: StoreColors.purpleSoft),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                for (final spec in widget.specs) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${spec['label'] ?? spec['key']}',
                    style: storeBody(size: 13, color: StoreColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in storeFilterChoices(spec))
                        Builder(
                          builder: (_) {
                            final key = spec['key'] as String;
                            final on = _picked[key]?.contains(value) ?? false;
                            return StoreOptionChip(
                              label: storeSpecValue(value, spec),
                              selected: on,
                              onTap: () => setState(() {
                                final list = _picked[key] ??= [];
                                on ? list.remove(value) : list.add(value);
                                if (list.isEmpty) _picked.remove(key);
                              }),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: StoreButton(
              label: 'Show results',
              onTap: () => Navigator.pop(context, _picked),
            ),
          ),
        ],
      ),
    ),
  );
}
