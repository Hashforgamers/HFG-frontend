class Product {
  final Availability availability;
  final String category;
  final String currency;
  final String description;
  final Dimensions dimensions;
  final Electronic electronic;
  final String id;
  final List<ProductImage> images;
  final String manufacturer;
  final String name;
  final NonElectronic nonElectronic;
  final double price;
  final Rating rating;
  final String sku;
  final Weight weight;

  Product({
    required this.availability,
    required this.category,
    required this.currency,
    required this.description,
    required this.dimensions,
    required this.electronic,
    required this.id,
    required this.images,
    required this.manufacturer,
    required this.name,
    required this.nonElectronic,
    required this.price,
    required this.rating,
    required this.sku,
    required this.weight,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      availability: Availability.fromJson(json['availability'] ?? {}),
      category: json['category'] ?? '',
      currency: json['currency'] ?? '',
      description: json['description'] ?? '',
      dimensions: Dimensions.fromJson(json['dimensions'] ?? {}),
      electronic: Electronic.fromJson(json['electronic'] ?? {}),
      id: json['id'] ?? '',
      images: (json['images'] as List?)
          ?.map((i) => ProductImage.fromJson(i))
          .toList() ??
          [],
      manufacturer: json['manufacturer'] ?? '',
      name: json['name'] ?? '',
      nonElectronic: NonElectronic.fromJson(json['non_electronic'] ?? {}),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: Rating.fromJson(json['rating'] ?? {}),
      sku: json['sku'] ?? '',
      weight: Weight.fromJson(json['weight'] ?? {}),
    );
  }
}

class Availability {
  final bool inStock;
  final int quantity;

  Availability({
    required this.inStock,
    required this.quantity,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      inStock: json['in_stock'] ?? false,
      quantity: json['quantity'] ?? 0,
    );
  }
}

class Dimensions {
  final double height;
  final double length;
  final double width;
  final String unit;

  Dimensions({
    required this.height,
    required this.length,
    required this.width,
    required this.unit,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }
}

class Electronic {
  final String compatibility;
  final String connectivity;
  final String? item;
  final String powerConsumption;

  Electronic({
    required this.compatibility,
    required this.connectivity,
    this.item,
    required this.powerConsumption,
  });

  factory Electronic.fromJson(Map<String, dynamic> json) {
    return Electronic(
      compatibility: json['compatibility'] ?? '',
      connectivity: json['connectivity'] ?? '',
      item: json['item'],
      powerConsumption: json['power_consumption'] ?? '',
    );
  }
}

class ProductImage {
  final String altText;
  final String url;

  ProductImage({
    required this.altText,
    required this.url,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      altText: json['alt_text'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class NonElectronic {
  final String color;
  final String material;
  final String size;
  final String? item;

  NonElectronic({
    required this.color,
    required this.material,
    required this.size,
    this.item,
  });

  factory NonElectronic.fromJson(Map<String, dynamic> json) {
    return NonElectronic(
      color: json['color'] ?? '',
      material: json['material'] ?? '',
      size: json['size'] ?? '',
      item: json['item'],
    );
  }
}

class Rating {
  final double average;
  final int count;

  Rating({
    required this.average,
    required this.count,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] ?? 0,
    );
  }
}

class Weight {
  final String unit;
  final double value;

  Weight({
    required this.unit,
    required this.value,
  });

  factory Weight.fromJson(Map<String, dynamic> json) {
    return Weight(
      unit: json['unit'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
