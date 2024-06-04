import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShopView extends StatelessWidget {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Product> gamingMice = List.generate(
      5,
          (index) => Product(
        name: 'Gaming Mouse ${index + 1}',
        imageUrl: 'https://via.placeholder.com/150', // Replace with actual image URLs
        price: '₹${(index + 1) * 500}',
      ),
    );

    final List<Product> keyboards = List.generate(
      5,
          (index) => Product(
        name: 'Keyboard ${index + 1}',
        imageUrl: 'https://via.placeholder.com/150', // Replace with actual image URLs
        price: '₹${(index + 1) * 700}',
      ),
    );

    final List<Product> rams = List.generate(
      5,
          (index) => Product(
        name: 'RAM ${index + 1}',
        imageUrl: 'https://via.placeholder.com/150', // Replace with actual image URLs
        price: '₹${(index + 1) * 800}',
      ),
    );

    final List<Product> headsets = List.generate(
      5,
          (index) => Product(
        name: 'Headset ${index + 1}',
        imageUrl: 'https://via.placeholder.com/150', // Replace with actual image URLs
        price: '₹${(index + 1) * 1000}',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Shop', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          Icon(CupertinoIcons.bag, color: Colors.white),
          SizedBox(width: 15),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            _buildSection('Gaming Mice', gamingMice),
            _buildSection('Keyboards', keyboards),
            _buildSection('RAMs', rams),
            _buildSection('Headsets', headsets),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 250, // Adjust the height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 190,
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              height: 115,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.price,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Handle product button tap
                  },
                  style: ElevatedButton.styleFrom(
                    primary: const Color.fromRGBO(58, 255, 107, 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 30),
                  ),
                  child: const Text('Buy Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String name;
  final String imageUrl;
  final String price;

  Product({required this.name, required this.imageUrl, required this.price});
}
