import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_orders_cubit.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

import '../../../data/services/user_controller.dart';

class HashStoreOrdersView extends StatefulWidget {
  const HashStoreOrdersView({super.key});

  @override
  State<HashStoreOrdersView> createState() => _HashStoreOrdersViewState();
}

class _HashStoreOrdersViewState extends State<HashStoreOrdersView> {
  final userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HashStoreOrdersCubit()..fetchOrders(),
      child: BlocBuilder<HashStoreOrdersCubit, HashStoreOrdersState>(
        builder: (context, state) {
          return Scaffold(
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
                              'Hey ${userController.user.value.gameUserName}, Your Orders',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            if (state is HashStoreOrdersLoaded)
                              Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 10),
                                      Text(
                                        "Latest Purchase",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.orders.isNotEmpty ? 1 : 0,
                                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                                    itemBuilder: (context, index) {
                                      final product = state.orders.first;
                                      return _buildProductCard(
                                        title: product['title'] ?? '',
                                        price: product['price'] ?? '',
                                        dateOfPurchase: product['date'] ?? '',
                                        paymentMode: product['mode'] ?? '',
                                        productImage: product['productImage'],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 10),
                                      Text(
                                        "Transaction History",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.orders.length > 1 ? state.orders.sublist(1).length : 0,
                                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                                    itemBuilder: (context, index) {
                                      final product = state.orders.sublist(1)[index];
                                      return _buildProductCard(
                                        title: product['title'] ?? '',
                                        price: product['price'] ?? '',
                                        dateOfPurchase: product['date'] ?? '',
                                        paymentMode: product['mode'] ?? '',
                                        productImage: product['productImage'],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            if (state is HashStoreOrdersError)
                              Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
                            if (state is! HashStoreOrdersLoaded && state is! HashStoreOrdersError)
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Centered loader when loading
                if (state is HashStoreOrdersLoading)
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
    required String title,
    required String price,
    required String dateOfPurchase,
    required String paymentMode,
    String? productImage,
  }) {
    return BounceTap(
      onTap: () {
        print('Tapped $title');
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹$price",
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date of Purchase:",
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              "Mode of Payment:",
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateOfPurchase,
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              paymentMode,
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
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