class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String createdBy;
  final DateTime createdAt;
  final String category;
  final bool featured;
  final bool inStock;
  final int stockQuantity;
  final List<String> variants;
  final String promoText;
  final double promoDiscountPercent;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.createdBy,
    required this.createdAt,
    this.category = 'General',
    this.featured = false,
    this.inStock = true,
    this.stockQuantity = 0,
    this.variants = const [],
    this.promoText = '',
    this.promoDiscountPercent = 0,
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: ((map['price'] ?? 0) as num).toDouble(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
      category: (map['category'] ?? 'General').toString(),
      featured: (map['featured'] ?? false) == true,
      inStock: (map['inStock'] ?? true) == true,
      stockQuantity: ((map['stockQuantity'] ?? 0) as num).toInt(),
      variants: List<String>.from(map['variants'] ?? []),
      promoText: (map['promoText'] ?? '').toString(),
      promoDiscountPercent: ((map['promoDiscountPercent'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'featured': featured,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'variants': variants,
      'promoText': promoText,
      'promoDiscountPercent': promoDiscountPercent,
    };
  }
}
