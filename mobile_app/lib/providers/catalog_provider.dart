import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../utils/api_helpers.dart';
import 'search_provider.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api);
  final ApiClient _api;

  /// Optional back-reference to SearchProvider – set by main.dart after MultiProvider init.
  SearchProvider? searchProvider;

  List<Product> _allProducts = [];
  List<Product> products = [];
  bool loading = false;
  String? error;

  /// Load the full product list (no server-side query).
  /// After loading, the list is cached and seeded into [SearchProvider]
  /// so all screens get instant local filtering.
  Future<void> load({String query = ''}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.get('/products/');
      _allProducts = resultsOf(data).map((e) => Product.fromJson(e)).toList();
      searchProvider?.seedProducts(_allProducts);
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Could not load products. Please try again.';
    } finally {
      // Apply local query filter if one was supplied (POS / Products search).
      if (query.isEmpty) {
        products = List.of(_allProducts);
      } else {
        final q = query.toLowerCase();
        products = _allProducts
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                (p.categoryName ?? '').toLowerCase().contains(q) ||
                p.variants.any((v) => v.sku.toLowerCase().contains(q) || v.color.toLowerCase().contains(q)))
            .toList();
      }
      loading = false;
      notifyListeners();
    }
  }

  /// Filter the already-loaded list locally (zero network calls).
  void filterLocally(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      products = List.of(_allProducts);
    } else {
      products = _allProducts
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.categoryName ?? '').toLowerCase().contains(q) ||
              p.variants.any((v) =>
                  v.sku.toLowerCase().contains(q) ||
                  v.color.toLowerCase().contains(q) ||
                  v.size.toLowerCase().contains(q)))
          .toList();
    }
    notifyListeners();
  }
}
