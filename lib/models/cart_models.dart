import 'json_utils.dart';
import 'product_models.dart';

class CartSaveRequest {
  const CartSaveRequest({
    required this.customerId,
    required this.productId,
    required this.color,
    required this.size,
  });

  final int customerId;
  final int productId;
  final String color;
  final String size;

  JsonMap toJson() {
    return <String, Object?>{
      'customerId': customerId,
      'productId': productId,
      'color': color,
      'size': size,
    };
  }
}

class CartItem {
  const CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.category,
    required this.skuId,
    required this.color,
    required this.size,
    required this.inventory,
    required this.actionButtonLabel,
    required this.savedAt,
  });

  factory CartItem.fromJson(JsonMap json) {
    final int skuId = intValue(json, 'skuId');

    return CartItem(
      cartItemId: intValue(json, 'cartItemId'),
      productId: intValue(json, 'productId'),
      productName: stringValue(json, 'productName'),
      imageUrl: stringValue(json, 'imageUrl'),
      category: stringValue(json, 'category'),
      skuId: skuId,
      color: stringValue(json, 'color'),
      size: stringValue(json, 'size'),
      inventory: InventoryStatus.fromJson(<String, Object?>{
        'skuId': skuId,
        'currentStoreInStock': json['currentStoreInStock'],
        'otherStoreInStock': json['otherStoreInStock'],
        'restockPlanned': json['restockPlanned'],
      }),
      actionButtonLabel: stringValue(json, 'actionButtonLabel'),
      savedAt: dateTimeValue(json, 'savedAt') ?? DateTime(1970),
    );
  }

  final int cartItemId;
  final int productId;
  final String productName;
  final String imageUrl;
  final String category;
  final int skuId;
  final String color;
  final String size;
  final InventoryStatus inventory;
  final String actionButtonLabel;
  final DateTime savedAt;

  bool get canStartLastIntent => actionButtonLabel == 'Last Intent 시작';

  ProductSkuSummary get skuSummary {
    return ProductSkuSummary(
      skuId: skuId,
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      color: color,
      size: size,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'cartItemId': cartItemId,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'category': category,
      'skuId': skuId,
      'color': color,
      'size': size,
      ...inventory.toJson()..remove('skuId'),
      'actionButtonLabel': actionButtonLabel,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}
