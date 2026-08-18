import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../repositories/repositories.dart';
import '../utils/app_config.dart';
import '../utils/app_design_tokens.dart';
import '../utils/execution_status_display.dart';
import '../widgets/app_state_view.dart';
import '../widgets/mobile_product_visual.dart';
import '../widgets/mobile_screen_scaffold.dart';

enum _MobileScreen {
  start,
  menu,
  products,
  detail,
  cartAdded,
  cart,
  results,
  onlinePurchase,
  storeVisit,
}

abstract final class _McmImageAssets {
  static const String startHero = 'assets/images/mcm/start_hero.png';
  static const String menuNewCollection =
      'assets/images/mcm/menu_new_collection.png';
  static const String menuBestSeller = 'assets/images/mcm/menu_best_seller.png';
  static const String menuPina = 'assets/images/mcm/menu_pina.png';
  static const String menuArenEastWest =
      'assets/images/mcm/menu_aren_east_west.png';
  static const String categoryNewBags =
      'assets/images/mcm/category_new_bags.png';
  static const String categoryTote = 'assets/images/mcm/category_tote.png';
  static const String categoryShoulder =
      'assets/images/mcm/category_shoulder.png';
  static const String categoryBackpack =
      'assets/images/mcm/category_backpack.png';
  static const String categoryTopHandle =
      'assets/images/mcm/category_top_handle.png';

  static String categoryHeroFor(String? category) {
    return switch (category ?? '가방') {
      '토트백 & 쇼퍼백' => categoryTote,
      '숄더백 & 크로스백' => categoryShoulder,
      '백팩' => categoryBackpack,
      '탑 핸들백' => categoryTopHandle,
      _ => categoryNewBags,
    };
  }
}

class CustomerMobileEntryScreen extends StatefulWidget {
  const CustomerMobileEntryScreen({super.key});

  @override
  State<CustomerMobileEntryScreen> createState() =>
      _CustomerMobileEntryScreenState();
}

