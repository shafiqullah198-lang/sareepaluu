import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final navigator = Navigator.of(context);
      _bootstrap(auth, navigator);
    });
  }

  Future<void> _bootstrap(AuthProvider auth, NavigatorState navigator) async {
    await auth.bootstrap();
    if (!mounted) return;
    navigator.pushReplacementNamed(
        auth.authenticated ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
