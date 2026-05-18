import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../utils/api_helpers.dart';
import 'search_provider.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._api);
  final ApiClient _api;

  SearchProvider? searchProvider;

  List<Order> _allOrders = [];
  List<Order> orders = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/orders/');
      _allOrders = resultsOf(data).map((e) => Order.fromJson(e)).toList();
      orders = List.of(_allOrders);
      searchProvider?.seedOrders(_allOrders);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not load orders. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Filter the cached list locally (no network call).
  void filterLocally(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      orders = List.of(_allOrders);
    } else {
      orders = _allOrders.where((o) {
        return o.token.toLowerCase().contains(q) ||
            (o.customerName ?? '').toLowerCase().contains(q) ||
            o.paymentStatus.toLowerCase().contains(q) ||
            o.id.toString().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> addPayment(int orderId, double amount) async {
    loading = true;
    notifyListeners();
    try {
      await _api.post('/orders/$orderId/payment/', data: {'amount': amount});
      await load();
    } catch (e) {
      error = 'Could not add payment.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
