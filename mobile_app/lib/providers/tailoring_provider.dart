import 'package:flutter/material.dart';
import '../models/tailoring.dart';
import '../services/api_client.dart';
import '../utils/api_helpers.dart';
import 'search_provider.dart';

class TailoringProvider with ChangeNotifier {
  TailoringProvider(this._api);
  final ApiClient _api;

  SearchProvider? searchProvider;

  List<TailoringItem> _allItems = [];
  List<TailoringItem> _items = [];
  List<Darzi> _darzis = [];
  bool _loading = false;
  String? _error;

  List<TailoringItem> get items => _items;
  List<Darzi> get darzis => _darzis;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/orders/items/?tailoring=true');
      _allItems = resultsOf(res).map((i) => TailoringItem.fromJson(i)).toList();
      _items = List.of(_allItems);
      searchProvider?.seedTailoring(_allItems);

      final darziRes = await _api.get('/orders/darzis/');
      _darzis = resultsOf(darziRes).map((d) => Darzi.fromJson(d)).toList();
    } catch (e) {
      debugPrint('Tailoring load error: $e');
      _error = 'Failed to load tailoring items.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Filter the cached list locally (no network call).
  void filterLocally(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _items = List.of(_allItems);
    } else {
      _items = _allItems.where((t) {
        return t.tokenNumber.toLowerCase().contains(q) ||
            t.customerName.toLowerCase().contains(q) ||
            t.productName.toLowerCase().contains(q) ||
            t.color.toLowerCase().contains(q) ||
            t.status.toLowerCase().contains(q) ||
            (t.darziName ?? '').toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> updateStatus(int itemId, String status) async {
    try {
      await _api.post('/orders/items/$itemId/status/', data: {'status': status});
      final idx = _allItems.indexWhere((i) => i.id == itemId);
      if (idx != -1) {
        _allItems[idx].status = status;
        filterLocally(''); // refresh filtered list
      }
    } catch (e) {
      debugPrint('Status update error: $e');
    }
  }

  Future<void> assignDarzi(int itemId, int darziId) async {
    try {
      await _api.post('/orders/items/$itemId/assign/', data: {'darzi_id': darziId});
      await load();
    } catch (e) {
      debugPrint('Assign darzi error: $e');
    }
  }
}
