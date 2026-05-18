import 'dart:async';
import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/tailoring.dart';

/// A single result item used by the global search overlay.
class SearchResultItem {
  final String section;     // 'Products', 'Orders', 'Customers', 'Tailoring'
  final String title;
  final String subtitle;
  final IconData? icon;
  final dynamic data;       // original model object

  const SearchResultItem({
    required this.section,
    required this.title,
    required this.subtitle,
    this.icon,
    this.data,
  });
}

/// Centralized search provider.
///
/// Usage pattern from any screen:
///   final sp = context.read<SearchProvider>();
///   sp.setQuery('silk');              // triggers debounced filter
///   sp.filteredProducts               // use the filtered list directly
///
/// Providers call [seedProducts], [seedOrders], [seedCustomers], [seedTailoring]
/// whenever they finish loading to keep the cache up to date.
class SearchProvider extends ChangeNotifier {
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  // ─── Raw caches ───────────────────────────────────────────────
  List<Product> _allProducts = [];
  List<Order> _allOrders = [];
  List<Customer> _allCustomers = [];
  List<TailoringItem> _allTailoring = [];

  // ─── Filtered lists ───────────────────────────────────────────
  List<Product> _products = [];
  List<Order> _orders = [];
  List<Customer> _customers = [];
  List<TailoringItem> _tailoring = [];

  // ─── Global search results (grouped) ─────────────────────────
  Map<String, List<SearchResultItem>> _globalResults = {};

  // ─── State ────────────────────────────────────────────────────
  String _query = '';
  Timer? _debounce;

  // ─── Public getters ───────────────────────────────────────────
  String get query => _query;
  List<Product> get filteredProducts => _products;
  List<Order> get filteredOrders => _orders;
  List<Customer> get filteredCustomers => _customers;
  List<TailoringItem> get filteredTailoring => _tailoring;
  Map<String, List<SearchResultItem>> get globalResults => _globalResults;
  bool get hasQuery => _query.trim().isNotEmpty;

  // ─── Seed methods (called by individual providers) ────────────
  void seedProducts(List<Product> items) {
    _allProducts = List.unmodifiable(items);
    _applyFilter();
  }

  void seedOrders(List<Order> items) {
    _allOrders = List.unmodifiable(items);
    _applyFilter();
  }

  void seedCustomers(List<Customer> items) {
    _allCustomers = List.unmodifiable(items);
    _applyFilter();
  }

  void seedTailoring(List<TailoringItem> items) {
    _allTailoring = List.unmodifiable(items);
    _applyFilter();
  }

  // ─── Query control ────────────────────────────────────────────
  void setQuery(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _applyFilter();
      notifyListeners();
    });
    // Immediate lightweight notify so the TextField stays in sync
    notifyListeners();
  }

  void clearQuery() {
    _query = '';
    _debounce?.cancel();
    _applyFilter();
    notifyListeners();
  }

  // ─── Core filter logic ────────────────────────────────────────
  void _applyFilter() {
    final q = _query.trim().toLowerCase();

    if (q.isEmpty) {
      _products = List.of(_allProducts);
      _orders = List.of(_allOrders);
      _customers = List.of(_allCustomers);
      _tailoring = List.of(_allTailoring);
      _globalResults = {};
      return;
    }

    _products = _allProducts.where((p) => _matchProduct(p, q)).toList();
    _orders = _allOrders.where((o) => _matchOrder(o, q)).toList();
    _customers = _allCustomers.where((c) => _matchCustomer(c, q)).toList();
    _tailoring = _allTailoring.where((t) => _matchTailoring(t, q)).toList();

    _buildGlobalResults();
  }

  // ─── Per-entity match helpers (multi-field, case-insensitive) ─
  bool _matchProduct(Product p, String q) {
    if (p.name.toLowerCase().contains(q)) return true;
    if ((p.categoryName ?? '').toLowerCase().contains(q)) return true;
    for (final v in p.variants) {
      if (v.sku.toLowerCase().contains(q)) return true;
      if (v.color.toLowerCase().contains(q)) return true;
      if (v.size.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  bool _matchOrder(Order o, String q) {
    if (o.token.toLowerCase().contains(q)) return true;
    if ((o.customerName ?? '').toLowerCase().contains(q)) return true;
    if (o.paymentStatus.toLowerCase().contains(q)) return true;
    if (o.id.toString().contains(q)) return true;
    return false;
  }

  bool _matchCustomer(Customer c, String q) {
    if ((c.name ?? '').toLowerCase().contains(q)) return true;
    if ((c.phone ?? '').toLowerCase().contains(q)) return true;
    return false;
  }

  bool _matchTailoring(TailoringItem t, String q) {
    if (t.tokenNumber.toLowerCase().contains(q)) return true;
    if (t.customerName.toLowerCase().contains(q)) return true;
    if (t.productName.toLowerCase().contains(q)) return true;
    if (t.color.toLowerCase().contains(q)) return true;
    if (t.status.toLowerCase().contains(q)) return true;
    if ((t.darziName ?? '').toLowerCase().contains(q)) return true;
    return false;
  }

  // ─── Build grouped global results ─────────────────────────────
  void _buildGlobalResults() {
    final Map<String, List<SearchResultItem>> results = {};

    if (_products.isNotEmpty) {
      results['Products'] = _products.map((p) => SearchResultItem(
        section: 'Products',
        title: p.name,
        subtitle: '${p.categoryName ?? 'Uncategorized'} · ${p.variants.length} variants · ${p.totalStock} in stock',
        data: p,
      )).toList();
    }

    if (_orders.isNotEmpty) {
      results['Orders'] = _orders.map((o) => SearchResultItem(
        section: 'Orders',
        title: 'Token #${o.token}',
        subtitle: '${o.customerName ?? 'Walk-in'} · Rs. ${o.finalAmount.toStringAsFixed(0)} · ${o.paymentStatus}',
        data: o,
      )).toList();
    }

    if (_customers.isNotEmpty) {
      results['Customers'] = _customers.map((c) => SearchResultItem(
        section: 'Customers',
        title: c.name ?? 'Unknown',
        subtitle: '${c.phone ?? 'No phone'} · ${c.totalOrders} orders',
        data: c,
      )).toList();
    }

    if (_tailoring.isNotEmpty) {
      results['Tailoring'] = _tailoring.map((t) => SearchResultItem(
        section: 'Tailoring',
        title: '${t.tokenNumber} · ${t.productName}',
        subtitle: '${t.customerName} · ${t.color} · ${t.status}',
        data: t,
      )).toList();
    }

    _globalResults = results;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
