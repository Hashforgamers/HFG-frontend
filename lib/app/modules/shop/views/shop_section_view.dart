import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/shop/views/shop_detail_view.dart';
import '../controllers/fetch_products_controller.dart';

class ShopSection extends StatelessWidget {
  final ProductsController controller = Get.put(ProductsController());
  bool isSale=true;
  @override
  Widget build(BuildContext context) {
    controller.fetchProducts();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE SHOP',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          } else if (controller.errorMessage.isNotEmpty) {
            return Center(child: Text(controller.errorMessage.value));
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.products.map((product) {
                  return _buildShopItem(product.name, '₹${product.price}', product.images.first.url,productId:product.id);
                }).toList(),
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _buildShopItem(String title, String price, String imageUrl, {required String productId}) {
    print(imageUrl);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: 150,
      height: 250,
      decoration: BoxDecoration(
        color: Color(0xff1E1E1E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isSale?
          Container(
            padding: EdgeInsets.symmetric(vertical: 2),
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              gradient: LinearGradient(
                colors: [
                  Color(0xffdf1b1b),
                  Color(0xffd62121),
                  Color(0xffce2525),
                  Color(0xffc72c2c),

                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'SALE',
                style: TextStyle(
                  fontSize: 14, // Increased font size for emphasis
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black26,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ):SizedBox(),
          GestureDetector(
            onTap: (){
              Get.to(ProductDetailView(productId:productId ,));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 100,
                width: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  price,
                  style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xff00D701),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Get it now'),
                ),
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(CupertinoIcons.bag_badge_plus),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
