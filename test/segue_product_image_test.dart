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
    final NetworkImage provider = _networkImageOf(image);
    expect(
      provider.url,
      'https://throat-bradford-blacks-yarn.trycloudflare.com/images/products/bag1.png',
    );
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
    final NetworkImage provider = _networkImageOf(image);
    expect(provider.url, 'https://example.com/sku2.png');
  });

  testWidgets('rewrites local absolute imageUrl against API_BASE_URL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SegueProductImage(
          imageUrl: 'http://localhost:8080/images/products/bag1.png',
        ),
      ),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final NetworkImage provider = _networkImageOf(image);
    expect(
      provider.url,
      'https://throat-bradford-blacks-yarn.trycloudflare.com/images/products/bag1.png',
    );
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

    await tester.pumpWidget(
      const MaterialApp(home: SegueProductImage(imageUrl: '/')),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.text('Image'), findsOneWidget);
  });
}

NetworkImage _networkImageOf(Image image) {
  final ImageProvider<Object> provider = image.image;
  if (provider is NetworkImage) {
    return provider;
  }
  if (provider is ResizeImage && provider.imageProvider is NetworkImage) {
    return provider.imageProvider as NetworkImage;
  }
  fail('Expected a NetworkImage, got ${provider.runtimeType}');
}
