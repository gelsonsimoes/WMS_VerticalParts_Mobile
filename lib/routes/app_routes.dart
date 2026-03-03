import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/main_menu/main_menu_screen.dart';
import '../presentation/scanner/barcode_scanning_screen.dart';
import '../presentation/scanner/task_summary_screen.dart';
import '../presentation/inventory/inventory_menu_screen.dart';
import '../presentation/inventory/quick_query_screen.dart';
import '../presentation/inventory/blind_count_screen.dart';
import '../presentation/replenishment/replenishment_screen.dart';
import '../presentation/printing/print_label_screen.dart';
import '../presentation/picking/picking_screen.dart';
import '../presentation/receiving/receiving_check_in_screen.dart';

class AppRoutes {
  static const String login = '/';
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

  static Map<String, WidgetBuilder> get routes {
    return {
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
    };
  }
}
