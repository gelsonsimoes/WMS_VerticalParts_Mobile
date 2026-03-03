import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../data/models/auth_model.dart';
import '../../data/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  // Credenciais de acesso conforme solicitado
  final String _mockId = "OP001";
  final String _mockPassword = "VP123";


  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulação de delay para futura chamada REST
    await Future.delayed(const Duration(seconds: 1));

    if (_employeeIdController.text.trim() == _mockId &&
        _passwordController.text == _mockPassword) {
      
      // Simulação da resposta JSON solicitada
      final authResponse = AuthResponse(
        token: "eyJhbGciOiJIUzI1NiIs...",
        usuario: User(
          id: 123,
          nome: "João Silva",
          perfil: "operador",
        ),
      );

      if (mounted) {
        // Salva os dados no Provider (que também persiste no SharedPreferences)
        await Provider.of<AuthProvider>(context, listen: false).login(authResponse);
        
        // Navegação para o Menu Principal em caso de sucesso
        Navigator.pushReplacementNamed(context, AppRoutes.mainMenu);
      }
    } else {
      setState(() {
        _errorMessage = "ID OU SENHA INCORRETOS.";
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 15.h,
                  child: Image.asset(
                    'img/logo_amarelo.png', 
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.warehouse_rounded,
                      size: 10.h,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'VERTICAL PARTS WMS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.goldPrimary,
                    letterSpacing: 2.0,
                    fontSize: 20.sp,
                  ),
                ),
                SizedBox(height: 6.h),

                TextFormField(
                  controller: _employeeIdController,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'ID DO FUNCIONÁRIO',
                    prefixIcon: Icon(Icons.badge, color: AppTheme.goldPrimary),
                  ),
                  validator: (value) => 
                    value?.isEmpty ?? true ? 'CAMPO OBRIGATÓRIO' : null,
                ),
                SizedBox(height: 3.h),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: const InputDecoration(
                    labelText: 'SENHA',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.goldPrimary),
                  ),
                  validator: (value) => 
                    value?.isEmpty ?? true ? 'CAMPO OBRIGATÓRIO' : null,
                ),
                
                if (_errorMessage != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                  ),
                ],

                SizedBox(height: 6.h),

                SizedBox(
                  width: double.infinity,
                  height: 10.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: AppTheme.darkBackground)
                        : Text(
                            'ENTRAR NO SISTEMA',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                SizedBox(height: 4.h),
                Text(
                  'v1.1.0 MODO PRODUÇÃO',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
