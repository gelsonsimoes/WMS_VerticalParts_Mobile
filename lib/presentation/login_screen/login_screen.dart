import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../data/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl  = TextEditingController();
  final _pwCtrl  = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() { _idCtrl.dispose(); _pwCtrl.dispose(); super.dispose(); }

  bool _mostrarSenha = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(_idCtrl.text.trim(), _pwCtrl.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, AppRoutes.mainMenu);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          child: Form(key: _formKey, child: Column(children: [
            SizedBox(height: 4.h),
            SizedBox(height: 15.h, child: Image.asset('img/logo_amarelo.png',
              errorBuilder: (_, __, ___) => Icon(Icons.warehouse_rounded, size: 10.h, color: AppTheme.goldPrimary))),
            SizedBox(height: 2.h),
            Text('VERTICAL PARTS WMS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.goldPrimary, letterSpacing: 2.0, fontSize: 20.sp)),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _idCtrl,
              style: TextStyle(fontSize: 14.sp),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'ID OU E-MAIL',
                hintText: 'Ex: OP001 ou gelson@...', 
                prefixIcon: Icon(Icons.badge, color: AppTheme.goldPrimary)
              ),
              validator: (v) => (v?.isEmpty ?? true) ? 'OBRIGATORIO' : null),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _pwCtrl, 
              obscureText: !_mostrarSenha,
              style: TextStyle(fontSize: 14.sp),
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'SENHA',
                prefixIcon: const Icon(Icons.lock, color: AppTheme.goldPrimary),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarSenha ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.goldPrimary,
                  ),
                  onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                ),
              ),
              validator: (v) => (v?.isEmpty ?? true) ? 'OBRIGATORIO' : null),
            if (auth.erro != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                  SizedBox(width: 2.w),
                  Expanded(child: Text(auth.erro!, style: const TextStyle(
                    color: AppTheme.errorRed, fontWeight: FontWeight.bold))),
                ])),
            ],
            SizedBox(height: 6.h),
            SizedBox(width: double.infinity, height: 10.h,
              child: ElevatedButton(
                onPressed: auth.carregando ? null : _login,
                child: auth.carregando
                  ? const CircularProgressIndicator(color: AppTheme.darkBackground)
                  : Text('ENTRAR NO SISTEMA', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)))),
            SizedBox(height: 4.h),
            Text('v2.0.1 · Supabase Integrated', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1, color: AppTheme.textMuted)),
          ])),
        ),
      ),
    );
  }
}
