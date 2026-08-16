import 'package:flutter/widgets.dart';

import '../repositories/repositories.dart';
import '../utils/app_config.dart';

class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    required this.repository,
    required super.child,
    super.key,
  });

  factory RepositoryScope.configured({required Widget child}) {
    return RepositoryScope(
      repository: AppConfig.useMockData
          ? MockSegueRepository()
          : RealSegueRepository(apiClient: HttpSegueApiClient()),
      child: child,
    );
  }

  final SegueRepository repository;

  static SegueRepository of(BuildContext context) {
    final RepositoryScope? scope = context
        .dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope is missing from the widget tree.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