class _CustomerMobileEntryScreenState extends State<CustomerMobileEntryScreen> {
  _MobileScreen _screen = _MobileScreen.start;
  MobileProduct _selectedProduct = MobileProductCatalog.products[2];
  String? _selectedCategory;
  String? _expandedMenuSection;
  String? _selectedColor;
  String? _selectedSize;
  CartItem? _lastSavedCartItem;
  final List<CartItem> _cartItems = <CartItem>[];
  bool _isSavingCart = false;
  bool _isLoadingCart = false;
  String? _cartSaveError;
  String? _cartError;
  final List<ConsultationResult> _consultationResults = <ConsultationResult>[];
  ConsultationResult? _selectedConsultationResult;
  bool _isLoadingResults = false;
  String? _resultsError;

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      _MobileScreen.start => _StartScreen(
        onOpenMenu: _openMenu,
        onOpenResults: () {
          _openResults();
        },
      ),
      _MobileScreen.menu => _MenuScreen(
        expandedSection: _expandedMenuSection,
        onClose: _openStart,
        onToggleSection: _toggleMenuSection,
        onOpenProducts: _openProductCategory,
        onOpenAllProducts: _openAllProducts,
        onOpenCart: _openCart,
        onOpenResults: () {
          _openResults();
        },
      ),
      _MobileScreen.products => _ProductListScreen(
        products: _filteredProducts,
        selectedCategory: _selectedCategory,
        onCategorySelected: (String? category) {
          if (category == null) {
            _openAllProducts();
            return;
          }
          _openProductCategory(category);
        },
        onProductSelected: _openDetail,
        onOpenMenu: _openMenu,
        onOpenResults: () {
          _openResults();
        },
      ),
      _MobileScreen.detail => _ProductDetailScreen(
        product: _selectedProduct,
        selectedColor: _selectedColor,
        selectedSize: _selectedSize,
        selectedSku: _selectedProduct.skuFor(
          color: _selectedColor,
          size: _selectedSize,
        ),
        onBack: _returnToProducts,
        onColorSelected: (String color) {
          setState(() {
            _selectedColor = color;
            _selectedSize = _selectedProduct.sizes.first;
          });
        },
        onSizeSelected: (String size) => setState(() => _selectedSize = size),
        onAddToCart: _saveSelectedCartItem,
        isSavingCart: _isSavingCart,
        cartSaveError: _cartSaveError,
      ),
      _MobileScreen.cartAdded => _CartAddedScreen(
        cartItem: _lastSavedCartItem,
        cartItems: _cartItems,
        onBack: _openDetailFromCartAdded,
        onOpenCart: _openCart,
        onContinueShopping: _returnToProducts,
      ),
      _MobileScreen.cart => _CartListScreen(
        cartItems: _cartItems,
        isLoading: _isLoadingCart,
        errorMessage: _cartError,
        onRetry: () => _loadCartItems(force: true),
        onBackToProducts: _returnToProducts,
        onTabSelected: _openTab,
      ),
      _MobileScreen.results => _ConsultationResultsScreen(
        results: _consultationResults,
        isLoading: _isLoadingResults,
        errorMessage: _resultsError,
        onRetry: () => _loadConsultationResults(force: true),
        onOnlinePurchase: _openOnlinePurchase,
        onStoreVisit: _openStoreVisit,
        onBackToHome: _openStart,
        onTabSelected: _openTab,
      ),
      _MobileScreen.onlinePurchase => _OnlinePurchaseScreen(
        result: _selectedConsultationResult,
        onBack: _openResultsWithoutReload,
      ),
      _MobileScreen.storeVisit => _StoreVisitScreen(
        result: _selectedConsultationResult,
        onBack: _openResultsWithoutReload,
      ),
    };
  }

  List<MobileProduct> get _filteredProducts {
    final String category = _selectedCategory ?? '가방';
    final List<MobileProduct> products = MobileProductCatalog.products.where((
      MobileProduct product,
    ) {
      return _matchesProductCategory(product, category);
    }).toList();
    products.sort((MobileProduct a, MobileProduct b) {
      final bool aIsNewSeason = a.season.contains('2026');
      final bool bIsNewSeason = b.season.contains('2026');
      if (aIsNewSeason != bIsNewSeason) {
        return aIsNewSeason ? -1 : 1;
      }
      return a.id.compareTo(b.id);
    });
    return products;
  }

  bool _matchesProductCategory(MobileProduct product, String category) {
    return switch (category) {
      '신상품' => product.season.contains('2026'),
      '가방' => product.category != '지갑',
      '토트백 & 쇼퍼백' => product.name.contains('토트') || product.name.contains('쇼퍼'),
      '숄더백 & 크로스백' =>
        product.name.contains('숄더') ||
            product.name.contains('크로스') ||
            product.name.contains('Patricia'),
      '백팩' => product.category == '백팩',
      '탑 핸들백' =>
        product.name.contains('탑 핸들') || product.name.contains('Klara'),
      _ => product.category == category,
    };
  }

  void _openStart() {
    setState(() => _screen = _MobileScreen.start);
  }

  void _openMenu() {
    setState(() {
      _expandedMenuSection ??= '가방';
      _screen = _MobileScreen.menu;
    });
  }

  void _toggleMenuSection(String section) {
    setState(() {
      _expandedMenuSection = _expandedMenuSection == section ? null : section;
    });
  }

  void _openAllProducts() {
    setState(() {
      _selectedCategory = null;
      _screen = _MobileScreen.products;
    });
  }

  void _openProductCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _screen = _MobileScreen.products;
    });
  }

  void _returnToProducts() {
    setState(() => _screen = _MobileScreen.products);
  }

  void _openDetail(MobileProduct product) {
    setState(() {
      _selectedProduct = product;
      _selectedColor = product.colors.first;
      _selectedSize = product.sizes.first;
      _screen = _MobileScreen.detail;
    });
  }

  void _openTab(CustomerMobileTab tab) {
    if (tab == CustomerMobileTab.results) {
      _openResults();
      return;
    }
    if (tab == CustomerMobileTab.cart) {
      _openCart();
      return;
    }

    setState(() {
      _screen = switch (tab) {
        CustomerMobileTab.home => _MobileScreen.start,
        CustomerMobileTab.products => _MobileScreen.products,
        CustomerMobileTab.cart => _MobileScreen.cart,
        CustomerMobileTab.results => _MobileScreen.results,
      };
    });
  }

  void _openCart() {
    setState(() => _screen = _MobileScreen.cart);
    if (!_isLoadingCart) {
      _loadCartItems(force: true);
    }
  }

  void _openDetailFromCartAdded() {
    setState(() => _screen = _MobileScreen.detail);
  }

  void _openResultsWithoutReload() {
    setState(() => _screen = _MobileScreen.results);
  }

  Future<void> _openResults() async {
    setState(() => _screen = _MobileScreen.results);
    if (_consultationResults.isEmpty && !_isLoadingResults) {
      await _loadConsultationResults();
    }
  }

  void _openOnlinePurchase(ConsultationResult result) {
    setState(() {
      _selectedConsultationResult = result;
      _screen = _MobileScreen.onlinePurchase;
    });
  }

  void _openStoreVisit(ConsultationResult result) {
    setState(() {
      _selectedConsultationResult = result;
      _screen = _MobileScreen.storeVisit;
    });
  }

  Future<void> _loadConsultationResults({bool force = false}) async {
    if (_isLoadingResults || (_consultationResults.isNotEmpty && !force)) {
      return;
    }

    setState(() {
      _isLoadingResults = true;
      _resultsError = null;
    });

    try {
      final List<ConsultationResult> results = await RepositoryScope.of(
        context,
      ).fetchConsultationResults(AppConfig.defaultCustomerId);
      results.sort(
        (ConsultationResult a, ConsultationResult b) =>
            b.consultedAt.compareTo(a.consultedAt),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _consultationResults
          ..clear()
          ..addAll(results);
        _selectedConsultationResult = results.isEmpty ? null : results.first;
        _isLoadingResults = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingResults = false;
        _resultsError = _errorMessage(
          error,
          fallback: '상담 결과를 불러오지 못했습니다. 다시 시도해 주세요.',
        );
      });
    }
  }

  Future<void> _loadCartItems({bool force = false}) async {
    if (_isLoadingCart || (_cartItems.isNotEmpty && !force)) {
      return;
    }

    setState(() {
      _isLoadingCart = true;
      _cartError = null;
    });

    try {
      final List<CartItem> items = await RepositoryScope.of(context).fetchCart(
        customerId: AppConfig.defaultCustomerId,
        storeId: AppConfig.defaultStoreId,
      );
      items.sort((CartItem a, CartItem b) => b.savedAt.compareTo(a.savedAt));
      if (!mounted) {
        return;
      }
      setState(() {
        _cartItems
          ..clear()
          ..addAll(items);
        _isLoadingCart = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCart = false;
        _cartError = _errorMessage(
          error,
          fallback: '장바구니를 불러오지 못했습니다. 다시 시도해 주세요.',
        );
      });
    }
  }

  Future<void> _saveSelectedCartItem() async {
    final MobileSkuOption? selectedSku = _selectedProduct.skuFor(
      color: _selectedColor,
      size: _selectedSize,
    );
    if (selectedSku == null || _isSavingCart) {
      return;
    }

    setState(() {
      _isSavingCart = true;
      _cartSaveError = null;
    });

    try {
      final CartItem cartItem = await RepositoryScope.of(context).saveCartItem(
        CartSaveRequest(
          customerId: AppConfig.defaultCustomerId,
          productId: _selectedProduct.id,
          color: selectedSku.color,
          size: selectedSku.size,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingCart = false;
        _lastSavedCartItem = cartItem;
        _cartItems.removeWhere((CartItem item) => item.skuId == cartItem.skuId);
        _cartItems.insert(0, cartItem);
        _cartError = null;
        _screen = _MobileScreen.cartAdded;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingCart = false;
        _cartSaveError = _errorMessage(
          error,
          fallback: '장바구니 저장에 실패했습니다. 다시 시도해 주세요.',
        );
      });
    }
  }
}

