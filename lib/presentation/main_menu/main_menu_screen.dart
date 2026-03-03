import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sync_status_widget.dart';
import '../../widgets/category_tile.dart';
import '../../routes/app_routes.dart';
import '../../data/providers/auth_provider.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.nome.toUpperCase() ?? 'SESSÃO ATIVA';
    final userProfile = authProvider.user?.perfil.toUpperCase() ?? 'OPERADOR';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(
          'PAINEL PRINCIPAL',
          style: TextStyle(color: AppTheme.goldPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              const SyncStatusWidget(isOnline: true),
              
              SizedBox(height: 3.h),
              
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4.w,
                  mainAxisSpacing: 4.w,
                  children: [
                    CategoryTile(
                      title: 'ENTRADA E RECEBIMENTO',
                      icon: Icons.unarchive_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.receiving),
                    ),
                    CategoryTile(
                      title: 'ALOCAÇÃO (GUARDA)',
                      icon: Icons.inventory_2_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.scanner),
                    ),
                    CategoryTile(
                      title: 'REMANEJAMENTO (ESTOQUE)',
                      icon: Icons.local_shipping_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.replenishment),
                    ),
                    CategoryTile(
                      title: 'SEPARAÇÃO (PICKING)',
                      icon: Icons.shopping_basket_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.picking),
                    ),
                    CategoryTile(
                      title: 'CONSULTAS E INVENTÁRIO',
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryMenu),
                    ),
                    CategoryTile(
                      title: 'SAIR DO SISTEMA',
                      icon: Icons.exit_to_app_rounded,
                      onTap: () {
                        authProvider.logout();
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Text(
                  'SESSÃO: $userName ($userProfile)',
                  style: TextStyle(color: AppTheme.goldPrimary.withOpacity(0.7), fontSize: 10.sp, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
