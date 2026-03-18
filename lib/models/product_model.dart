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
  final List<String> variants;

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
    this.variants = const [],
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
      variants: List<String>.from(map['variants'] ?? []),
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
      'variants': variants,
    };
  }
}
