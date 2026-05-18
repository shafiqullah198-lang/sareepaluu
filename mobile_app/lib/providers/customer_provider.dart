import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../utils/api_helpers.dart';
import 'search_provider.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider(this._api);
  final ApiClient _api;

  SearchProvider? searchProvider;

  List<Customer> _allCustomers = [];
  List<Customer> customers = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/customers/');
      _allCustomers = resultsOf(data).map((e) => Customer.fromJson(e)).toList();
      customers = List.of(_allCustomers);
      searchProvider?.seedCustomers(_allCustomers);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not load customers. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Filter the cached list locally (no network call).
  void filterLocally(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      customers = List.of(_allCustomers);
    } else {
      customers = _allCustomers.where((c) {
        return (c.name ?? '').toLowerCase().contains(q) ||
            (c.phone ?? '').toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<Customer?> getCustomerDetail(int id) async {
    try {
      final data = await _api.get('/customers/$id/');
      return Customer.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
