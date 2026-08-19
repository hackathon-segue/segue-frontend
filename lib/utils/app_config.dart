abstract final class AppConfig {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Segue',
  );

  static const String appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://throat-bradford-blacks-yarn.trycloudflare.com',
  );

  static const int defaultStoreId = int.fromEnvironment(
    'STORE_ID',
    defaultValue: 1,
  );

  static const int defaultCustomerId = int.fromEnvironment(
    'CUSTOMER_ID',
    defaultValue: 1,
  );

  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 10,
  );

  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  static const bool debugGeneralProductCheck = bool.fromEnvironment(
    'DEBUG_GENERAL_PRODUCT_CHECK',
    defaultValue: false,
  );

  /// Sent on every real JSON API request, and only on ngrok-hosted product
  /// photo loads in `SegueProductImage`.
  /// Skips ngrok's free-tier browser-warning interstitial — an HTML page
  /// with no CORS headers that a real backend never sends, so ngrok tunnels
  /// used for `API_BASE_URL` during development work the same as a direct
  /// URL. Non-ngrok backends simply ignore this header.
  static const Map<String, String> ngrokSkipWarningHeader = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };
}

abstract final class AppRoutes {
  static const String root = '/';
  static const String customerMobile = '/mobile';
  static const String staffHome = '/staff/home';
  static const String customerLookup = '/staff/customers';
  static const String customerConsent = '/staff/consent';
  static const String customerConsentDeclined = '/staff/consent/declined';
  static const String cartInventory = '/staff/cart';
  static const String generalProductCheck = '/staff/product-check';
  static const String lastIntentIntro = '/staff/last-intent';
  static const String consultationHistory = '/staff/consultation-history';

  // The rest of the Last Intent flow (utterance onward) is reached via
  // Navigator.push with unnamed MaterialPageRoutes — this app has no
  // usePathUrlStrategy()/Router2 setup, so on web, an unnamed route never
  // gets its own browser history entry, which makes the browser's own back
  // button behave unpredictably (it can skip past several screens at once
  // instead of always landing on the immediately-previous one). None of
  // these are registered in MaterialApp's routes table (they need
  // customer/cartItem constructor args a static WidgetBuilder can't
  // provide) — they're only ever reached via a direct `.push`, and only
  // used as RouteSettings.name tags so Flutter/the browser can track one
  // history entry per screen, matching lastIntentIntro's existing pattern.
  static const String lastIntentUtterance = '/staff/last-intent/utterance';
  static const String lastIntentFollowUp = '/staff/last-intent/follow-up';
  static const String lastIntentConfirm = '/staff/last-intent/confirm';
  static const String lastIntentEdit = '/staff/last-intent/edit';
  static const String lastIntentCard = '/staff/last-intent/card';
  static const String lastIntentResult = '/staff/last-intent/result';
  static const String lastIntentAdditionalConsultation =
      '/staff/last-intent/additional-consultation';
  static const String lastIntentCompletion = '/staff/last-intent/completion';
}
