import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/widgets/segue_product_image.dart';

void main() {
  testWidgets('resolves a path-only imageUrl against API_BASE_URL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SegueProductImage(imageUrl: '/images/products/bag1.png'),
      ),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final NetworkImage provider = image.image as NetworkImage;
    expect(provider.url, 'http://localhost:8080/images/products/bag1.png');
    expect(provider.headers, isNull);
  });

  testWidgets('leaves an already-absolute imageUrl unchanged', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SegueProductImage(imageUrl: 'https://example.com/sku2.png'),
      ),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final NetworkImage provider = image.image as NetworkImage;
    expect(provider.url, 'https://example.com/sku2.png');
  });

  testWidgets('shows the placeholder when imageUrl is null or empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SegueProductImage()));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Image'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: SegueProductImage(imageUrl: '')),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.text('Image'), findsOneWidget);
  });
}
