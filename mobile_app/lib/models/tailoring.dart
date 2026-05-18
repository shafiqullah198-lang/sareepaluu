class Darzi {
  final int id;
  final String name;
  final String? phone;
  final String? address;

  Darzi({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  factory Darzi.fromJson(Map<String, dynamic> json) => Darzi(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        address: json['address'],
      );
}

class TailoringItem {
  final int id;
  final String tokenNumber;
  final String customerName;
  final String productName;
  final String color;
  final String? darziName;
  String status;
  final double stitchingPrice;
  final DateTime? deliveryDate;

  TailoringItem({
    required this.id,
    required this.tokenNumber,
    required this.customerName,
    required this.productName,
    required this.color,
    this.darziName,
    required this.status,
    required this.stitchingPrice,
    this.deliveryDate,
  });

  factory TailoringItem.fromJson(Map<String, dynamic> json) => TailoringItem(
        id: json['id'],
        tokenNumber: json['token_number'] ?? '',
        customerName: json['customer_name'] ?? 'Walk-in',
        productName: json['variant_detail']?['product_name'] ?? 'Unknown',
        color: json['variant_detail']?['color'] ?? '',
        darziName: json['darzi_detail']?['name'],
        status: json['stitching_status'] ?? 'Pending',
        stitchingPrice: double.tryParse(json['stitching_price']?.toString() ?? '0') ?? 0,
        deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
      );
}