class _StartScreen extends StatelessWidget {
  const _StartScreen({required this.onOpenMenu, required this.onOpenResults});

  final VoidCallback onOpenMenu;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      backgroundColor: const Color(0xFFB7C79B),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _CampaignBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    top: 28,
                    left: -10,
                    right: -10,
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: '메뉴 열기',
                          onPressed: onOpenMenu,
                          color: Colors.white,
                          iconSize: 34,
                          icon: const Icon(Icons.menu),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'SEGUE 내역 확인',
                          onPressed: onOpenResults,
                          color: Colors.white,
                          iconSize: 33,
                          icon: const Icon(Icons.person_outline),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    top: 104,
                    left: 0,
                    right: 0,
                    child: _StartScreenLogo(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartScreenLogo extends StatelessWidget {
  const _StartScreenLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text(
                'MCM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 0.92,
                  letterSpacing: 0,
                ),
              ),
              Transform.translate(
                offset: const Offset(-2, 0),
                child: const _OutlinedText(
                  'LXXVI',
                  fontSize: 43,
                  strokeWidth: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '1976',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 0.9,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText(
    this.text, {
    required this.fontSize,
    required this.strokeWidth,
  });

  final String text;
  final double fontSize;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w300,
        height: 0.92,
        letterSpacing: 0,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = Colors.white,
      ),
    );
  }
}

class _MenuScreen extends StatelessWidget {
  const _MenuScreen({
    required this.expandedSection,
    required this.onClose,
    required this.onToggleSection,
    required this.onOpenProducts,
    required this.onOpenAllProducts,
    required this.onOpenCart,
    required this.onOpenResults,
  });

