import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_orders_view.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:hive/hive.dart';
import 'package:hash/core/utils/app_logger.dart';

class HashStoreCartView extends StatefulWidget {
  const HashStoreCartView({super.key});

  @override
  State<HashStoreCartView> createState() => _HashStoreCartViewState();
}

class _HashStoreCartViewState extends State<HashStoreCartView> {
  @override
  void initState() {
    super.initState();
    // Ensure fetchCart is called when the widget is built
  }

  double getTotalPrice(List<Map<String, dynamic>> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      int qty = item['quantity'] is int
          ? item['quantity']
          : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      total += price * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HashStoreCartCubit()..fetchCart(), // Trigger fetch on creation
      child: BlocBuilder<HashStoreCartCubit, HashStoreCartState>(
        builder: (context, state) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HashStoreOrdersView()));
              },
              child: const Icon(Icons.arrow_forward),
            ),
            body: Stack(
              children: [
                // Main content
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const HashStoreAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Your Cart',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (state is HashStoreCartLoaded)
                              Column(
                                children: [
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.cartItems.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                                    itemBuilder: (context, index) {
                                      final item = state.cartItems[index];
                                      final cubit = context.read<HashStoreCartCubit>();
                                      return _buildProductCard(
                                        index: index,
                                        title: item['title'] ?? '',
                                        price: item['price']?.toString() ?? '',
                                        productImage: item['productImage'],
                                        quantity: item['quantity'] is int
                                            ? item['quantity']
                                            : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
                                        onIncrement: () => cubit.incrementQuantity(index),
                                        onDecrement: () => cubit.decrementQuantity(index),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(color: Color(0xFF7A44C0)),
                                  const SizedBox(height: 20),
                                  ...state.cartItems.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${item['title']} (${item['quantity']})",
                                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                                        ),
                                        Text(
                                          "Rs. ${(double.tryParse(item['price']?.toString() ?? '0')! * (item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1)).toStringAsFixed(2)}",
                                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "Rs. ${getTotalPrice(state.cartItems).toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  BounceTap(
                                    onTap: () {},
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Check Out",
                                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      const Text(
                                        "Shipping Address",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {},
                                        child: const Text(
                                          "Edit",
                                          style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            if (state is HashStoreCartError)
                              Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
                            if (state is! HashStoreCartLoaded && state is! HashStoreCartError)
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Centered loader when loading
                if (state is HashStoreCartLoading)
                  const Center(
                    child: RainbowGlowingLoader(size: 60),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard({
    required int index,
    required String title,
    required String price,
    required int quantity,
    String? productImage,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return BounceTap(
      onTap: () {
        AppLogger.d('Tapped $title');
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7A44C0), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          "₹$price",
                          style: GoogleFonts.inter(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFF412D65)),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: onDecrement,
                                child: const Icon(Icons.remove),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "$quantity",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 3),
                              InkWell(
                                onTap: onIncrement,
                                child: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (productImage != null)
                      Image.asset(
                        productImage,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.contain,
                      ),
                    if (productImage == null) const Icon(Icons.error_outline, size: 20),
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