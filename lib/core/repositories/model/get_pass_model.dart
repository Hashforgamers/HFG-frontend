class GetPassModel {
  final int daysValid;
  final String description;
  final String id;
  final String name;
  final String passType;
  final double price;
  final String? vendorId;
  final String vendorName;
  final String? expiryDate;
  final String? purchaseDate;
  final double? progress;
  final String? status;
  final String? imageUrl;
  final String? vendorImage;
  final String? validFrom;
  final String? validTo;
  final int? cafePassId;
  final bool? isBought;
  final List<VendorImages>? vendorImages;

  GetPassModel({
    required this.daysValid,
    required this.description,
    required this.id,
    required this.name,
    required this.passType,
    required this.price,
    this.vendorId,
    required this.vendorName,
    this.expiryDate,
    this.purchaseDate,
    this.progress,
    this.status,
    this.imageUrl,
    this.vendorImage,
    this.validFrom,
    this.validTo,
    this.cafePassId,
    this.isBought,
    this.vendorImages,
  });

  factory GetPassModel.fromJson(Map<String, dynamic> json) {
    return GetPassModel(
      daysValid:
          (json['days_valid'] as num?)?.toInt() ?? 365, // Default to 1 year
      description: (json['description'] ?? 'Game Pass').toString(),
      id: json['id'].toString(),
      name: (json['cafe_pass_name'] ?? json['name'] ?? 'Game Pass').toString(),
      passType: (json['pass_type'] ?? 'yearly').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      vendorId: json['vendor_id']?.toString(),
      vendorName: (json['vendor_name'] ?? 'Gaming Cafe').toString(),
      expiryDate:
          json['valid_to']?.toString() ?? json['expiry_date']?.toString(),
      purchaseDate:
          json['valid_from']?.toString() ?? json['purchase_date']?.toString(),
      progress: (json['progress'] as num?)?.toDouble(),
      status: json['status']?.toString(),
      imageUrl: json['image_url']?.toString(),
      vendorImage: json['vendor_image']?.toString(),
      validFrom: json['valid_from']?.toString(),
      validTo: json['valid_to']?.toString(),
      cafePassId: json['cafe_pass_id'] as int?,
      isBought: json['is_bought'] as bool?,
      vendorImages: json['vendor_images'] != null
          ? (json['vendor_images'] as List)
              .map((e) => VendorImages.fromJson(e))
              .toList()
          : null,
    );
  }

  // Helper method to get display image
  String get displayImage {
    return imageUrl ?? vendorImage ?? 'assets/images/globalpass1.png';
  }

  // Helper method to get progress value
  double get progressValue {
    if (progress != null) return progress!;

    // Calculate progress based on valid_from and valid_to dates
    if (validFrom != null && validTo != null) {
      try {
        final startDate = DateTime.parse(validFrom!);
        final endDate = DateTime.parse(validTo!);
        final now = DateTime.now();

        if (endDate.isBefore(now)) return 1.0; // Expired
        if (startDate.isAfter(now)) return 0.0; // Not started

        final totalDuration = endDate.difference(startDate).inDays;
        final elapsed = now.difference(startDate).inDays;

        if (totalDuration <= 0) return 1.0;
        return (elapsed / totalDuration).clamp(0.0, 1.0);
      } catch (e) {
        return 0.0;
      }
    }

    // Fallback to expiry date calculation
    if (expiryDate != null) {
      try {
        final expiry = DateTime.parse(expiryDate!);
        final now = DateTime.now();
        final purchase = purchaseDate != null
            ? DateTime.parse(purchaseDate!)
            : now;

        if (expiry.isBefore(now)) return 1.0; // Expired
        if (purchase.isAfter(now)) return 0.0; // Not started

        final totalDuration = expiry.difference(purchase).inDays;
        final elapsed = now.difference(purchase).inDays;

        if (totalDuration <= 0) return 1.0;
        return (elapsed / totalDuration).clamp(0.0, 1.0);
      } catch (e) {
        return 0.0;
      }
    }

    return 0.0;
  }

  // Helper method to get status color
  int get statusColor {
    if (status == 'expired' || progressValue >= 1.0) {
      return 0xFFFBA544; // Orange for expired
    } else if (status == 'active' || progressValue > 0.0) {
      return 0xFF6DFB60; // Green for active
    } else {
      return 0xFFE6D009; // Yellow for pending
    }
  }

  // Helper method to get expiry text
  String get expiryText {
    if (validTo != null) {
      try {
        final expiry = DateTime.parse(validTo!);
        final now = DateTime.now();

        if (expiry.isBefore(now)) {
          return 'Expired on ${_formatDate(expiry)}';
        } else {
          return 'Expires ${_formatDate(expiry)}';
        }
      } catch (e) {
        return 'Expires soon';
      }
    }

    if (expiryDate != null) {
      try {
        final expiry = DateTime.parse(expiryDate!);
        final now = DateTime.now();

        if (expiry.isBefore(now)) {
          return 'Expired on ${_formatDate(expiry)}';
        } else {
          return 'Expires ${_formatDate(expiry)}';
        }
      } catch (e) {
        return 'Expires soon';
      }
    }
    return 'No expiry date';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper method to get info text
  String get infoText {
    //calculate the valid days
    final validDays = DateTime.parse(
      validTo!,
    ).difference(DateTime.parse(DateTime.now().toString())).inDays;

    if (validDays > 0) {
      if (price > 0) {
        return '$validDays Days @ Rs.${price.toStringAsFixed(0)}';
      } else {
        return '$validDays Days';
      }
    }
    if (price > 0) {
      return 'Rs.${price.toStringAsFixed(0)}';
    }
    return passType.isNotEmpty ? passType.toUpperCase() : 'GAME PASS';
  }

  // Helper method to get timestamp for grouping
  DateTime get timestamp {
    if (validFrom != null) {
      try {
        return DateTime.parse(validFrom!);
      } catch (e) {
        return DateTime.now();
      }
    }

    if (purchaseDate != null) {
      try {
        return DateTime.parse(purchaseDate!);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

class VendorImages {
  final int id;
  final String url;

  VendorImages({
    required this.id,
    required this.url,
  });

  factory VendorImages.fromJson(Map<String, dynamic> json) {
    return VendorImages(id: json['id'], url: json['url']);
  }
}
