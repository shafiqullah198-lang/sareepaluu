import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

class CartLine {
  CartLine(this.product, this.variant, {this.quantity = 1, this.price});
  final Product product;
  final ProductVariant variant;
  int quantity;
  double? price; // Can be manually overridden
  bool needsStitching = false;
  double stitchingPrice = 0.0;

  double get total => (price ?? variant.price) * quantity;
}

class CartProvider extends ChangeNotifier {
  CartProvider(this._api);
  final ApiClient _api;

  final List<CartLine> lines = [];
  bool loading = false;
  String? error;

  String customerName = '';
  String customerPhone = '';
  double discount = 0.0;
  double? manualTotal;
  String paymentType = 'full'; // 'full' or 'partial'
  double amountPaid = 0.0;

  double get subtotal => lines.fold(0.0, (sum, item) => sum + item.total);
  double get stitchingTotal => lines.fold(0.0, (sum, item) => sum + (item.stitchingPrice * item.quantity));
  
  double get calculatedTotal => (subtotal + stitchingTotal) - discount;
  double get finalTotal => (manualTotal ?? subtotal) + stitchingTotal - discount;

  void add(Product product, ProductVariant variant) {
    CartLine? existing;
    for (final line in lines) {
      if (line.variant.id == variant.id) existing = line;
    }
    if (existing == null) {
      lines.add(CartLine(product, variant, price: 0)); // Start with 0 so user enters it as per web
    } else {
      existing.quantity++;
    }
    notifyListeners();
  }

  void remove(CartLine line) {
    lines.remove(line);
    notifyListeners();
  }
  
  void updateLine(CartLine line) {
    notifyListeners();
  }
  
  void setManualTotal(double? total) {
    manualTotal = total;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void setPartialAmount(double? amount) {
    amountPaid = amount ?? 0.0;
    notifyListeners();
  }

  void setPaymentType(String type) {
    paymentType = type.toLowerCase();
    notifyListeners();
  }

  void clearCart() {
    lines.clear();
    customerName = '';
    customerPhone = '';
    discount = 0.0;
    manualTotal = null;
    paymentType = 'full';
    amountPaid = 0.0;
    notifyListeners();
  }

  Future<Order?> checkout() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final payload = {
        'customer': {'name': customerName, 'phone': customerPhone},
        'discount': discount,
        'manual_total': manualTotal,
        'amount_paid': paymentType == 'partial' ? amountPaid : finalTotal,
        'cart': lines
            .map((line) => {
                  'variant_id': line.variant.id,
                  'quantity': line.quantity,
                  'price': line.price ?? 0,
                  'needs_stitching': line.needsStitching,
                  'stitching_price': line.stitchingPrice,
                })
            .toList(),
      };
      
      final data = await _api.post('/pos/checkout/', data: payload);
      clearCart();
      return Order.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      error = e.message;
      return null;
    } catch (e) {
      error = 'Checkout failed. Please try again.';
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
