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
    defaultValue: 'http://localhost:8080',
  );
}

abstract final class AppRoutes {
  static const String root = '/';
  static const String customerMobile = '/mobile';
  static const String staffWeb = '/staff';
}
