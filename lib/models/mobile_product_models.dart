import 'json_utils.dart';

class MobileSkuOption {
  const MobileSkuOption({
    required this.skuId,
    required this.color,
    required this.size,
    required this.swatchValue,
    this.material,
    this.weightGrams,
    this.storageStructure,
    this.wearStyle,
    this.laptopCompatible,
    this.colorFamily,
    this.colorTone,
    this.sizeGrade,
  });

  final int skuId;
  final String color;
  final String size;
  final int swatchValue;
  final String? material;
  final int? weightGrams;
  final String? storageStructure;
  final String? wearStyle;
  final bool? laptopCompatible;
  final String? colorFamily;
  final String? colorTone;
  final String? sizeGrade;

  JsonMap toJson() {
    return <String, Object?>{
      'skuId': skuId,
      'color': color,
      'size': size,
      if (material != null) 'material': material,
      if (weightGrams != null) 'weightGrams': weightGrams,
      if (storageStructure != null) 'storageStructure': storageStructure,
      if (wearStyle != null) 'wearStyle': wearStyle,
      if (laptopCompatible != null) 'laptopCompatible': laptopCompatible,
      if (colorFamily != null) 'colorFamily': colorFamily,
      if (colorTone != null) 'colorTone': colorTone,
      if (sizeGrade != null) 'sizeGrade': sizeGrade,
    };
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
    this.imageUrl,
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
  final String? imageUrl;
  final String? assetImagePath;

  MobileProduct copyWith({
    String? name,
    String? collection,
    String? category,
    int? price,
    String? material,
    String? dimensions,
    String? origin,
    String? season,
    int? visualValue,
    int? accentValue,
    List<MobileSkuOption>? options,
    String? imageUrl,
    String? assetImagePath,
  }) {
    return MobileProduct(
      id: id,
      name: name ?? this.name,
      collection: collection ?? this.collection,
      category: category ?? this.category,
      price: price ?? this.price,
      material: material ?? this.material,
      dimensions: dimensions ?? this.dimensions,
      origin: origin ?? this.origin,
      season: season ?? this.season,
      visualValue: visualValue ?? this.visualValue,
      accentValue: accentValue ?? this.accentValue,
      options: options ?? this.options,
      imageUrl: imageUrl ?? this.imageUrl,
      assetImagePath: assetImagePath ?? this.assetImagePath,
    );
  }

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

  MobileSkuOption? get firstAvailableOption {
    if (options.isEmpty) {
      return null;
    }
    return options.first;
  }

  List<String> sizesForColor(String? color) {
    final Iterable<MobileSkuOption> matchingOptions = color == null
        ? options
        : options.where((MobileSkuOption option) => option.color == color);
    return <String>{
      for (final MobileSkuOption option in matchingOptions) option.size,
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

  MobileSkuOption? firstOptionForColor(String color) {
    for (final MobileSkuOption option in options) {
      if (option.color == color) {
        return option;
      }
    }
    return null;
  }

  MobileSkuOption optionForColor(String color) {
    return options.firstWhere(
      (MobileSkuOption option) => option.color == color,
      orElse: () =>
          firstAvailableOption ??
          const MobileSkuOption(
            skuId: 0,
            color: 'Black',
            size: 'M',
            swatchValue: 0xFF111827,
          ),
    );
  }
}
