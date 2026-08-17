import '../models/models.dart';

abstract final class MobileProductCatalog {
  static const List<MobileProduct> products = <MobileProduct>[
    MobileProduct(
      id: 1,
      name: 'Stark 백팩',
      collection: '블랙 / 모노그램',
      category: '백팩',
      price: 895000,
      material: '비세토스 코팅 캔버스 / 소가죽',
      dimensions: 'W 31 x H 42 x D 16 cm',
      origin: 'Made in Korea',
      season: '2024 FW',
      visualValue: 0xFF1F2937,
      accentValue: 0xFFB08968,
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 1,
          color: '블랙',
          size: '미디움',
          swatchValue: 0xFF111827,
        ),
        MobileSkuOption(
          skuId: 2,
          color: '코냑',
          size: '미디움',
          swatchValue: 0xFF9A5A2D,
        ),
        MobileSkuOption(
          skuId: 3,
          color: '네이비',
          size: '미디움',
          swatchValue: 0xFF1E3A5F,
        ),
      ],
    ),
    MobileProduct(
      id: 2,
      name: 'Mini Klara 숄더백',
      collection: '카멜 / 비세토스',
      category: '가방',
      price: 720000,
      material: '비세토스 캔버스 / 나파 가죽',
      dimensions: 'W 19 x H 13 x D 7 cm',
      origin: 'Made in Korea',
      season: '2024 FW',
      visualValue: 0xFFB87945,
      accentValue: 0xFF273449,
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 4,
          color: '카멜',
          size: '미니',
          swatchValue: 0xFFB87945,
        ),
        MobileSkuOption(
          skuId: 5,
          color: '베이지',
          size: '미니',
          swatchValue: 0xFFE8D9C5,
        ),
      ],
    ),
    MobileProduct(
      id: 3,
      name: 'Himmel Large Backpack',
      collection: 'MCM / 백팩',
      category: '백팩',
      price: 1150000,
      material: '비세토스 코팅 캔버스 / 소가죽',
      dimensions: 'W 32 x H 44 x D 18 cm',
      origin: 'Made in Korea',
      season: '2024 FW',
      visualValue: 0xFF8A542F,
      accentValue: 0xFF111827,
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 6,
          color: '코냑',
          size: '라지',
          swatchValue: 0xFF8A542F,
        ),
        MobileSkuOption(
          skuId: 7,
          color: '블랙',
          size: '라지',
          swatchValue: 0xFF111827,
        ),
        MobileSkuOption(
          skuId: 8,
          color: '네이비',
          size: '라지',
          swatchValue: 0xFF1E3A5F,
        ),
        MobileSkuOption(
          skuId: 9,
          color: '베이지',
          size: '라지',
          swatchValue: 0xFFE8D9C5,
        ),
      ],
    ),
    MobileProduct(
      id: 4,
      name: 'Patricia 크로스백',
      collection: '네이비 / 비세토스',
      category: '가방',
      price: 650000,
      material: '비세토스 캔버스 / 레더 트림',
      dimensions: 'W 21 x H 14 x D 8 cm',
      origin: 'Made in Korea',
      season: '2024 FW',
      visualValue: 0xFF1E3A5F,
      accentValue: 0xFFC8A46E,
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 10,
          color: '네이비',
          size: '스몰',
          swatchValue: 0xFF1E3A5F,
        ),
        MobileSkuOption(
          skuId: 11,
          color: '블랙',
          size: '스몰',
          swatchValue: 0xFF111827,
        ),
      ],
    ),
    MobileProduct(
      id: 5,
      name: 'Aren 카드 지갑',
      collection: '블랙 / 레더',
      category: '지갑',
      price: 280000,
      material: '스페니시 레더',
      dimensions: 'W 10 x H 7 x D 1 cm',
      origin: 'Made in Korea',
      season: '2024 FW',
      visualValue: 0xFF374151,
      accentValue: 0xFFB91C1C,
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 12,
          color: '블랙',
          size: '원사이즈',
          swatchValue: 0xFF111827,
        ),
        MobileSkuOption(
          skuId: 13,
          color: '베이지',
          size: '원사이즈',
          swatchValue: 0xFFE8D9C5,
        ),
      ],
    ),
  ];

  static MobileProduct productById(int id) {
    return products.firstWhere(
      (MobileProduct product) => product.id == id,
      orElse: () => products.first,
    );
  }

  static MobileProduct productBySkuId(int skuId) {
    return products.firstWhere(
      (MobileProduct product) => product.options.any(
        (MobileSkuOption option) => option.skuId == skuId,
      ),
      orElse: () => products.first,
    );
  }

  static MobileSkuOption? skuById(int skuId) {
    for (final MobileProduct product in products) {
      for (final MobileSkuOption option in product.options) {
        if (option.skuId == skuId) {
          return option;
        }
      }
    }
    return null;
  }
}
