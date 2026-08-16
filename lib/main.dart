import 'package:flutter/material.dart';

import 'screens/customer_mobile_entry_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/staff_web_entry_screen.dart';
import 'utils/app_config.dart';

void main() {
  runApp(const SegueApp());
}

class SegueApp extends StatelessWidget {
  const SegueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.root,
      routes: <String, WidgetBuilder>{
        AppRoutes.root: (_) => const CustomerMobileEntryScreen(),
        AppRoutes.customerMobile: (_) => const CustomerMobileEntryScreen(),
        AppRoutes.staffWeb: (_) => const StaffWebEntryScreen(),
      },
      onUnknownRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          builder: (_) => NotFoundScreen(routeName: settings.name),
          settings: settings,
        );
      },
    );
  }
}
