import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../widgets/app_shell.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  
  // Tab routes (managed by AppShell index but kept here for constants)
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const pos = '/pos';
  static const orders = '/orders';
  static const customers = '/customers';
  static const profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    home: (_) => const AppShell(),
  };
}
