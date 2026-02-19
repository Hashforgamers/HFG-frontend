import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:lottie/lottie.dart';

import '../../../../utils/widgets/loader.dart';
import '../products_model.dart';

class ShopSection extends StatelessWidget {
  const ShopSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> products = [
      Product(
        availability: Availability(inStock: true, quantity: 50),
        category: 'Gaming Accessories',
        currency: 'INR',
        description: 'High-quality gaming mouse with RGB lighting.',
        dimensions: Dimensions(
          height: 5.0,
          length: 12.0,
          width: 8.0,
          unit: 'cm',
        ),
        electronic: Electronic(
          compatibility: 'PC, Mac',
          connectivity: 'Wireless',
          item: 'Mouse',
          powerConsumption: '5W',
        ),
        id: '1',
        images: [
          ProductImage(
            altText: 'Gaming Mouse',
            url:
                'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png',
          ),
        ],
        manufacturer: 'Razer',
        name: 'Gaming Mouse 1',
        nonElectronic: NonElectronic(
          color: 'Black',
          material: 'Plastic',
          size: 'Standard',
          item: null,
        ),
        price: 1599.99,
        rating: Rating(average: 4.5, count: 120),
        sku: 'GM123',
        weight: Weight(unit: 'kg', value: 0.15),
      ),
      Product(
        availability: Availability(inStock: true, quantity: 30),
        category: 'Keyboards',
        currency: 'INR',
        description:
            'Mechanical gaming keyboard with customizable RGB lighting.',
        dimensions: Dimensions(
          height: 3.5,
          length: 45.0,
          width: 15.0,
          unit: 'cm',
        ),
        electronic: Electronic(
          compatibility: 'PC',
          connectivity: 'Wired',
          item: 'Keyboard',
          powerConsumption: '10W',
        ),
        id: '2',
        images: [
          ProductImage(
            altText: 'Gaming Keyboard',
            url:
                'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
          ),
        ],
        manufacturer: 'Logitech',
        name: 'Gaming Keyboard Pro',
        nonElectronic: NonElectronic(
          color: 'Black',
          material: 'Aluminum',
          size: 'Full Size',
          item: null,
        ),
        price: 3499.99,
        rating: Rating(average: 4.7, count: 85),
        sku: 'GK456',
        weight: Weight(unit: 'kg', value: 1.2),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HASH QUEST',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075181/hashQuestBg_mkuqee.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const Center(child: RainbowGlowingLoader(size: 40)),
                  errorWidget: (_, _, _) => Container(
                    color: Colors.grey,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hash Headphones',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'premium quality leather with foam \ncushion for maximum comfort.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: const Color(0xff00DC00),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Pre-Register',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 16,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://res.cloudinary.com/dxjjigepf/image/upload/v1755075181/headphone_ruavro.png',
                  height: 180,
                  width: 140,
                  placeholder: (_, _) =>
                      const Center(child: RainbowGlowingLoader(size: 40)),
                  errorWidget: (_, _, _) => Container(
                    color: Colors.grey,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                right: 16,
                child: Transform.rotate(
                  angle: 170,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff00DC00),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '₹2499',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final String productImage;

  const ProductCard({
    super.key,
    required this.product,
    required this.productImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          width: Get.width * 0.8,
          margin: const EdgeInsets.only(right: 10, left: 55, bottom: 20),
          decoration: ShapeDecoration(
            color: Colors.white12,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(65),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFavoriteIcon(),
              _buildProductDetails(),
              _buildBottomRow(),
            ],
          ),
        ),
        _buildProductImage(),
      ],
    );
  }

  Widget _buildFavoriteIcon() {
    return GestureDetector(
      onTap: () => _showComingSoonToast(),
      child: const Padding(
        padding: EdgeInsets.only(top: 15.0, right: 15),
        child: Icon(CupertinoIcons.heart, size: 20, color: Colors.red),
      ),
    );
  }

  Widget _buildProductDetails() {
    return GestureDetector(
      onTap: () => _showComingSoonToast(),
      child: Container(
        width: Get.width * 0.5,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              product.name,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '₹${product.price}',
              style: GoogleFonts.inter(color: const Color(0xff00DC00), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => _showComingSoonToast(),
            child: const Icon(
              CupertinoIcons.bag_badge_plus,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _showComingSoonToast(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff00DC00),
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.black, size: 16),
                const SizedBox(width: 5),
                Text(
                  'Coming Soon',
                  style: GoogleFonts.inter(color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return GestureDetector(
      onTap: () => _showComingSoonToast(),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 33, sigmaY: 32),
            child: Transform.rotate(
              angle: 100,
              child: Lottie.asset(
                'assets/Animation - 1732554237164.json',
                height: 80,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: CachedNetworkImage(
              imageUrl: productImage,
              fit: BoxFit.fitWidth,
              width: Get.width * 0.45,
              height: 150,
              placeholder: (context, url) =>
                  Center(child: AppLinearLoader()),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonToast() {
    Fluttertoast.showToast(
      msg: "Coming Soon",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