  final String? expandedSection;
  final VoidCallback onClose;
  final ValueChanged<String> onToggleSection;
  final ValueChanged<String> onOpenProducts;
  final VoidCallback onOpenAllProducts;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(onLeadingPressed: onClose, leadingIcon: Icons.close),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                children: <Widget>[
                  _MenuPrimaryRow(
                    label: '신상품',
                    expanded: expandedSection == '신상품',
                    onTap: () => onToggleSection('신상품'),
                  ),
                  if (expandedSection == '신상품') ...<Widget>[
                    _MenuSubItem(
                      label: '여성 신상품',
                      onTap: () => onOpenProducts('신상품'),
                    ),
                    _MenuSubItem(
                      label: '남성 신상품',
                      onTap: () => onOpenProducts('신상품'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _EditorialTile(
                            assetPath: _McmImageAssets.menuNewCollection,
                            label: '여성 신상품 둘러보기',
                            onTap: () => onOpenProducts('신상품'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _EditorialTile(
                            assetPath: _McmImageAssets.menuBestSeller,
                            label: '남성 신상품 둘러보기',
                            onTap: () => onOpenProducts('신상품'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuPrimaryRow(
                    label: '가방',
                    expanded: expandedSection == '가방',
                    onTap: () => onToggleSection('가방'),
                  ),
                  if (expandedSection == '가방') ...<Widget>[
                    _MenuSubItem(
                      label: '신상품',
                      onTap: () => onOpenProducts('신상품'),
                    ),
                    _MenuSubItem(label: '모두보기', onTap: onOpenAllProducts),
                    _MenuSubItem(
                      label: '토트백 & 쇼퍼백',
                      onTap: () => onOpenProducts('토트백 & 쇼퍼백'),
                    ),
                    _MenuSubItem(
                      label: '숄더백 & 크로스백',
                      onTap: () => onOpenProducts('숄더백 & 크로스백'),
                    ),
                    _MenuSubItem(
                      label: '백팩',
                      onTap: () => onOpenProducts('백팩'),
                    ),
                    _MenuSubItem(
                      label: '탑 핸들백',
                      onTap: () => onOpenProducts('탑 핸들백'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _EditorialTile(
                            assetPath: _McmImageAssets.menuPina,
                            label: 'PINA 둘러보기',
                            onTap: () => onOpenProducts('숄더백 & 크로스백'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _EditorialTile(
                            assetPath: _McmImageAssets.menuArenEastWest,
                            label: 'AREN EAST WEST 둘러보기',
                            onTap: () => onOpenProducts('탑 핸들백'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuPrimaryRow(
                    label: 'MCM 소개',
                    expanded: false,
                    onTap: () => onToggleSection('MCM 소개'),
                  ),
                  _MenuPrimaryRow(
                    label: 'SEGUE 소개',
                    expanded: false,
                    onTap: () => onToggleSection('SEGUE 소개'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: Column(
                children: <Widget>[
                  _MenuFooterRow(
                    label: '로그인',
                    icon: Icons.person_outline,
                    onTap: onClose,
                  ),
                  _MenuFooterRow(
                    label: '쇼핑백',
                    icon: Icons.shopping_bag_outlined,
                    onTap: onOpenCart,
                  ),
                  _MenuFooterRow(
                    label: 'SEGUE 내역 확인',
                    icon: Icons.receipt_long_outlined,
                    onTap: onOpenResults,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _McmPhoneShell extends StatelessWidget {
  const _McmPhoneShell({
    required this.child,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7F7F7C),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.mobileContentMaxWidth,
          ),
          child: ColoredBox(color: backgroundColor, child: child),
        ),
      ),
    );
  }
}

class _McmTopBar extends StatelessWidget {
  const _McmTopBar({
    required this.onLeadingPressed,
    this.leadingIcon = Icons.menu,
    this.onProfilePressed,
  });

  final VoidCallback onLeadingPressed;
  final IconData leadingIcon;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: leadingIcon == Icons.close ? '메뉴 닫기' : '메뉴 열기',
              onPressed: onLeadingPressed,
              icon: Icon(leadingIcon, size: 22),
            ),
          ),
          const Text(
            'MCM',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 0,
            ),
          ),
          if (onProfilePressed != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'SEGUE 내역 확인',
                onPressed: onProfilePressed,
                icon: const Icon(Icons.person_outline, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

class _CampaignBackdrop extends StatelessWidget {
  const _CampaignBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            _McmImageAssets.startHero,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }
}

class _CampaignMiniature extends StatelessWidget {
  const _CampaignMiniature({
    required this.assetPath,
    this.large = false,
    this.caption,
  });

  final String assetPath;
  final bool large;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF3F0E8)),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2DED4)),
                gradient: large
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          if (large && caption != null)
            Positioned(
              left: 18,
              bottom: 14,
              child: Text(
                caption!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuPrimaryRow extends StatelessWidget {
  const _MenuPrimaryRow({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSubItem extends StatelessWidget {
  const _MenuSubItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 0, 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _EditorialTile extends StatelessWidget {
  const _EditorialTile({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.65,
            child: _CampaignMiniature(assetPath: assetPath),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              const Icon(Icons.arrow_forward, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuFooterRow extends StatelessWidget {
  const _MenuFooterRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 43,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFBEBEBE))),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(icon, size: 17),
          ],
        ),
      ),
    );
  }
}

class _ProductListScreen extends StatelessWidget {
  const _ProductListScreen({
    required this.products,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onProductSelected,
    required this.onOpenMenu,
    required this.onOpenResults,
  });

  final List<MobileProduct> products;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<MobileProduct> onProductSelected;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    final String title = selectedCategory ?? '가방';
    final String heroAssetPath = _McmImageAssets.categoryHeroFor(
      selectedCategory,
    );
    const List<String?> categories = <String?>[
      null,
      '신상품',
      '토트백 & 쇼퍼백',
      '숄더백 & 크로스백',
      '백팩',
      '탑 핸들백',
    ];

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onOpenMenu,
              onProfilePressed: onOpenResults,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _CategoryTrail(
                    selectedCategory: selectedCategory,
                    categories: categories,
                    onCategorySelected: onCategorySelected,
                  ),
                  _ProductCampaignHero(assetPath: heroAssetPath, title: title),
                  const _ProductSortRow(),
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: AppStateView.empty(title: '검색 결과가 없습니다'),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        children: <Widget>[
                          for (final MobileProduct product in products)
                            _ProductGridTile(
                              product: product,
                              onTap: () => onProductSelected(product),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTrail extends StatelessWidget {
  const _CategoryTrail({
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  final String? selectedCategory;
  final List<String?> categories;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text('>', style: TextStyle(fontSize: 10)),
            ),
          );
        },
        itemBuilder: (BuildContext context, int index) {
          final String? category = categories[index];
          final bool selected = selectedCategory == category;
          return Center(
            child: InkWell(
              onTap: () => onCategorySelected(category),
              child: Text(
                index == 0 ? '가방' : category!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? Colors.black : const Color(0xFF5C5C5C),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCampaignHero extends StatelessWidget {
  const _ProductCampaignHero({required this.assetPath, required this.title});

  final String assetPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: '$title 상품 목록 캠페인',
          child: AspectRatio(
            aspectRatio: 1.96,
            child: _CampaignMiniature(
              assetPath: assetPath,
              large: true,
              caption: 'AUTUMN WINTER 2026',
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '정렬 기준 / 영역',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '기준순',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.keyboard_arrow_down, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductSortRow extends StatelessWidget {
  const _ProductSortRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ProductGridTile extends StatelessWidget {
  const _ProductGridTile({required this.product, required this.onTap});

  final MobileProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFE4E4E4)),
          bottom: BorderSide(color: Color(0xFFE4E4E4)),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      product.collection,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A8A8A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.shopping_bag_outlined, size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: MobileProductVisual(product: product, compact: true),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                _formatWon(product.price),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  for (final String color in product.colors.take(
                    3,
                  )) ...<Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Color(product.optionForColor(color).swatchValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDetailScreen extends StatelessWidget {
  const _ProductDetailScreen({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    required this.selectedSku,
    required this.onBack,
    required this.onColorSelected,
    required this.onSizeSelected,
    required this.onAddToCart,
    required this.isSavingCart,
    required this.cartSaveError,
  });

  final MobileProduct product;
  final String? selectedColor;
  final String? selectedSize;
  final MobileSkuOption? selectedSku;
  final VoidCallback onBack;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onAddToCart;
  final bool isSavingCart;
  final String? cartSaveError;

  @override
  Widget build(BuildContext context) {
    final Color selectedVisualColor = selectedColor == null
        ? Color(product.visualValue)
        : Color(product.optionForColor(selectedColor!).swatchValue);
    final String colorLabel = selectedColor ?? product.colors.first;
    final String sizeLabel = selectedSize ?? 'M';

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(onLeadingPressed: onBack, onProfilePressed: onBack),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '신규 컬렉션',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF6D6D6D),
                            ),
                          ),
                        ),
                        Icon(Icons.shopping_bag_outlined, size: 14),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 46, 48, 30),
                    child: AspectRatio(
                      aspectRatio: 0.92,
                      child: MobileProductVisual(
                        product: product,
                        colorOverride: selectedVisualColor,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E5E5)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _formatWon(product.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          '색상: $colorLabel',
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '사이즈: $sizeLabel',
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 22),
                        if (product.colors.length > 1)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String color in product.colors)
                                _McmOptionChip(
                                  label: color,
                                  selected: selectedColor == color,
                                  onTap: () => onColorSelected(color),
                                ),
                            ],
                          ),
                        if (product.sizes.length > 1) ...<Widget>[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String size in product.sizes)
                                _McmOptionChip(
                                  label: size,
                                  selected: selectedSize == size,
                                  onTap: () => onSizeSelected(size),
                                ),
                            ],
                          ),
                        ],
                        if (cartSaveError != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            cartSaveError!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _McmPrimaryButton(
                          label: isSavingCart ? '저장 중' : '쇼핑백에 추가',
                          onPressed: selectedSku == null || isSavingCart
                              ? null
                              : onAddToCart,
                        ),
                        const SizedBox(height: 18),
                        const _McmFinePrint(
                          '이 제품으로 SEGUE 상담을 받고 싶으신가요? 쇼핑백에 추가해 보세요.',
                        ),
                        const SizedBox(height: 6),
                        const _McmUnderlinedText('SEGUE 상담이 무엇인가요?'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _McmOptionChip extends StatelessWidget {
  const _McmOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 28,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        constraints: const BoxConstraints(minWidth: 42),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _McmPrimaryButton extends StatelessWidget {
  const _McmPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF8A8A8A),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _McmOutlinedButton extends StatelessWidget {
  const _McmOutlinedButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _McmFinePrint extends StatelessWidget {
  const _McmFinePrint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF777777),
        fontSize: 9,
        height: 1.45,
      ),
    );
  }
}

class _McmUnderlinedText extends StatelessWidget {
  const _McmUnderlinedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4A4A4A),
        fontSize: 9,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

class _McmSectionDivider extends StatelessWidget {
  const _McmSectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8));
  }
}

class _McmEmptyState extends StatelessWidget {
  const _McmEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, height: 1.45),
    );
  }
}

class _ShoppingBagLineItem extends StatelessWidget {
  const _ShoppingBagLineItem({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final MobileProduct product = MobileProductCatalog.productById(
      item.productId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 108,
            height: 108,
            child: MobileProductVisual(product: product, compact: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatWon(product.price),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(item.color, style: const TextStyle(fontSize: 10)),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.size,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    const Text('수량 1', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingBagSummary extends StatelessWidget {
  const _ShoppingBagSummary({
    required this.itemCount,
    required this.totalPrice,
  });

  final int itemCount;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _McmAmountRow(
          label: '소계 ($itemCount개 품목)',
          value: _formatWon(totalPrice),
        ),
        const _McmAmountRow(label: '배송비', value: '무료'),
        _McmAmountRow(
          label: '예상 합계',
          value: _formatWon(totalPrice),
          bold: true,
        ),
      ],
    );
  }
}

class _ShoppingBagActionPanel extends StatelessWidget {
  const _ShoppingBagActionPanel({
    required this.totalLabel,
    required this.totalPrice,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String totalLabel;
  final int totalPrice;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _McmAmountRow(label: totalLabel, value: _formatWon(totalPrice)),
            const SizedBox(height: 12),
            _McmPrimaryButton(label: primaryLabel, onPressed: onPrimary),
            if (secondaryLabel != null && onSecondary != null) ...<Widget>[
              const SizedBox(height: 7),
              _McmOutlinedButton(
                label: secondaryLabel!,
                onPressed: onSecondary!,
              ),
            ],
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: _McmFinePrint('쇼핑백에 상품을 추가하면 SEGUE 상담을 손쉽게 받을 수 있어요.'),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: _McmUnderlinedText('SEGUE 상담이 무엇인가요?'),
            ),
          ],
        ),
      ),
    );
  }
}

class _McmAmountRow extends StatelessWidget {
  const _McmAmountRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegueHistoryRow extends StatelessWidget {
  const _SegueHistoryRow({required this.result, required this.onTap});

  final ConsultationResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MobileProduct product = MobileProductCatalog.productBySkuId(
      result.skuId,
    );
    final MobileSkuOption? sku = MobileProductCatalog.skuById(result.skuId);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 92,
                  height: 76,
                  child: MobileProductVisual(
                    product: product,
                    colorOverride: sku == null ? null : Color(sku.swatchValue),
                    compact: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        color: const Color(0xFF2D2D2D),
                        child: const Text(
                          '상담 제품',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatWon(product.price),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${sku?.color ?? 'Black'}\n${sku?.size ?? 'M'}',
                        style: const TextStyle(fontSize: 10, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatKoreanDateTime(result.consultedAt),
                style: const TextStyle(fontSize: 9, color: Color(0xFF777777)),
              ),
            ),
            const _McmSectionDivider(),
          ],
        ),
      ),
    );
  }
}

class _McmResultBlock extends StatelessWidget {
  const _McmResultBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(fontSize: 10, height: 1.45)),
        ],
      ),
    );
  }
}

class _CartAddedScreen extends StatelessWidget {
  const _CartAddedScreen({
    required this.cartItem,
    required this.cartItems,
    required this.onBack,
    required this.onOpenCart,
    required this.onContinueShopping,
  });

  final CartItem? cartItem;
  final List<CartItem> cartItems;
  final VoidCallback onBack;
  final VoidCallback onOpenCart;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final List<CartItem> displayItems = cartItems.isEmpty
        ? <CartItem>[if (cartItem != null) cartItem!]
        : cartItems;
    final int itemCount = displayItems.length;
    final int totalPrice = displayItems.fold<int>(0, (int sum, CartItem item) {
      return sum + MobileProductCatalog.productById(item.productId).price;
    });

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onBack,
              leadingIcon: Icons.close,
              onProfilePressed: onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          '새로운 상품이 쇼핑백에 추가되었습니다!',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '($itemCount개 품목)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (displayItems.isEmpty)
                    const _McmEmptyState(message: '저장된 항목이 없습니다')
                  else
                    for (final CartItem item in displayItems) ...<Widget>[
                      _ShoppingBagLineItem(item: item),
                      const _McmSectionDivider(),
                    ],
                ],
              ),
            ),
            _ShoppingBagActionPanel(
              totalLabel: '합계:',
              totalPrice: totalPrice,
              primaryLabel: '쇼핑백 확인하기',
              onPrimary: onOpenCart,
              secondaryLabel: '계속 쇼핑하기',
              onSecondary: onContinueShopping,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartListScreen extends StatelessWidget {
  const _CartListScreen({
    required this.cartItems,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onBackToProducts,
    required this.onTabSelected,
  });

  final List<CartItem> cartItems;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onBackToProducts;
  final ValueChanged<CustomerMobileTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final int totalPrice = cartItems.fold<int>(0, (int sum, CartItem item) {
      return sum + MobileProductCatalog.productById(item.productId).price;
    });

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onBackToProducts,
              onProfilePressed: () => onTabSelected(CustomerMobileTab.results),
            ),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  if (isLoading) {
                    return const Center(
                      child: AppStateView.loading(title: '장바구니를 불러오는 중입니다'),
                    );
                  }

                  if (errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: AppStateView.error(
                          title: '장바구니를 불러오지 못했습니다',
                          message: errorMessage,
                          onAction: onRetry,
                        ),
                      ),
                    );
                  }

                  if (cartItems.isEmpty) {
                    return const Center(
                      child: _McmEmptyState(
                        message: '쇼핑백이 비어 있습니다.\n로그인 후 쇼핑백 확인하러 가기',
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: <Widget>[
                      Text(
                        '나의 쇼핑백(${cartItems.length}개 품목)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final CartItem cartItem in cartItems) ...<Widget>[
                        _ShoppingBagLineItem(item: cartItem),
                        const _McmSectionDivider(),
                      ],
                      const SizedBox(height: 10),
                      _ShoppingBagSummary(
                        itemCount: cartItems.length,
                        totalPrice: totalPrice,
                      ),
                    ],
                  );
                },
              ),
            ),
            if (!isLoading && errorMessage == null && cartItems.isNotEmpty)
              _ShoppingBagActionPanel(
                totalLabel: '예상 합계',
                totalPrice: totalPrice,
                primaryLabel: '결제하기',
                onPrimary: onBackToProducts,
              ),
          ],
        ),
      ),
    );
  }
}

