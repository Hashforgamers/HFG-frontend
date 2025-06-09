import 'package:cloud_firestore/cloud_firestore.dart';
import '../products_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  Future<void> addProduct(Product product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).set({
        'availability': {
          'inStock': product.availability.inStock,
          'quantity': product.availability.quantity,
        },
        'category': product.category,
        'currency': product.currency,
        'description': product.description,
        'dimensions': {
          'height': product.dimensions.height,
          'length': product.dimensions.length,
          'width': product.dimensions.width,
          'unit': product.dimensions.unit,
        },
        'electronic': {
          'compatibility': product.electronic.compatibility,
          'connectivity': product.electronic.connectivity,
          'item': product.electronic.item,
          'powerConsumption': product.electronic.powerConsumption,
        },
        'id': product.id,
        'images': product.images.map((img) => {
          'altText': img.altText,
          'url': img.url,
        }).toList(),
        'manufacturer': product.manufacturer,
        'name': product.name,
        'nonElectronic': {
          'color': product.nonElectronic.color,
          'material': product.nonElectronic.material,
          'size': product.nonElectronic.size,
          'item': product.nonElectronic.item,
        },
        'price': product.price,
        'rating': {
          'average': product.rating.average,
          'count': product.rating.count,
        },
        'sku': product.sku,
        'weight': {
          'unit': product.weight.unit,
          'value': product.weight.value,
        },
        'preRegisterCount': 0, // Initialize pre-registration count
      });
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<void> incrementPreRegisterCount(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'preRegisterCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment pre-registration count: $e');
    }
  }

  // Future<void> initializeProducts() async {
  //   try {
  //     final List<Product> products = [
  //       Product(
  //         availability: Availability(inStock: true, quantity: 50),
  //         category: 'Gaming Accessories',
  //         currency: 'INR',
  //         description: 'High-quality gaming mouse with RGB lighting.',
  //         dimensions: Dimensions(height: 5.0, length: 12.0, width: 8.0, unit: 'cm'),
  //         electronic: Electronic(
  //           compatibility: 'PC, Mac',
  //           connectivity: 'Wireless',
  //           item: 'Mouse',
  //           powerConsumption: '5W',
  //         ),
  //         id: '1',
  //         images: [
  //           ProductImage(
  //             altText: 'Gaming Mouse',
  //             url: 'https://www.pngkey.com/png/full/246-2463403_gaming-mice-razer-naga-razer-mouse.png',
  //           )
  //         ],
  //         manufacturer: 'Razer',
  //         name: 'Gaming Mouse 1',
  //         nonElectronic: NonElectronic(color: 'Black', material: 'Plastic', size: 'Standard', item: null),
  //         price: 1599.99,
  //         rating: Rating(average: 4.5, count: 120),
  //         sku: 'GM123',
  //         weight: Weight(unit: 'kg', value: 0.15),
  //       ),
  //       Product(
  //         availability: Availability(inStock: true, quantity: 30),
  //         category: 'Keyboards',
  //         currency: 'INR',
  //         description: 'Mechanical gaming keyboard with customizable RGB lighting.',
  //         dimensions: Dimensions(height: 3.5, length: 45.0, width: 15.0, unit: 'cm'),
  //         electronic: Electronic(
  //           compatibility: 'PC',
  //           connectivity: 'Wired',
  //           item: 'Keyboard',
  //           powerConsumption: '10W',
  //         ),
  //         id: '2',
  //         images: [
  //           ProductImage(
  //             altText: 'Gaming Keyboard',
  //             url: 'https://assets.mspimages.in/wp-content/uploads/2017/03/pro-tenkeyless-gaming-keyboard-1.png',
  //           )
  //         ],
  //         manufacturer: 'Logitech',
  //         name: 'Gaming Keyboard Pro',
  //         nonElectronic: NonElectronic(color: 'Black', material: 'Aluminum', size: 'Full Size', item: null),
  //         price: 3499.99,
  //         rating: Rating(average: 4.7, count: 85),
  //         sku: 'GK456',
  //         weight: Weight(unit: 'kg', value: 1.2),
  //       ),
  //       Product(
  //         availability: Availability(inStock: true, quantity: 20),
  //         category: 'Memory',
  //         currency: 'INR',
  //         description: 'High-performance DDR4 RAM for gaming PCs.',
  //         dimensions: Dimensions(height: 2.5, length: 14.0, width: 0.5, unit: 'cm'),
  //         electronic: Electronic(
  //           compatibility: 'Desktop',
  //           connectivity: 'NA',
  //           item: 'RAM',
  //           powerConsumption: '1.2V',
  //         ),
  //         id: '3',
  //         images: [
  //           ProductImage(
  //             altText: 'Gaming RAM',
  //             url: 'https://www.pngall.com/wp-content/uploads/5/Gaming-RAM-PNG-Image.png',
  //           )
  //         ],
  //         manufacturer: 'Corsair',
  //         name: 'Gaming RAM 16GB',
  //         nonElectronic: NonElectronic(color: 'Black', material: 'PCB', size: '16GB', item: null),
  //         price: 5999.99,
  //         rating: Rating(average: 4.8, count: 200),
  //         sku: 'GR789',
  //         weight: Weight(unit: 'kg', value: 0.1),
  //       ),
  //       Product(
  //         availability: Availability(inStock: false, quantity: 0),
  //         category: 'Headsets',
  //         currency: 'INR',
  //         description: 'Immersive gaming headset with 7.1 surround sound.',
  //         dimensions: Dimensions(height: 8.0, length: 18.0, width: 18.0, unit: 'cm'),
  //         electronic: Electronic(
  //           compatibility: 'PC, Console',
  //           connectivity: 'Wired',
  //           item: 'Headset',
  //           powerConsumption: 'NA',
  //         ),
  //         id: '4',
  //         images: [
  //           ProductImage(
  //             altText: 'Gaming Headset',
  //             url: 'https://www.pngall.com/wp-content/uploads/5/Logitech-Gaming-Headset.png',
  //           )
  //         ],
  //         manufacturer: 'SteelSeries',
  //         name: 'Gaming Headset Pro',
  //         nonElectronic: NonElectronic(color: 'Black & Orange', material: 'Plastic', size: 'Adjustable', item: null),
  //         price: 6999.99,
  //         rating: Rating(average: 4.2, count: 60),
  //         sku: 'GH101',
  //         weight: Weight(unit: 'kg', value: 0.8),
  //       ),
  //     ];

  //     // Add each product to Firebase
  //     for (var product in products) {
  //       await addProduct(product);
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to initialize products: $e');
  //   }
  // }
}