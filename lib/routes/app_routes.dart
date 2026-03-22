import 'package:flutter/material.dart';
import 'package:verticalpartswms/presentation/login_screen/login_screen.dart';
import 'package:verticalpartswms/presentation/main_menu/main_menu_screen.dart';
import 'package:verticalpartswms/presentation/scanner/barcode_scanning_screen.dart';
import 'package:verticalpartswms/presentation/scanner/task_summary_screen.dart';
import 'package:verticalpartswms/presentation/inventory/inventory_menu_screen.dart';
import 'package:verticalpartswms/presentation/inventory/quick_query_screen.dart';
import 'package:verticalpartswms/presentation/inventory/blind_count_screen.dart';
import 'package:verticalpartswms/presentation/inventory/inventory_count_screen.dart';
import 'package:verticalpartswms/presentation/registry/quick_registry_screen.dart';
import 'package:verticalpartswms/presentation/portaria/check_in_portaria_screen.dart';
import 'package:verticalpartswms/presentation/replenishment/replenishment_screen.dart';
import 'package:verticalpartswms/presentation/printing/print_label_screen.dart';
import 'package:verticalpartswms/presentation/picking/picking_screen.dart';
import 'package:verticalpartswms/presentation/receiving/receiving_check_in_screen.dart';
import 'package:verticalpartswms/presentation/main_menu/widgets/task_list_screen.dart';
import 'package:verticalpartswms/presentation/splash/splash_screen.dart';
import 'package:verticalpartswms/presentation/common/damage_report_screen.dart';
import 'package:verticalpartswms/presentation/notifications/notifications_screen.dart';
import 'package:verticalpartswms/presentation/dashboard/dashboard_screen.dart';
import 'package:verticalpartswms/presentation/picking/outbound_picking_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String mainMenu = '/main-menu';
  static const String scanner = '/scanner';
  static const String taskSummary = '/task-summary';
  static const String inventoryMenu = '/inventory-menu';
  static const String quickQuery = '/quick-query';
  static const String blindCount = '/blind-count';
  static const String replenishment = '/replenishment';
  static const String printLabel = '/print-label';
  static const String picking = '/picking';
  static const String receiving = '/receiving';
  static const String allocationTasks = '/allocation-tasks';
  static const String pickingTasks = '/picking-tasks';
  static const String damageReport = '/damage-report';
  static const String notifications = '/notifications';
  static const String dashboard = '/dashboard';
  static const String inventoryCount  = '/inventory-count';
  static const String quickRegistry    = '/quick-registry';
  static const String checkInPortaria  = '/check-in-portaria';
  static const String outboundPicking  = '/outbound-picking';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      mainMenu: (context) => const MainMenuScreen(),
      scanner: (context) => const BarcodeScanningScreen(),
      taskSummary: (context) => const TaskSummaryScreen(),
      inventoryMenu: (context) => const InventoryMenuScreen(),
      quickQuery: (context) => const QuickQueryScreen(),
      blindCount: (context) => const BlindCountScreen(),
      replenishment: (context) => const ReplenishmentScreen(),
      printLabel: (context) => const PrintLabelScreen(),
      picking: (context) => const PickingScreen(),
      receiving: (context) => const ReceivingCheckInScreen(),
      allocationTasks: (context) => const TaskListScreen(tipo: 'alocacao'),
      pickingTasks: (context) => const TaskListScreen(tipo: 'picking'),
      notifications: (context) => const NotificationsScreen(),
      dashboard: (context) => const DashboardScreen(),
      outboundPicking: (context) => const OutboundPickingScreen(),
      inventoryCount: (context) => const InventoryCountScreen(),
      quickRegistry:    (context) => const QuickRegistryScreen(),
      checkInPortaria:  (context) => const CheckInPortariaScreen(),
      damageReport: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return DamageReportScreen(
          taskId: args?['taskId'] ?? '',
          itemId: args?['itemId'],
          sku: args?['sku'],
        );
      },
    };
  }
}
