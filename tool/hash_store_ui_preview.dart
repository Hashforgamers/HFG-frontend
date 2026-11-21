// Local visual QA only. No authentication, store requests or payments.
import 'package:flutter/material.dart';
import 'package:hash/app/modules/hash_store/widgets/store_page_intro.dart';
import 'package:hash/app/modules/hash_store/widgets/store_product_card.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const _Preview(),
  ),
);

class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050506),
    body: SafeArea(
      child: ListView(
        children: [
          const StorePageIntro(
            eyebrow: 'Hash Shop',
            title: 'Upgrade your game.',
            subtitle: 'Gear for your setup. Sessions for your next win.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StoreProductCard(
              product: const {
                'title': 'Hash pro mouse pad',
                'vendor_name': 'Hash Gear',
                'description':
                    'XL cloth pad with stitched edges. Built for your next session.',
                'price_inr': 799,
                'available': 8,
                'kind': 'product',
              },
              onDetails: () {},
              onAdd: () {},
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StoreProductCard(
              product: const {
                'title': 'PS5 gaming session · 1 hour',
                'vendor_name': 'Hash Arena',
                'description': 'Book a console bay at the arena.',
                'price_inr': 400,
                'available': 0,
                'kind': 'service',
              },
              onDetails: () {},
              onAdd: () {},
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}
