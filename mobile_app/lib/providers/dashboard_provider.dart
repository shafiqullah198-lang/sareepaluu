import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/api_exception.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._api);
  final ApiClient _api;

  Map<String, dynamic> summary = {};
  Map<String, dynamic> salesData = {};
  Map<String, dynamic> workflow = {};
  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> lowStockItems = [];

  bool loading = false;
  String? error;
  String period = 'week';

  void setPeriod(String newPeriod) {
    period = newPeriod;
    load();
  }

  Future<void> load() async {
    // Only set loading to true if we don't have data yet, to support background refresh
    if (summary.isEmpty) {
      loading = true;
      error = null;
      notifyListeners();
    }

    try {
      // Fetch both concurrently to save time
      final results = await Future.wait([
        _api.get('/reports/summary/'),
        _api.get('/reports/sales/', params: {'period': period}),
      ]);

      final s = Map<String, dynamic>.from(results[0] as Map);
      summary = s;
      workflow = Map<String, dynamic>.from(s['workflow'] as Map? ?? {});
      recentOrders = List<Map<String, dynamic>>.from(
        (s['recent_orders'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      lowStockItems = List<Map<String, dynamic>>.from(
        (s['low_stock_items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      salesData = Map<String, dynamic>.from(results[1] as Map);
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Unable to connect to server. Please check your internet.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
