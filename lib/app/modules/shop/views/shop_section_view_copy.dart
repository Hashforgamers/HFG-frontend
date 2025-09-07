import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220, // Adjust height for product cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productImage = product.images.isNotEmpty
                  ? product.images[0].url
                  : 'https://via.placeholder.com/150';
              return ProductCard(product: product, productImage: productImage);
            },
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
              style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 14),
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
              backgroundColor: const Color(0xff00D701),
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
                   Center(child: RainbowLoadingBar()),
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
