import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_tile.dart';
import '../../routes/app_routes.dart';

class InventoryMenuScreen extends StatelessWidget {
  const InventoryMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONSULTAS E INVENTÁRIO'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            SizedBox(height: 2.h),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                mainAxisSpacing: 3.h,
                childAspectRatio: 2.2,
                children: [
                  CategoryTile(
                    title: 'CONSULTA RÁPIDA\n(PRODUTO/ENDEREÇO)',
                    icon: Icons.search_rounded,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.quickQuery),
                  ),
                  CategoryTile(
                    title: 'CONFERÊNCIA CEGA\n(INVENTÁRIO)',
                    icon: Icons.inventory_rounded,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.blindCount),
                  ),
                  CategoryTile(
                    title: 'IMPRESSÃO DE ETIQUETAS',
                    icon: Icons.print_rounded,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.printLabel),
                  ),
                ],
              ),
            ),
            Text(
              'FERRAMENTAS DE APOIO AO ESTOQUE',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp, letterSpacing: 1),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
