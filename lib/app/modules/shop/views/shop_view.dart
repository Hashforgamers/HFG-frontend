import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/shop/controllers/cart_controller.dart';
import '../controllers/fetch_products_controller.dart';
import '../products_model.dart';
import 'cart_view.dart';
import 'shop_detail_view.dart';

class ShopView extends StatelessWidget {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductsController productsController = Get.put(ProductsController());
    final CartController cartController = Get.put(CartController());
    cartController.fetchCart(); // Fetch cart items on page load

    // final List<Product> gamingMice = List.generate(
    //   5,
    //       (index) => Product(
    //     name: 'Gaming Mouse ${index + 1}',
    //     imageUrl: 'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png', // Replace with actual image URLs
    //     price: '${(index + 1) * 500}', description: '', specifications: [],
    //   ),
    // );
    //
    // final List<Product> keyboards = List.generate(
    //   5,
    //       (index) => Product(
    //     name: 'Hash. Mechanical HX230${index + 1}',
    //     imageUrl: 'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png', // Replace with actual image URLs
    //     price: '${(index + 1) * 700}', description: '', specifications: [],
    //   ),
    // );
    //
    // final List<Product> rams = List.generate(
    //   5,
    //       (index) => Product(
    //     name: 'RAM ${index + 1}',
    //     imageUrl: 'https://www.pngall.com/wp-content/uploads/5/Gaming-RAM-PNG-Image.png', // Replace with actual image URLs
    //     price: '${(index + 1) * 800}', description: '', specifications: [],
    //   ),
    // );
    //
    // final List<Product> headsets = List.generate(
    //   5,
    //       (index) => Product(
    //     name: 'Headset ${index + 1}',
    //     imageUrl: 'https://www.pngall.com/wp-content/uploads/5/Logitech-Gaming-Headset.png', // Replace with actual image URLs
    //     price: '${(index + 1) * 1000}', description: '', specifications: [],
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Shop', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
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
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: Icon(CupertinoIcons.bag, color: Colors.white),
              )),
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
      body: Obx(() {
        if (productsController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else if (productsController.errorMessage.value.isNotEmpty) {
          return Center(child: Text(productsController.errorMessage.value, style: TextStyle(color: Colors.white)));
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: _buildSection('Products', productsController.products),
          );
        }
      }),
    );
  }

  Widget _buildSection(String title, List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 100,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: Get.height-345, // Adjust the height as needed
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    CartController cartController=Get.put(CartController());
    int qty=0;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          width: Get.width * 0.83,
          margin: EdgeInsets.only(right: 10, left: 55,bottom: 20),
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
                  Get.to(ProductDetailView(productId: product.id));
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.0, right: 15),
                  child: Icon(CupertinoIcons.heart, size: 20, color: Colors.red),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(ProductDetailView(productId: product.id));
                },
                child: Container(
                  width: Get.width * 0.57,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₹${product.price}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: (){

                        cartController.addToCart(product.id, qty+1);
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(CupertinoIcons.bag_badge_plus),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle product button tap
                        },
                        style: ElevatedButton.styleFrom(
                          primary: const Color(0xff00D701),
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          minimumSize: Size(double.infinity, 30),
                        ),
                        child: const Text(
                          'Buy',
                          style: TextStyle(color: Colors.black),
                        ),
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
            Get.to(ProductDetailView(productId: product.id));
          },
          child: Container(
            margin: EdgeInsets.only(top: 15),
            child: Image.network(
               'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
              // product.images.isNotEmpty ? product.images[0].url : 'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
              width: Get.width * 0.5,
              height: 125,
            ),
          ),
        ),
      ],
    );
  }
}
