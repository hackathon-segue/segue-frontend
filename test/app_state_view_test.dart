import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/utils/app_theme.dart';
import 'package:segue_frontend/widgets/app_state_view.dart';

void main() {
  testWidgets('renders loading, empty, error, and success states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SegueTheme.light(),
        home: Scaffold(
          body: ListView(
            children: const <Widget>[
              AppStateView.loading(),
              AppStateView.empty(),
              AppStateView.error(),
              AppStateView.success(),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('표시할 내용이 없습니다'), findsOneWidget);
    expect(find.text('다시 확인이 필요합니다'), findsOneWidget);
    expect(find.text('완료되었습니다'), findsOneWidget);
  });
}
