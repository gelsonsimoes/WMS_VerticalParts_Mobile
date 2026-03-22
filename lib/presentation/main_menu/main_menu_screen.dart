import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:verticalpartswms/theme/app_theme.dart';
import 'package:verticalpartswms/widgets/sync_status_widget.dart';
import 'package:verticalpartswms/widgets/category_tile.dart';
import 'package:verticalpartswms/routes/app_routes.dart';
import 'package:verticalpartswms/data/providers/auth_provider.dart';
import 'package:verticalpartswms/data/providers/notification_provider.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final userName = authProvider.user?.nome.toUpperCase() ?? 'OPERADOR';
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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.goldPrimary),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              if (notifProvider.naoLidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifProvider.naoLidas}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              const SyncStatusWidget(),
              SizedBox(height: 3.h),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4.w,
                  mainAxisSpacing: 4.w,
                  children: [
                    CategoryTile(
                      title: 'CHECK-IN PORTARIA',
                      icon: Icons.where_to_vote_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.checkInPortaria),
                    ),
                    CategoryTile(
                      title: 'ENTRADA E RECEBIMENTO',
                      icon: Icons.unarchive_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.receiving),
                    ),
                    CategoryTile(
                      title: 'ALOCAÇÃO (GUARDA)',
                      icon: Icons.inventory_2_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.allocationTasks),
                    ),
                    CategoryTile(
                      title: 'REMANEJAMENTO',
                      icon: Icons.local_shipping_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.replenishment),
                    ),
                    CategoryTile(
                      title: 'SEPARAÇÃO (PICKING)',
                      icon: Icons.shopping_basket_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.pickingTasks),
                    ),
                    CategoryTile(
                      title: 'SAÍDA DIRIGIDA\n(OMIE)',
                      icon: Icons.output_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.outboundPicking),
                    ),
                    CategoryTile(
                      title: 'DASHBOARD',
                      icon: Icons.bar_chart_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.dashboard),
                    ),
                    CategoryTile(
                      title: 'CONSULTAS E INVENTÁRIO',
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.inventoryMenu),
                    ),
                    CategoryTile(
                      title: 'CADASTRO RÁPIDO\n(MOTORISTA/VEÍCULO)',
                      icon: Icons.app_registration_rounded,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.quickRegistry),
                    ),
                    CategoryTile(
                      title: 'NOTIFICAÇÕES',
                      icon: Icons.notifications_active_rounded,
                      badge: notifProvider.naoLidas > 0 ? '${notifProvider.naoLidas}' : null,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
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
