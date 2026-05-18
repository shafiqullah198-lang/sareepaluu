import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_client.dart';
import '../utils/api_helpers.dart';

class ExpenseProvider with ChangeNotifier {
  ExpenseProvider(this._api);
  final ApiClient _api;
  List<Expense> _expenses = [];
  bool _loading = false;

  List<Expense> get expenses => _expenses;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/reports/expenses/');
      _expenses = resultsOf(res).map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Expense load error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addExpense(double amount, String category, String? note) async {
    try {
      await _api.post('/reports/expenses/', data: {
        'amount': amount,
        'category': category,
        'note': note,
      });
      await load();
    } catch (e) {
      debugPrint('Add expense error: $e');
    }
  }
}
