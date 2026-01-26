import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_categories_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_cart_view.dart';
import 'package:hash/app/modules/hash_store/widgets/hash_store_app_bar.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HashStoreCategoriesCubit()..fetchCategories(),
      child: BlocBuilder<HashStoreCategoriesCubit, HashStoreCategoriesState>(
        builder: (context, state) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HashStoreCartView()));
              },
              child: Icon(Icons.arrow_forward),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Categories',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (state is HashStoreCategoriesLoaded)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.categories.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 20),
                                itemBuilder: (context, index) {
                                  final category = state.categories[index];
                                  return _buildProductCard(
                                    title: category['title'] ?? '',
                                    productImage: category['productImage'],
                                  );
                                },
                              ),
                            if (state is HashStoreCategoriesError)
                              Center(child: Text(state.message, style: const TextStyle(color: Colors.red))),
                            if (state is! HashStoreCategoriesLoaded && state is! HashStoreCategoriesError)
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Centered loader when loading
                if (state is HashStoreCategoriesLoading)
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
    String? productImage,
  }) {
    return BounceTap(
      onTap: () {
        print('Tapped $title');
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF412D65), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (productImage != null)
                Image.asset(
                  productImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
            ],
          ),
        ),
      ),
    );
  }
}