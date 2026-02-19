import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/shop/controllers/cart_controller.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/glow_neon_loader.dart';
import 'package:lottie/lottie.dart';
import '../../../../utils/widgets/loader.dart';
import '../products_model.dart';
import 'cart_view.dart';
import 'shop_detail_view.dart';
import '../services/pre_registration_service.dart';
import '../models/pre_registration_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/product_service.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  final ProductService _productService = ProductService();
  UserController userController = Get.put(UserController());
  final segmentService = locator<SegmentSdkService>();

  final List<Product> products = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final loadedProducts = await _productService.getProducts();
      setState(() {
        products.clear();
        products.addAll(loadedProducts);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color(0xff00DC00),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _handlePreRegistration(Product product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showToast("Please login to pre-register");
        return;
      }

      final preRegistrationService = PreRegistrationService();

      // Check if already registered
      final bool isRegistered = await preRegistrationService
          .isAlreadyRegistered(user.uid, product.id);

      if (isRegistered) {
        _showToast("You have already pre-registered for this product");
        return;
      }

      final registration = PreRegistration(
        userId: user.uid,
        productId: product.id,
        productName: product.name,
        productPrice: product.price,
        registrationDate: DateTime.now(),
      );

      await preRegistrationService.savePreRegistration(registration);
      _showToast("Successfully Pre-Registered");
      _loadProducts(); // Reload products to update the count
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());
    cartController.fetchCart(); // Fetch cart items on page load

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Shop',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        actions: [
          GestureDetector(
            onTap: () {
              Get.to(CartView());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Badge(
                  label: Text(
                    '${cartController.cartItems.length}',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                  ),
                  child: const Icon(CupertinoIcons.bag, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: isLoading
          ? Center(child: AppLinearLoader())
          : errorMessage.isNotEmpty
          ? Center(
              child: Text(
                errorMessage,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              child: SingleChildScrollView(
                child: _buildSection('Products', products),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final productImage = product.images.isNotEmpty
                ? product.images[0].url
                : 'https://via.placeholder.com/150';
            return _buildProductCard(
              context,
              product,
              productImage,
            ); // pass context
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    String productImage,
  ) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final renderW = (Get.width * 0.48);
    const renderH = 125.0;
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          width: Get.width * 0.83,
          margin: const EdgeInsets.only(left: 45, bottom: 20),
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
              GestureDetector(
                onTap: () {
                  _showToast("Coming Soon");
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 15.0, right: 20),
                  child: Icon(
                    CupertinoIcons.heart,
                    size: 20,
                    color: Colors.red,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(
                    ProductDetailView(
                      productId: product.id,
                      productImages: productImage,
                    ),
                  );
                },
                child: Container(
                  width: Get.width * 0.57,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
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
                        style: GoogleFonts.inter(
                          color: const Color(0xff00DC00),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${product.preRegisterCount} Pre-Registered',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Track product pre-registered event
                        segmentService.onProductPreRegistered(
                          email:
                              userController
                                  .user
                                  .value
                                  .contact
                                  ?.electronicAddress
                                  ?.emailId ??
                              '',
                          productName: product.name,
                        );

                        _showToast("Coming Soon");
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(CupertinoIcons.bag_badge_plus),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _handlePreRegistration(product);
                      },
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
                            'Pre-Register',
                            style: GoogleFonts.inter(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            _showToast("Coming Soon");
          },
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
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 7,
                    sigmaY: 7,
                  ), // adjust 8–16 as you like
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: productImage,
                      fit: BoxFit.cover,
                      width: renderW,
                      height: renderH,
                      // request an appropriately sized decode for smooth blur (no unnecessary VRAM)
                      memCacheWidth: (renderW * dpr).round(),
                      memCacheHeight: (renderH * dpr).round(),
                      placeholder: (_, __) =>
                          const Center(child: RainbowGlowingLoader(size: 24)),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
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
