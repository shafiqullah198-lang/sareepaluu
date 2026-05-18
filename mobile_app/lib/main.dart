import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/order_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/tailoring_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/search_provider.dart';
import 'routes/app_routes.dart';
import 'services/api_client.dart';
import 'services/token_store.dart';

void main() {
  final tokens = TokenStore();
  final api = ApiClient(tokens);
  runApp(SareePaluuApp(api: api, tokens: tokens));
}

class SareePaluuApp extends StatelessWidget {
  const SareePaluuApp({super.key, required this.api, required this.tokens});
  final ApiClient api;
  final TokenStore tokens;

  @override
  Widget build(BuildContext context) {
    // Create providers that need cross-wiring up front.
    final searchProvider = SearchProvider();
    final catalogProvider = CatalogProvider(api)..searchProvider = searchProvider;
    final orderProvider = OrderProvider(api)..searchProvider = searchProvider;
    final customerProvider = CustomerProvider(api)..searchProvider = searchProvider;
    final tailoringProvider = TailoringProvider(api)..searchProvider = searchProvider;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api, tokens)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(api)),
        ChangeNotifierProvider.value(value: catalogProvider),
        ChangeNotifierProvider(create: (_) => CartProvider(api)),
        ChangeNotifierProvider.value(value: orderProvider),
        ChangeNotifierProvider.value(value: customerProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: tailoringProvider),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(api)),
        ChangeNotifierProvider.value(value: searchProvider),
      ],
      child: MaterialApp(
        title: 'Saree POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}
