import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:verticalpartswms/data/providers/auth_provider.dart';
import 'package:verticalpartswms/routes/app_routes.dart';
import 'package:verticalpartswms/theme/app_theme.dart';

/// AuthGuard — Protege uma tela exigindo autenticação e, opcionalmente, um perfil específico.
///
/// Uso:
/// ```dart
/// AuthGuard(
///   perfisPermitidos: ['Supervisor', 'Operador de Armazem'],
///   child: OutboundPickingScreen(),
/// )
/// ```
/// Se o operador não estiver autenticado → redireciona para /login.
/// Se o perfil não for permitido → exibe tela de acesso negado.
class AuthGuard extends StatelessWidget {
  final Widget child;

  /// Lista de perfis autorizados. Se vazia/null, qualquer operador autenticado tem acesso.
  final List<String>? perfisPermitidos;

  const AuthGuard({
    super.key,
    required this.child,
    this.perfisPermitidos,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // ── Não autenticado → redireciona para login ──────────────────────────
    if (!auth.autenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const _LoadingGuard();
    }

    // ── Verifica perfil se necessário ─────────────────────────────────────
    final perfil = (auth.user?.perfil ?? '').toLowerCase().trim();
    if (perfisPermitidos != null && perfisPermitidos!.isNotEmpty) {
      final permitido = perfisPermitidos!.any(
        (p) => p.toLowerCase().trim() == perfil,
      );
      if (!permitido) {
        return _AcessoNegadoScreen(
          perfilAtual: auth.user?.perfil ?? 'Desconhecido',
          perfisPermitidos: perfisPermitidos!,
        );
      }
    }

    return child;
  }
}

// ── Widget de carregamento exibido durante o redirect ─────────────────────────
class _LoadingGuard extends StatelessWidget {
  const _LoadingGuard();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.darkBackground,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppTheme.goldPrimary),
        SizedBox(height: 2.h),
        Text('VERIFICANDO SESSÃO...',
          style: TextStyle(color: AppTheme.goldPrimary, fontSize: 10.sp, fontWeight: FontWeight.black, letterSpacing: 2),
        ),
      ]),
    ),
  );
}

// ── Tela de Acesso Negado ─────────────────────────────────────────────────────
class _AcessoNegadoScreen extends StatelessWidget {
  final String perfilAtual;
  final List<String> perfisPermitidos;

  const _AcessoNegadoScreen({
    required this.perfilAtual,
    required this.perfisPermitidos,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.darkBackground,
    appBar: AppBar(
      backgroundColor: AppTheme.darkBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('ACESSO RESTRITO',
        style: TextStyle(color: AppTheme.errorRed, fontSize: 13.sp, fontWeight: FontWeight.black, letterSpacing: 1.5),
      ),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.sp, height: 80.sp,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorRed.withOpacity(0.12),
                border: Border.all(color: AppTheme.errorRed, width: 2),
              ),
              child: Icon(Icons.block_rounded, color: AppTheme.errorRed, size: 40.sp),
            ),
            SizedBox(height: 3.h),
            Text('ACESSO NEGADO',
              style: TextStyle(color: AppTheme.errorRed, fontSize: 18.sp, fontWeight: FontWeight.black, letterSpacing: 2),
            ),
            SizedBox(height: 1.h),
            Text('Seu perfil não tem permissão para acessar esta área.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.errorRed.withOpacity(0.4)),
              ),
              child: Column(children: [
                _InfoRow(label: 'SEU PERFIL', value: perfilAtual.toUpperCase(), valueColor: AppTheme.textMuted),
                SizedBox(height: 1.5.h),
                _InfoRow(
                  label: 'PERFIS AUTORIZADOS',
                  value: perfisPermitidos.map((p) => p.toUpperCase()).join(', '),
                  valueColor: AppTheme.goldPrimary,
                ),
              ]),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity, height: 6.h,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: Text('VOLTAR AO MENU', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.black)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 8.sp, fontWeight: FontWeight.black, letterSpacing: 1)),
      Flexible(
        child: Text(value, style: TextStyle(color: valueColor, fontSize: 9.sp, fontWeight: FontWeight.black), textAlign: TextAlign.right),
      ),
    ],
  );
}
