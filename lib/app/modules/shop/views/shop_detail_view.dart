import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../reviews/views/review_view.dart';
import '../controllers/cart_controller.dart';
import '../controllers/fetch_products_by_id_controller.dart';
import '../products_model.dart';
import 'cart_view.dart';

class ProductDetailView extends StatefulWidget {
  final String productId;
  final String productImages;

  const ProductDetailView(
      {super.key, required this.productId, required this.productImages});

  @override
  _ProductDetailViewState createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 200.0;
  final GetProductByIdController controller =
      Get.put(GetProductByIdController());

  @override
  void initState() {
    super.initState();
    controller.fetchProductById(widget.productId);
    _scrollController.addListener(() {
      double offset = _scrollController.offset;
      setState(() {
        _imageHeight = (200.0 - offset).clamp(0, 200.0);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());
    cartController.fetchCart(); // Fetch cart items on page load
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Product Details',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back,
            color: Color(0xff00D701),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Get.to(CartView());
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() => Badge(
                    label: Text(
                      '${cartController.cartItems.length}',
                      style:
                          GoogleFonts.inter(color: Colors.white, fontSize: 10),
                    ),
                    child: const Icon(CupertinoIcons.bag, color: Colors.white),
                  )),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.errorMessage.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        } else if (controller.product.value != null) {
          final product = controller.product.value;
          print('product ${controller.isLoading.value}');

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 160),
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: const ShapeDecoration(
                          color: Colors.white10,
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(104)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 50),
                            Text(
                              product!.name,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₹${(product.price + 122).toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.normal,
                                          decoration:
                                              TextDecoration.lineThrough),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      '₹${product.price.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                          color: const Color(0xff00D701),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.yellow, size: 18),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${product.rating.average} (${product.rating.count} reviews)',
                                      style: GoogleFonts.inter(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const SizedBox(height: 20),
                            Text(
                              'Availability: ${product.availability.inStock ? "In Stock" : "Out of Stock"}',
                              style: GoogleFonts.inter(
                                  color: const Color(0xff00D701), fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Description',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product.description,
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Specifications',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildSpecifications(product),
                            const SizedBox(height: 30),
                            Text(
                              'Customer Reviews',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ReviewPage(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CachedNetworkImage(
                    imageUrl: widget.productImages,
                    height: _imageHeight,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text('No product found'));
        }
      }),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle product buy now tap
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00D701),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Buy Now'),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[850], // Match the background color
                ),
                child: const Icon(CupertinoIcons.bag_badge_plus,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecifications(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpecificationRow('Category', product.category),
        _buildSpecificationRow('Manufacturer', product.manufacturer),
        _buildSpecificationRow('SKU', product.sku),
        _buildSpecificationRow('Color', product.nonElectronic.color),
        _buildSpecificationRow('Material', product.nonElectronic.material),
        _buildSpecificationRow('Size', product.nonElectronic.size),
        _buildSpecificationRow(
            'Compatibility', product.electronic.compatibility),
        _buildSpecificationRow('Connectivity', product.electronic.connectivity),
        _buildSpecificationRow(
            'Power Consumption', product.electronic.powerConsumption),
        _buildSpecificationRow('Dimensions (L x W x H)',
            '${product.dimensions.length} x ${product.dimensions.width} x ${product.dimensions.height} ${product.dimensions.unit}'),
        _buildSpecificationRow(
            'Weight', '${product.weight.value} ${product.weight.unit}'),
      ],
    );
  }

  Widget _buildSpecificationRow(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Text(
            '$key: ',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: Get.width * 0.45,
            child: Text(value,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
