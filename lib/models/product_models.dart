import 'json_utils.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
  });

  factory Product.fromJson(JsonMap json) {
    return Product(
      id: intValue(json, 'productId', defaultValue: intValue(json, 'id')),
      name: stringValue(
        json,
        'productName',
        defaultValue: stringValue(json, 'name'),
      ),
      imageUrl: stringValue(json, 'imageUrl'),
      category: stringValue(json, 'category'),
    );
  }

  final int id;
  final String name;
  final String imageUrl;
  final String category;

  JsonMap toJson() {
    return <String, Object?>{
      'productId': id,
      'productName': name,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}

class Sku {
  const Sku({
    required this.id,
    required this.productId,
    required this.color,
    required this.size,
    this.material,
    this.weightGrams,
    this.storageStructure,
    this.wearStyle,
    this.laptopCompatible,
  });

  factory Sku.fromJson(JsonMap json) {
    return Sku(
      id: intValue(json, 'skuId', defaultValue: intValue(json, 'id')),
      productId: intValue(json, 'productId'),
      color: stringValue(json, 'color'),
      size: stringValue(json, 'size'),
      material: json['material']?.toString(),
      weightGrams: json['weightGrams'] is num
          ? (json['weightGrams']! as num).toInt()
          : int.tryParse(json['weightGrams']?.toString() ?? ''),
      storageStructure: json['storageStructure']?.toString(),
      wearStyle: json['wearStyle']?.toString(),
      laptopCompatible: json['laptopCompatible'] is bool
          ? json['laptopCompatible']! as bool
          : null,
    );
  }

  final int id;
  final int productId;
  final String color;
  final String size;
  final String? material;
  final int? weightGrams;
  final String? storageStructure;
  final String? wearStyle;
  final bool? laptopCompatible;

  JsonMap toJson() {
    return <String, Object?>{
      'skuId': id,
      'productId': productId,
      'color': color,
      'size': size,
      if (material != null) 'material': material,
      if (weightGrams != null) 'weightGrams': weightGrams,
      if (storageStructure != null) 'storageStructure': storageStructure,
      if (wearStyle != null) 'wearStyle': wearStyle,
      if (laptopCompatible != null) 'laptopCompatible': laptopCompatible,
    };
  }
}

class ProductSkuSummary {
  const ProductSkuSummary({
    required this.skuId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.color,
    required this.size,
  });

  factory ProductSkuSummary.fromJson(JsonMap json) {
    return ProductSkuSummary(
      skuId: intValue(json, 'skuId'),
      productId: intValue(json, 'productId'),
      productName: stringValue(json, 'productName'),
      imageUrl: stringValue(json, 'imageUrl'),
      color: stringValue(json, 'color'),
      size: stringValue(json, 'size'),
    );
  }

  final int skuId;
  final int productId;
  final String productName;
  final String imageUrl;
  final String color;
  final String size;

  JsonMap toJson() {
    return <String, Object?>{
      'skuId': skuId,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'color': color,
      'size': size,
    };
  }
}

class InventoryStatus {
  const InventoryStatus({
    required this.skuId,
    required this.currentStoreInStock,
    required this.otherStoreInStock,
    required this.restockPlanned,
  });

  factory InventoryStatus.fromJson(JsonMap json) {
    return InventoryStatus(
      skuId: intValue(json, 'skuId'),
      currentStoreInStock: boolValue(json, 'currentStoreInStock'),
      otherStoreInStock: boolValue(json, 'otherStoreInStock'),
      restockPlanned: boolValue(json, 'restockPlanned'),
    );
  }

  final int skuId;
  final bool currentStoreInStock;
  final bool otherStoreInStock;
  final bool restockPlanned;

  bool get needsLastIntent {
    return !currentStoreInStock && (otherStoreInStock || restockPlanned);
  }

  JsonMap toJson() {
    return <String, Object?>{
      'skuId': skuId,
      'currentStoreInStock': currentStoreInStock,
      'otherStoreInStock': otherStoreInStock,
      'restockPlanned': restockPlanned,
    };
  }
}
