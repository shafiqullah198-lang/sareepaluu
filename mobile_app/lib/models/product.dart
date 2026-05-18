class ProductVariant {
  ProductVariant(
      {required this.id,
      required this.sku,
      required this.color,
      required this.size,
      required this.price,
      required this.stock});
  final int id;
  final String sku;
  final String color;
  final String size;
  final double price;
  final int stock;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'],
        sku: json['sku'] ?? '',
        color: json['color'] ?? '',
        size: json['size'] ?? '',
        price: double.parse('${json['price'] ?? 0}'),
        stock: json['stock'] ?? 0,
      );
}

class Product {
  Product(
      {required this.id,
      required this.name,
      this.categoryName,
      this.imageUrl,
      required this.totalStock,
      required this.variants});
  final int id;
  final String name;
  final String? categoryName;
  final String? imageUrl;
  final int totalStock;
  final List<ProductVariant> variants;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'] ?? '',
        categoryName: json['category_name'],
        imageUrl: json['image'] as String?,
        totalStock: json['total_stock'] ?? 0,
        variants: ((json['variants'] ?? []) as List)
            .map((e) => ProductVariant.fromJson(e))
            .toList(),
      );
}
