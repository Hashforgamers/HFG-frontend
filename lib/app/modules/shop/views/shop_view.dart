import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/shop/controllers/cart_controller.dart';
import 'package:lottie/lottie.dart';
import '../controllers/fetch_products_controller.dart';
import '../products_model.dart';
import 'cart_view.dart';
import 'shop_detail_view.dart';

class ShopView extends StatelessWidget {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.put(CartController());
    cartController.fetchCart(); // Fetch cart items on page load
    final List<Product> products = [
      Product(
        availability: Availability(inStock: true, quantity: 50),
        category: 'Gaming Accessories',
        currency: 'INR',
        description: 'High-quality gaming mouse with RGB lighting.',
        dimensions: Dimensions(height: 5.0, length: 12.0, width: 8.0, unit: 'cm'),
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
            url: 'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png',
          )
        ],
        manufacturer: 'Razer',
        name: 'Gaming Mouse 1',
        nonElectronic: NonElectronic(color: 'Black', material: 'Plastic', size: 'Standard', item: null),
        price: 1599.99,
        rating: Rating(average: 4.5, count: 120),
        sku: 'GM123',
        weight: Weight(unit: 'kg', value: 0.15),
      ),
      Product(
        availability: Availability(inStock: true, quantity: 30),
        category: 'Keyboards',
        currency: 'INR',
        description: 'Mechanical gaming keyboard with customizable RGB lighting.',
        dimensions: Dimensions(height: 3.5, length: 45.0, width: 15.0, unit: 'cm'),
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
            url: 'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
          )
        ],
        manufacturer: 'Logitech',
        name: 'Gaming Keyboard Pro',
        nonElectronic: NonElectronic(color: 'Black', material: 'Aluminum', size: 'Full Size', item: null),
        price: 3499.99,
        rating: Rating(average: 4.7, count: 85),
        sku: 'GK456',
        weight: Weight(unit: 'kg', value: 1.2),
      ),
      Product(
        availability: Availability(inStock: true, quantity: 20),
        category: 'Memory',
        currency: 'INR',
        description: 'High-performance DDR4 RAM for gaming PCs.',
        dimensions: Dimensions(height: 2.5, length: 14.0, width: 0.5, unit: 'cm'),
        electronic: Electronic(
          compatibility: 'Desktop',
          connectivity: 'NA',
          item: 'RAM',
          powerConsumption: '1.2V',
        ),
        id: '3',
        images: [
          ProductImage(
            altText: 'Gaming RAM',
            url: 'https://www.pngall.com/wp-content/uploads/5/Gaming-RAM-PNG-Image.png',
          )
        ],
        manufacturer: 'Corsair',
        name: 'Gaming RAM 16GB',
        nonElectronic: NonElectronic(color: 'Black', material: 'PCB', size: '16GB', item: null),
        price: 5999.99,
        rating: Rating(average: 4.8, count: 200),
        sku: 'GR789',
        weight: Weight(unit: 'kg', value: 0.1),
      ),
      Product(
        availability: Availability(inStock: false, quantity: 0),
        category: 'Headsets',
        currency: 'INR',
        description: 'Immersive gaming headset with 7.1 surround sound.',
        dimensions: Dimensions(height: 8.0, length: 18.0, width: 18.0, unit: 'cm'),
        electronic: Electronic(
          compatibility: 'PC, Console',
          connectivity: 'Wired',
          item: 'Headset',
          powerConsumption: 'NA',
        ),
        id: '4',
        images: [
          ProductImage(
            altText: 'Gaming Headset',
            url: 'https://www.pngall.com/wp-content/uploads/5/Logitech-Gaming-Headset.png',
          )
        ],
        manufacturer: 'SteelSeries',
        name: 'Gaming Headset Pro',
        nonElectronic: NonElectronic(color: 'Black & Orange', material: 'Plastic', size: 'Adjustable', item: null),
        price: 6999.99,
        rating: Rating(average: 4.2, count: 60),
        sku: 'GH101',
        weight: Weight(unit: 'kg', value: 0.8),
      ),
    ];
    final List<Product> productsController = products;

    List <String> productImage=[
      'https://images.gopuff.com/blob/gopuffcatalogstorageprod/catalog-images-container/resize/cf/version=1_2,format=auto,fit=scale-down,width=800,height=800/afb39750-5af9-4ba3-a4f7-a4c526d68d94-background_removed.png',

      'https://www.pngall.com/wp-content/uploads/5/Gaming-RAM-PNG-Image.png',
      'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
      'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png',
      'https://www.pngall.com/wp-content/uploads/5/Logitech-Gaming-Headset.png',
          'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
      'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png',
      'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
      'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
      'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png',
      'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
      'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
      'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png',
      'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',

    ];
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
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: SingleChildScrollView(child: _buildSection('Products', productsController,productImage)),
      )
      // Obx(() {
      //   if (productsController.isLoading.value) {
      //     return Center(child: CircularProgressIndicator());
      //   } else if (productsController.errorMessage.value.isNotEmpty) {
      //     return Center(child: Text(productsController.errorMessage.value, style: TextStyle(color: Colors.white)));
      //   } else {
      //     return Padding(
      //       padding: const EdgeInsets.symmetric(vertical: 10.0),
      //       child: _buildSection('Products', productsController.products,productImage),
      //     );
      //   }
      // }),
    );
  }

  Widget _buildSection(String title, List<Product> products, List<String> productImage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index], productImage[index]);
            },
          ),
        ],
      ),
    );
  }


  Widget _buildProductCard(Product product, String productImage) {
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
                onTap: () {Fluttertoast.showToast(
                  msg: "Coming Soon",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
                  // Get.to(ProductDetailView(productId: product.id,productImages:));
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.0, right: 15),
                  child: Icon(CupertinoIcons.heart, size: 20, color: Colors.red),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(ProductDetailView(productId: product.id,productImages:productImage));
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: (){
                        Fluttertoast.showToast(
                          msg: "Coming Soon",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                        // cartController.addToCart(product.id, qty+1);
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(CupertinoIcons.bag_badge_plus),
                      ),
                    ),
                    SizedBox(width: 10,),
                    ElevatedButton(
                      onPressed: () {
                        // Handle product button tap
                        Fluttertoast.showToast(
                                                msg: "Coming Soon",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.CENTER,
                                                timeInSecForIosWeb: 1,
                                                backgroundColor: Colors.red,
                                                textColor: Colors.white,
                                                fontSize: 16.0,
                                              );
                      },
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xff00D701),
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock,color: Colors.black,size: 16,),
                          SizedBox(width: 5,),
                          const Text(
                            'Coming Soon',
                            style: TextStyle(color: Colors.black),
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
            // Get.to(ProductDetailView(productId: product.id, productImages: productImage,));
            Fluttertoast.showToast(
              msg: "Coming Soon",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          },
          child: Stack(alignment: Alignment.centerLeft,
            children: [
              ImageFiltered(
                  
                  imageFilter: ImageFilter.blur(sigmaX: 33,sigmaY: 32),
                  child: Transform.rotate(
                      
                      angle: 100,
                      child: Lottie.asset('assets/Animation - 1732554237164.json',height: 80))),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Image.network(
                  productImage,
                  fit: BoxFit.fitWidth,
                  // product.images.isNotEmpty ? product.images[0].url : 'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
                  width: Get.width * 0.48,

                  height: 125,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
