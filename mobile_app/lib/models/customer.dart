class Customer {
  Customer({
    required this.id,
    this.name,
    this.phone,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.totalPaid = 0.0,
    this.purchaseHistory = const [],
  });
  
  final int id;
  final String? name;
  final String? phone;
  final int totalOrders;
  final double totalSpent;
  final double totalPaid;
  final List<dynamic> purchaseHistory;

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        totalOrders: json['total_orders'] ?? 0,
        totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0,
        totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0.0,
        purchaseHistory: json['purchase_history'] ?? [],
      );
}
