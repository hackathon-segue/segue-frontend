import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/repositories/mobile_product_catalog.dart';
import 'package:segue_frontend/utils/app_config.dart';
import 'package:segue_frontend/widgets/mobile_product_visual.dart';

void main() {
  testWidgets('customer mobile product visual renders the mapped asset image', (
    WidgetTester tester,
  ) async {
    final product = MobileProductCatalog.products.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: MobileProductVisual(product: product, compact: true),
          ),
        ),
      ),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final AssetImage provider = image.image as AssetImage;
    expect(provider.assetName, product.assetImagePath);
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('customer mobile product visual prefers backend imageUrl', (
    WidgetTester tester,
  ) async {
    final product = MobileProductCatalog.products.first.copyWith(
      imageUrl: '/images/products/server-bag.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: MobileProductVisual(product: product, compact: true),
          ),
        ),
      ),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final NetworkImage provider = _networkImageOf(image);
    expect(
      provider.url,
      '${AppConfig.apiBaseUrl}/images/products/server-bag.png',
    );
    expect(image.fit, BoxFit.contain);
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
