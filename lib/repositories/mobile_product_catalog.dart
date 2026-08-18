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
      assetImagePath: 'assets/images/mcm/category_backpack.png',
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
      assetImagePath: 'assets/images/mcm/product_round_crossbody.png',
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
      assetImagePath: 'assets/images/mcm/category_backpack.png',
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
      assetImagePath: 'assets/images/mcm/category_shoulder.png',
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
      assetImagePath: 'assets/images/mcm/menu_aren_east_west.png',
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
    MobileProduct(
      id: 6,
      name: 'Diamond 3D 카프스킨 숄더백',
      collection: '신상품',
      category: '가방',
      price: 2050000,
      material: '카프스킨 레더 / 코튼 안감',
      dimensions: 'W 24 x H 14 x D 7 cm',
      origin: 'Made in Italy',
      season: '2026 AW',
      visualValue: 0xFFE85F35,
      accentValue: 0xFF9F2E1E,
      assetImagePath: 'assets/images/mcm/category_new_bags.png',
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 14,
          color: '오렌지',
          size: '스몰',
          swatchValue: 0xFFE85F35,
        ),
        MobileSkuOption(
          skuId: 15,
          color: '카키',
          size: '스몰',
          swatchValue: 0xFF7A8061,
        ),
      ],
    ),
    MobileProduct(
      id: 7,
      name: 'Ottomar 비세토스 위켄더',
      collection: '토트백 & 쇼퍼백',
      category: '가방',
      price: 1290000,
      material: '비세토스 캔버스 / 나파 가죽',
      dimensions: 'W 45 x H 28 x D 20 cm',
      origin: 'Made in Korea',
      season: '2026 AW',
      visualValue: 0xFF66735F,
      accentValue: 0xFFC4A06A,
      assetImagePath: 'assets/images/mcm/product_black_tote.png',
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 16,
          color: '카키',
          size: '라지',
          swatchValue: 0xFF66735F,
        ),
        MobileSkuOption(
          skuId: 17,
          color: '블랙',
          size: '라지',
          swatchValue: 0xFF111827,
        ),
      ],
    ),
    MobileProduct(
      id: 8,
      name: 'New Liz 비세토스 쇼퍼',
      collection: '토트백 & 쇼퍼백',
      category: '가방',
      price: 1090000,
      material: '비세토스 캔버스 / 레더 트림',
      dimensions: 'W 35 x H 29 x D 14 cm',
      origin: 'Made in Korea',
      season: '2026 AW',
      visualValue: 0xFFB87945,
      accentValue: 0xFFE7CC9D,
      assetImagePath: 'assets/images/mcm/category_top_handle.png',
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 18,
          color: '코냑',
          size: '미디움',
          swatchValue: 0xFFB87945,
        ),
        MobileSkuOption(
          skuId: 19,
          color: '오렌지',
          size: '미디움',
          swatchValue: 0xFFE85F35,
        ),
      ],
    ),
    MobileProduct(
      id: 9,
      name: 'Mode 트라비아 가죽 토트',
      collection: '토트백 & 쇼퍼백',
      category: '가방',
      price: 1990000,
      material: '스페니시 레더',
      dimensions: 'W 38 x H 31 x D 15 cm',
      origin: 'Made in Italy',
      season: '2026 AW',
      visualValue: 0xFFE86645,
      accentValue: 0xFFB72F23,
      assetImagePath: 'assets/images/mcm/category_tote.png',
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 20,
          color: '오렌지',
          size: '라지',
          swatchValue: 0xFFE86645,
        ),
      ],
    ),
    MobileProduct(
      id: 10,
      name: 'Diamond 엠보스드 레더 탑 핸들백',
      collection: '탑 핸들백',
      category: '가방',
      price: 850000,
      material: '엠보스드 레더',
      dimensions: 'W 26 x H 18 x D 9 cm',
      origin: 'Made in Korea',
      season: '2026 AW',
      visualValue: 0xFF111827,
      accentValue: 0xFF454545,
      assetImagePath: 'assets/images/mcm/category_top_handle.png',
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 21,
          color: '블랙',
          size: '스몰',
          swatchValue: 0xFF111827,
        ),
        MobileSkuOption(
          skuId: 22,
          color: '코냑',
          size: '스몰',
          swatchValue: 0xFFB87945,
        ),
      ],
    ),
    MobileProduct(
      id: 11,
      name: 'Aren ECONYL 백팩',
      collection: '백팩',
      category: '백팩',
      price: 1050000,
      material: '리사이클 나일론 / 레더 트림',
      dimensions: 'W 29 x H 43 x D 14 cm',
      origin: 'Made in Korea',
      season: '2026 AW',
      visualValue: 0xFF6B7655,
      accentValue: 0xFF242A21,
      assetImagePath: 'assets/images/mcm/category_backpack.png',
      options: <MobileSkuOption>[
        MobileSkuOption(
          skuId: 23,
          color: '카키',
          size: '미디움',
          swatchValue: 0xFF6B7655,
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
