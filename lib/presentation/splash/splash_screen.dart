import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Pequeno delay para mostrar o logo/animação
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.autenticado) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainMenu);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 150,
              child: Image.asset(
                'img/logo_amarelo.png',
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.warehouse_rounded,
                  size: 100,
                  color: AppTheme.goldPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.goldPrimary),
            const SizedBox(height: 16),
            const Text(
              'CARREGANDO SISTEMA...',
              style: TextStyle(
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
