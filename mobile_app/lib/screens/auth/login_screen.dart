import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool rememberMe = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.95, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child!),
                child: GlassCard(
                  padding: const EdgeInsets.all(40),
                  radius: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.deepMaroon,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildLabel('USERNAME'),
                      _buildTextField(
                        controller: usernameController,
                        hint: 'admin',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('PASSWORD'),
                      _buildTextField(
                        controller: passwordController,
                        hint: '•••••',
                        icon: Icons.lock_outline,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.slate400,
                          ),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRememberMe(),
                      if (auth.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 40),
                      GlassButton(
                        label: auth.loading ? 'AUTHENTICATING...' : 'LOGIN',
                        expanded: true,
                        onPressed: auth.loading ? null : _handleLogin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.premiumGold, width: 2),
            boxShadow: [
              BoxShadow(color: AppColors.deepMaroon.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))
            ],
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('SBP', style: TextStyle(color: AppColors.premiumGold, fontSize: 10, fontWeight: FontWeight.w900)),
                Text('Saree by Paalu', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saree by Paalu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.deepMaroon,
                fontFamily: 'Playfair Display',
              ),
            ),
            Text(
              'PREMIUM COLLECTION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.accentRose,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.accentRose,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return GlassSurface(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.slate400.withValues(alpha: 0.6)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentRose.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accentRose, size: 18),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: rememberMe,
            onChanged: (v) => setState(() => rememberMe = v ?? false),
            activeColor: AppColors.accentRose,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const Text(
          'Remember login on this device',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate500),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      usernameController.text.trim(),
      passwordController.text,
    );
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }
}
