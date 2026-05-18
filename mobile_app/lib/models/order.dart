class Order {
  Order({
    required this.id,
    required this.token,
    required this.date,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    required this.amountPaid,
    required this.paymentStatus,
    this.customerName,
    this.items = const [],
    this.payments = const [],
    this.invoiceUrl,
  });

  final int id;
  final String token;
  final String date;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final double amountPaid;
  final String paymentStatus;
  final String? customerName;
  final List<dynamic> items;
  final List<dynamic> payments;
  final String? invoiceUrl;

  double get balanceDue => finalAmount - amountPaid;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        token: json['token_number'] ?? '',
        date: json['date'] ?? '',
        totalAmount: double.parse('${json['total_amount'] ?? 0}'),
        discount: double.parse('${json['discount'] ?? 0}'),
        finalAmount: double.parse('${json['final_amount'] ?? 0}'),
        amountPaid: double.parse('${json['amount_paid'] ?? 0}'),
        paymentStatus: json['payment_status'] ?? '',
        customerName: json['customer_name'],
        items: json['items'] ?? [],
        payments: json['payments'] ?? [],
        invoiceUrl: json['invoice_url'],
      );
}
