import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/sync_provider.dart';
import 'data/providers/picking_provider.dart';
import 'data/providers/receiving_provider.dart';
import 'data/providers/scanning_provider.dart';
import 'data/providers/quantity_confirmation_provider.dart';
import 'data/providers/replenishment_provider.dart';
import 'data/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => PickingProvider()),
        ChangeNotifierProvider(create: (_) => ReceivingProvider()),
        ChangeNotifierProvider(create: (_) => ScanningProvider()),
        ChangeNotifierProvider(create: (_) => QuantityConfirmationProvider()),
        ChangeNotifierProvider(create: (_) => ReplenishmentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const VerticalPartsWMS(),
    ),
  );
}

class VerticalPartsWMS extends StatelessWidget {
  const VerticalPartsWMS({super.key});
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'VerticalParts WMS Mobile',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
