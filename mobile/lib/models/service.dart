class Category {
  final String id;
  final String name;
  final String? icon;
  final String colorHex;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.colorHex,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      colorHex: json['color_hex'],
      isActive: json['is_active'],
    );
  }
}

class Service {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double minPrice;
  final double maxPrice;
  final int urgencyLevel;
  final bool isActive;

  Service({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.minPrice,
    required this.maxPrice,
    required this.urgencyLevel, 
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      minPrice: (json['min_price'] ?? 0).toDouble(),
      maxPrice: (json['max_price'] ?? 0).toDouble(),
      urgencyLevel: json['urgency_level'] ?? 1,
      isActive: json['is_active'] ?? true,
    );
  }
}