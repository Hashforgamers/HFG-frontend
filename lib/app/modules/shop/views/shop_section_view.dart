import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShopSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE SHOP',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildShopItem(
                  'Boat ultra gaming headset', '₹2,000', 'https://www.onbeli.com/cdn/shop/collections/gaming-accessories-onbeli.jpg?v=1657265527'),
              _buildShopItem(
                  'Round-neck T Shirt', '₹2,000', 'https://www.onbeli.com/cdn/shop/collections/gaming-accessories-onbeli.jpg?v=1657265527'),
              _buildShopItem(
                  'Gaming Mouse', '₹1,500', 'https://www.onbeli.com/cdn/shop/collections/gaming-accessories-onbeli.jpg?v=1657265527'),
              _buildShopItem(
                  'Gaming Keyboard', '₹3,500', 'https://www.onbeli.com/cdn/shop/collections/gaming-accessories-onbeli.jpg?v=1657265527'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShopItem(String title, String price, String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: 150,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight:  Radius.circular(10),),

            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 100,
              width: 150,

              fit: BoxFit.cover,

              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),

            child: ListView(
              shrinkWrap: true,
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
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact,
                    primary: Color.fromRGBO(58, 255, 107, 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Get it now'),
                ),
                Container(padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(CupertinoIcons.bag_badge_plus))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
