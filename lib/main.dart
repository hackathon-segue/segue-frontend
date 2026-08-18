import 'package:flutter/material.dart';

import 'providers/providers.dart';
import 'repositories/repositories.dart';
import 'screens/cart_inventory_screen.dart';
import 'screens/consent_declined_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/customer_lookup_screen.dart';
import 'screens/customer_mobile_entry_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/staff_home_screen.dart';
import 'utils/app_config.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const SegueApp());
}

class SegueApp extends StatefulWidget {
  const SegueApp({super.key});

  @override
  State<SegueApp> createState() => _SegueAppState();
}

class _SegueAppState extends State<SegueApp> {
  // A single repository + staff session controller instance is kept for the
  // lifetime of the app so the CA's lookup/consent/cart state survives
  // navigation across the staff/tablet route stack (home → customer lookup
  // → consent), mirroring how RepositoryScope is already shared.
  late final SegueRepository _repository = AppConfig.useMockData
      ? MockSegueRepository()
      : RealSegueRepository(apiClient: HttpSegueApiClient());
  late final StaffWebSessionController _staffSessionController =
      StaffWebSessionController(repository: _repository)
        ..onNewLookup = () => _lastIntentSessionManager.reset();
  late final LastIntentSessionManager _lastIntentSessionManager =
      LastIntentSessionManager(repository: _repository);

  @override
  void dispose() {
    _staffSessionController.dispose();
    _lastIntentSessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: _repository,
      child: StaffSessionScope(
        controller: _staffSessionController,
        child: LastIntentSessionScope(
          manager: _lastIntentSessionManager,
          child: MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: SegueTheme.light(),
            initialRoute: AppRoutes.root,
            routes: <String, WidgetBuilder>{
              AppRoutes.root: (_) => const CustomerMobileEntryScreen(),
              AppRoutes.customerMobile: (_) => const CustomerMobileEntryScreen(),
              AppRoutes.staffHome: (_) => const StaffHomeScreen(),
              AppRoutes.customerLookup: (_) => const CustomerLookupScreen(),
              AppRoutes.customerConsent: (_) => const ConsentScreen(),
              AppRoutes.customerConsentDeclined: (_) => const ConsentDeclinedScreen(),
              AppRoutes.cartInventory: (_) => const CartInventoryScreen(),
            },
            onUnknownRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (_) => NotFoundScreen(routeName: settings.name),
                settings: settings,
              );
            },
          ),
        ),
      ),
    );
  }
}
