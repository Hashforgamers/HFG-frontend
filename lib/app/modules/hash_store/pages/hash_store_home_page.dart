import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_home_cubit.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class HashStoreHomePage extends StatefulWidget {
  const HashStoreHomePage({super.key});

  @override
  State<HashStoreHomePage> createState() => _HashStoreHomePageState();
}

class _HashStoreHomePageState extends State<HashStoreHomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HashStoreHomeCubit()..fetchProducts(),
      child: BlocBuilder<HashStoreHomeCubit, HashStoreHomeState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Main content
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const HashStoreAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Buy our Exclusive Hash Products',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (state is HashStoreHomeLoaded)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.products.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final product = state.products[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(
                                      milliseconds: 340 + (index * 90),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 18 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildProductCard(
                                      title: product['title'] ?? '',
                                      description: product['description'] ?? '',
                                      price: product['price'],
                                      backgroundImage:
                                          product['backgroundImage'],
                                      productImage: product['productImage'],
                                    ),
                                  );
                                },
                              ),
                            if (state is HashStoreHomeError)
                              Center(
                                child: Text(
                                  state.message,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            if (state is! HashStoreHomeLoaded &&
                                state is! HashStoreHomeError)
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Centered loader when loading
                if (state is HashStoreHomeLoading)
                  const Center(child: RainbowGlowingLoader(size: 60)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard({
    required String title,
    required String description,
    String? price,
    String? backgroundImage,
    String? productImage,
  }) {
    return BounceTap(
      onTap: () {
        AppLogger.d('Tapped $title');
      },
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7A44C0).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                backgroundImage ?? 'assets/hash_store_images/fallback_bg.jpg',
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text and button
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(right: 55),
                          child: Text(
                            description,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (price != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "₹$price",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        BounceTap(
                          onTap: () {
                            AppLogger.d('Add to Cart: $title');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xff00DC00),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Add to Cart',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Product image
                  if (productImage != null)
                    Image.asset(
                      productImage,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