class _ConsultationResultsScreen extends StatelessWidget {
  const _ConsultationResultsScreen({
    required this.results,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOnlinePurchase,
    required this.onStoreVisit,
    required this.onBackToHome,
    required this.onTabSelected,
  });

  final List<ConsultationResult> results;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<ConsultationResult> onOnlinePurchase;
  final ValueChanged<ConsultationResult> onStoreVisit;
  final VoidCallback onBackToHome;
  final ValueChanged<CustomerMobileTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onBackToHome,
              onProfilePressed: onBackToHome,
            ),
            const SizedBox(height: 12),
            const Text(
              'SEGUE 내역',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  if (isLoading) {
                    return const Center(
                      child: AppStateView.loading(title: '상담 결과를 불러오는 중입니다'),
                    );
                  }

                  if (errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: AppStateView.error(
                          message: errorMessage,
                          onAction: onRetry,
                        ),
                      ),
                    );
                  }

                  if (results.isEmpty) {
                    return const Center(
                      child: _McmEmptyState(message: '상담 결과가 없습니다'),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            '총 ${results.length}건의 상담 기록',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF565656),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '최근 상담순',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF565656),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 13),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final ConsultationResult result in results)
                        _SegueHistoryRow(
                          result: result,
                          onTap: () => onOnlinePurchase(result),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlinePurchaseScreen extends StatelessWidget {
  const _OnlinePurchaseScreen({required this.result, required this.onBack});

  final ConsultationResult? result;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ConsultationResult? currentResult = result;

    if (currentResult == null) {
      return _MissingConsultationResultScreen(
        title: 'SEGUE 결과',
        onBack: onBack,
      );
    }

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(onLeadingPressed: onBack, leadingIcon: Icons.close),
            const Text(
              'SEGUE 결과',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: _ConsultationProductRow(
                      result: currentResult,
                      showBadge: true,
                    ),
                  ),
                  const _McmSectionDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _McmResultBlock(
                          label: '핵심 조건',
                          value: currentResult.coreConditions,
                        ),
                        _McmResultBlock(
                          label: '결과 유형',
                          value: _resultTypeLabel(currentResult.resultType),
                        ),
                        _McmResultBlock(
                          label: '추천 경로',
                          value: currentResult.recommendedPath,
                        ),
                        _McmResultBlock(
                          label: '상담 날짜',
                          value: _formatKoreanDateTime(
                            currentResult.consultedAt,
                          ),
                        ),
                        _McmResultBlock(
                          label: '처리 상태',
                          value: _executionStatusMessage(currentResult),
                        ),
                        _McmResultBlock(
                          label: '처리 갱신',
                          value: _formatKoreanDateTime(
                            currentResult.executionUpdatedAt,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _McmSectionDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _ConsultationProductRow(
                          result: currentResult,
                          showBadge: true,
                          recommended: true,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          '상담 완료',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '추천 제품은 Client Advisor와 함께 매장에서 확인했습니다. 또한 해당 매장에서 바로 구매가 진행되었습니다.',
                          style: TextStyle(fontSize: 10, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreVisitScreen extends StatelessWidget {
  const _StoreVisitScreen({required this.result, required this.onBack});

  final ConsultationResult? result;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ConsultationResult? currentResult = result;
    final ThemeData theme = Theme.of(context);

    if (currentResult == null) {
      return _MissingConsultationResultScreen(
        title: '매장 재방문 안내',
        onBack: onBack,
      );
    }

    return MobileScreenScaffold(
      title: '매장 재방문 안내',
      showBackButton: true,
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Text('매장 재방문 안내', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '상담 내용을 바탕으로 매장 방문을 준비해 드립니다.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            title: '재방문 상담 결과',
            children: <Widget>[
              _ResultField(label: '상담 제품', value: currentResult.productName),
              _ResultField(
                label: '결과 유형',
                value: _resultTypeLabel(currentResult.resultType),
              ),
              _ResultField(
                label: '처리 상태',
                value: _executionStatusMessage(currentResult),
              ),
              _ResultField(
                label: '처리 갱신',
                value: _formatKoreanDateTime(currentResult.executionUpdatedAt),
              ),
              _ResultField(
                label: '상담 일시',
                value: _formatKoreanDateTime(currentResult.consultedAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _InfoCard(
            title: '방문 전 준비 사항',
            children: <Widget>[
              _BulletPanel(text: '이 화면을 매장 직원에게 보여주시면 상담 내용을 바로 이어갈 수 있습니다.'),
              SizedBox(height: AppSpacing.sm),
              _BulletPanel(
                text: 'Client Advisor가 제품 상태와 재고를 재확인한 뒤 다음 단계를 안내합니다.',
              ),
              SizedBox(height: AppSpacing.sm),
              _BulletPanel(
                text: '재고 및 입고 정보는 방문 시점에 다시 확인되며, 현재 표시는 상담 기준입니다.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            title: '방문 예정 매장',
            children: <Widget>[
              Text('MCM 청담 플래그십 스토어', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '서울 강남구 압구정로 442 · 운영시간 11:00-20:00',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            title: '요청 접수 안내',
            children: <Widget>[
              Text(
                '이 안내는 예약·구매·제품 이동의 완료가 아니라 Client Advisor의 후속 확인을 돕기 위한 자료입니다.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissingConsultationResultScreen extends StatelessWidget {
  const _MissingConsultationResultScreen({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return MobileScreenScaffold(
      title: title,
      showBackButton: true,
      onBack: onBack,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: AppStateView.empty(title: '선택된 상담 결과가 없습니다'),
        ),
      ),
    );
  }
}

class _ConsultationProductRow extends StatelessWidget {
  const _ConsultationProductRow({
    required this.result,
    this.showBadge = false,
    this.recommended = false,
  });

  final ConsultationResult result;
  final bool showBadge;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final MobileProduct product = MobileProductCatalog.productBySkuId(
      result.skuId,
    );
    final MobileSkuOption? sku = MobileProductCatalog.skuById(result.skuId);
    final String color = sku?.color ?? 'Black';
    final String size = sku?.size ?? 'M';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: recommended ? 102 : 92,
          height: recommended ? 74 : 86,
          child: MobileProductVisual(
            product: product,
            colorOverride: sku == null ? null : Color(sku.swatchValue),
            compact: true,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showBadge) ...<Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    color: const Color(0xFF2D2D2D),
                    child: Text(
                      recommended ? '추천 제품' : '상담 제품',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ] else
                const Text(
                  '상담 제품',
                  style: TextStyle(fontSize: 10, color: Color(0xFF555555)),
                ),
              Text(
                result.productName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                _formatWon(product.price),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(color, style: const TextStyle(fontSize: 10, height: 1.25)),
              Text(size, style: const TextStyle(fontSize: 10, height: 1.25)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ResultField extends StatelessWidget {
  const _ResultField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _BulletPanel extends StatelessWidget {
  const _BulletPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('·', style: theme.textTheme.bodySmall),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error, {required String fallback}) {
  if (error is AppException) {
    return error.message;
  }
  return fallback;
}

String _resultTypeLabel(DecisionResultType resultType) {
  return switch (resultType) {
    DecisionResultType.exactProduct => '정확한 제품 확인',
    DecisionResultType.comparisonExperience => '비교 체험 제품',
    DecisionResultType.todayPurchase => '오늘 구매 가능 제품',
    DecisionResultType.additionalConsultation => '추가 상담',
  };
}

String _executionStatusMessage(ConsultationResult result) {
  return executionStatusMessage(
    status: result.executionStatus,
    note: result.executionNote,
  );
}

String _formatKoreanDateTime(DateTime date) {
  final String meridiem = date.hour < 12 ? '오전' : '오후';
  final int displayHour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final String minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}년 ${date.month}월 ${date.day}일 $meridiem $displayHour:$minute';
}

String _formatWon(int price) {
  final String digits = price.toString();
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return '₩ ${buffer.toString()}';
}
