import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/widgets/segue_product_image.dart';

/// The real backend has been observed returning `imageUrl` as a path-only
/// value (e.g. `/images/products/bag1.png`) rather than the absolute
/// `https://...` URL API.md documents — Image.network would resolve that
/// relative to the Flutter app's own origin (always 404, different origin
/// than the API) unless SegueProductImage resolves it against
/// AppConfig.apiBaseUrl first.
void main() {
  testWidgets('resolves a path-only imageUrl against API_BASE_URL', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SegueProductImage(imageUrl: '/images/products/bag1.png')),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final NetworkImage provider = image.image as NetworkImage;
    // AppConfig.apiBaseUrl defaults to http://localhost:8080 in this test
    // binary (no --dart-define override).
    expect(provider.url, 'http://localhost:8080/images/products/bag1.png');
  });

  testWidgets('leaves an already-absolute imageUrl unchanged', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SegueProductImage(imageUrl: 'https://example.com/sku2.png')),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final NetworkImage provider = image.image as NetworkImage;
    expect(provider.url, 'https://example.com/sku2.png');
  });

  testWidgets('shows the placeholder when imageUrl is null or empty', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SegueProductImage()));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Image'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SegueProductImage(imageUrl: '')));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Image'), findsOneWidget);
  });
}
