import 'json_utils.dart';

class MobileSkuOption {
  const MobileSkuOption({
    required this.skuId,
    required this.color,
    required this.size,
    required this.swatchValue,
  });

  final int skuId;
  final String color;
  final String size;
  final int swatchValue;

  JsonMap toJson() {
    return <String, Object?>{'skuId': skuId, 'color': color, 'size': size};
  }
}

class MobileProduct {
  const MobileProduct({
    required this.id,
    required this.name,
    required this.collection,
    required this.category,
    required this.price,
    required this.material,
    required this.dimensions,
    required this.origin,
    required this.season,
    required this.visualValue,
    required this.accentValue,
    required this.options,
    this.assetImagePath,
  });

  final int id;
  final String name;
  final String collection;
  final String category;
  final int price;
  final String material;
  final String dimensions;
  final String origin;
  final String season;
  final int visualValue;
  final int accentValue;
  final List<MobileSkuOption> options;
  final String? assetImagePath;

  List<String> get colors {
    return <String>{
      for (final MobileSkuOption option in options) option.color,
    }.toList();
  }

  List<String> get sizes {
    return <String>{
      for (final MobileSkuOption option in options) option.size,
    }.toList();
  }

  MobileSkuOption? skuFor({required String? color, required String? size}) {
    if (color == null || size == null) {
      return null;
    }

    for (final MobileSkuOption option in options) {
      if (option.color == color && option.size == size) {
        return option;
      }
    }
    return null;
  }

  MobileSkuOption optionForColor(String color) {
    return options.firstWhere(
      (MobileSkuOption option) => option.color == color,
      orElse: () => options.first,
    );
  }
}
