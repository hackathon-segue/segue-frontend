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
            _selectedSize = null;
          });
        },
        onSizeSelected: (String size) => setState(() => _selectedSize = size),
        onAddToCart: _saveSelectedCartItem,
        isSavingCart: _isSavingCart,
        cartSaveError: _cartSaveError,
      ),
      _MobileScreen.cartAdded => _CartAddedScreen(
        cartItem: _lastSavedCartItem,
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
      _selectedSize = null;
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
    final ThemeData theme = Theme.of(context);
    final Color selectedVisualColor = selectedColor == null
        ? Color(product.visualValue)
        : Color(product.optionForColor(selectedColor!).swatchValue);

    return MobileScreenScaffold(
      title: '제품 상세 화면',
      showBackButton: true,
      onBack: onBack,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: MobileProductVisual(
                  product: product,
                  colorOverride: selectedVisualColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  for (final String color in product.colors) ...<Widget>[
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: MobileProductVisual(
                          product: product,
                          colorOverride: Color(
                            product.optionForColor(color).swatchValue,
                          ),
                          compact: true,
                        ),
                      ),
                    ),
                    if (color != product.colors.last)
                      const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(product.name, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(product.collection, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              Text('컬러 선택', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final String color in product.colors)
                    ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(
                          product.optionForColor(color).swatchValue,
                        ),
                      ),
                      label: Text(color),
                      selected: selectedColor == color,
                      onSelected: (_) => onColorSelected(color),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('사이즈 선택', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final String size in product.sizes)
                    ChoiceChip(
                      label: Text(size),
                      selected: selectedSize == size,
                      onSelected: (_) => onSizeSelected(size),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProductInfoCard(product: product),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('구매 안내', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '장바구니에 저장된 제품과 컬러 정보는 매장 상담 시 Client Advisor가 확인하며 예약 또는 구매 완료가 아닙니다.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (cartSaveError != null) ...<Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            cartSaveError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              FilledButton(
                onPressed: selectedSku == null || isSavingCart
                    ? null
                    : onAddToCart,
                child: Text(isSavingCart ? '저장 중' : '장바구니 담기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({required this.product});

  final MobileProduct product;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('소재 및 상세 정보', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: '소재', value: product.material),
            _InfoRow(label: '사이즈', value: product.dimensions),
            _InfoRow(label: '원산지', value: product.origin),
            _InfoRow(label: '시즌', value: product.season),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartAddedScreen extends StatelessWidget {
  const _CartAddedScreen({
    required this.cartItem,
    required this.onBack,
    required this.onOpenCart,
    required this.onContinueShopping,
  });

  final CartItem? cartItem;
  final VoidCallback onBack;
  final VoidCallback onOpenCart;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return MobileScreenScaffold(
      title: '장바구니 추가 완료',
      showBackButton: true,
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Text(
            '장바구니에 추가되었습니다',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '선택한 제품이 안전하게 저장되었어요',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (cartItem == null)
            const AppStateView.empty(title: '저장된 항목이 없습니다')
          else
            _SavedCartItemCard(cartItem: cartItem!),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onOpenCart,
              child: const Text('장바구니 보기'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onContinueShopping,
              child: const Text('계속 쇼핑하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCartItemCard extends StatelessWidget {
  const _SavedCartItemCard({required this.cartItem});

  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MobileProduct product = MobileProductCatalog.productById(
      cartItem.productId,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('저장된 항목', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 132,
                  height: 92,
                  child: MobileProductVisual(product: product, compact: true),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        cartItem.productName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '선택 컬러 ${cartItem.color}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '선택 사이즈 ${cartItem.size}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('수량: 1개'),
                ),
              ),
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
    final ThemeData theme = Theme.of(context);

    return MobileScreenScaffold(
      title: '앱 장바구니 목록',
      currentTab: CustomerMobileTab.cart,
      onTabSelected: onTabSelected,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Text('장바구니', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('최근 담은 순서', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const AppStateView.loading(title: '장바구니를 불러오는 중입니다')
          else if (errorMessage != null)
            AppStateView.error(
              title: '장바구니를 불러오지 못했습니다',
              message: errorMessage,
              onAction: onRetry,
            )
          else if (cartItems.isEmpty)
            const AppStateView.empty(
              title: '장바구니가 비어 있습니다',
              message: '마음에 드는 제품을 담아두면 매장 상담 시 함께 확인할 수 있습니다.',
            )
          else
            for (final CartItem cartItem in cartItems) ...<Widget>[
              _CartListItemCard(cartItem: cartItem),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '저장한 제품은 매장 상담 시 Client Advisor가 함께 확인합니다.',
            style: theme.textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onBackToProducts,
              child: const Text('이전 화면으로'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartListItemCard extends StatelessWidget {
  const _CartListItemCard({required this.cartItem});

  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MobileProduct product = MobileProductCatalog.productById(
      cartItem.productId,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 132,
              height: 92,
              child: MobileProductVisual(product: product, compact: true),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    cartItem.productName,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${cartItem.color} · ${cartItem.size}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _formatCartDate(cartItem.savedAt),
                    style: theme.textTheme.bodySmall,
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
    final ThemeData theme = Theme.of(context);

    return MobileScreenScaffold(
      title: '앱 상담 결과 확인',
      currentTab: CustomerMobileTab.results,
      onTabSelected: onTabSelected,
      body: Builder(
        builder: (BuildContext context) {
          if (isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: AppStateView.loading(title: '상담 결과를 불러오는 중입니다'),
              ),
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
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: AppStateView.empty(
                  title: '상담 결과가 없습니다',
                  message: '매장 상담 후 저장된 결과가 이곳에 표시됩니다.',
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              Text('상담 결과', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final ConsultationResult result in results) ...<Widget>[
                _ConsultationResultSection(
                  result: result,
                  onOnlinePurchase: () => onOnlinePurchase(result),
                  onStoreVisit: () => onStoreVisit(result),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onBackToHome,
                  child: const Text('이전 화면으로 돌아가기'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConsultationResultSection extends StatelessWidget {
  const _ConsultationResultSection({
    required this.result,
    required this.onOnlinePurchase,
    required this.onStoreVisit,
  });

  final ConsultationResult result;
  final VoidCallback onOnlinePurchase;
  final VoidCallback onStoreVisit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ConsultationProductRow(result: result),
                const SizedBox(height: AppSpacing.md),
                _ResultField(label: '핵심 조건', value: result.coreConditions),
                _ResultField(
                  label: '결과 유형',
                  value: _resultTypeLabel(result.resultType),
                ),
                _ResultField(label: '추천 경로', value: result.recommendedPath),
                _ResultField(
                  label: '처리 상태',
                  value: _executionStatusMessage(result),
                ),
                _ResultField(
                  label: '처리 갱신',
                  value: _formatKoreanDateTime(result.executionUpdatedAt),
                ),
                _ResultField(
                  label: '상담 시각',
                  value: _formatKoreanDateTime(result.consultedAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('다음 행동 안내', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _nextActionMessage(result),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: onOnlinePurchase,
            child: const Text('온라인 구매하기'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: onStoreVisit,
            child: const Text('매장 재방문 안내 보기'),
          ),
        ),
      ],
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
    final ThemeData theme = Theme.of(context);

    if (currentResult == null) {
      return _MissingConsultationResultScreen(
        title: '온라인 구매 화면',
        onBack: onBack,
      );
    }

    return MobileScreenScaffold(
      title: '온라인 구매 화면',
      showBackButton: true,
      onBack: onBack,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Text('온라인 구매 안내', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _ConsultationProductCard(result: currentResult),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            title: '온라인 구매 가능 여부',
            children: <Widget>[
              Text(
                '현재 온라인 스토어에서 구매 가능 여부를 확인할 수 있는 제품입니다.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('재고 확인 기준 · 상담 결과', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _InfoCard(
            title: '다음 단계 안내',
            children: <Widget>[
              _InstructionLine(number: 1, text: '아래 버튼을 눌러 온라인 스토어로 이동하세요.'),
              _InstructionLine(number: 2, text: '원하는 컬러와 수량을 선택한 뒤 구매를 진행하세요.'),
              _InstructionLine(
                number: 3,
                text: '구매 완료 후 상담 결과 화면에서 진행 상태를 확인할 수 있습니다.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            title: '상담 Client Advisor 안내',
            children: <Widget>[
              _StatusBar(result: currentResult),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '궁금한 점은 매장 재방문 또는 고객센터를 통해 확인하실 수 있습니다.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('온라인 스토어 연결은 데모 범위에서 안내만 제공합니다.'),
                  ),
                );
              },
              child: const Text('온라인 스토어에서 구매하기'),
            ),
          ),
        ],
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

class _ConsultationProductCard extends StatelessWidget {
  const _ConsultationProductCard({required this.result});

  final ConsultationResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _ConsultationProductRow(result: result, showSku: true),
      ),
    );
  }
}

class _ConsultationProductRow extends StatelessWidget {
  const _ConsultationProductRow({required this.result, this.showSku = false});

  final ConsultationResult result;
  final bool showSku;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MobileProduct product = MobileProductCatalog.productBySkuId(
      result.skuId,
    );
    final MobileSkuOption? sku = MobileProductCatalog.skuById(result.skuId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 132,
          height: 92,
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
              Text('상담 제품', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                result.productName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sku != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${sku.color} · ${sku.size}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (showSku) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text('SKU ${result.skuId}', style: theme.textTheme.bodySmall),
              ],
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

class _InstructionLine extends StatelessWidget {
  const _InstructionLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 20,
            child: Text('$number', style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.result});

  final ConsultationResult result;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Icon(executionStatusIcon(result.executionStatus), size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _executionStatusMessage(result),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '처리 갱신 ${_formatKoreanDateTime(result.executionUpdatedAt)}',
                    style: theme.textTheme.bodySmall,
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

String _nextActionMessage(ConsultationResult result) {
  final String statusText = _executionStatusMessage(result);
  final String actionText = switch (result.resultType) {
    DecisionResultType.exactProduct =>
      '상담에서 확인된 제품을 온라인으로 확인하거나 가까운 매장 재방문을 준비할 수 있습니다.',
    DecisionResultType.comparisonExperience =>
      '비교 체험 제품을 확인한 뒤 매장에서 직접 비교해 볼 수 있습니다.',
    DecisionResultType.todayPurchase =>
      '오늘 구매 경로를 확인한 제품입니다. 온라인 안내와 매장 안내를 함께 확인해 주세요.',
    DecisionResultType.additionalConsultation =>
      '조건을 조금 더 확인한 뒤 Client Advisor와 추가 상담을 이어갈 수 있습니다.',
  };
  return '$actionText $statusText';
}

String _formatKoreanDateTime(DateTime date) {
  final String meridiem = date.hour < 12 ? '오전' : '오후';
  final int displayHour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final String minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}년 ${date.month}월 ${date.day}일 $meridiem $displayHour:$minute';
}

String _formatCartDate(DateTime date) {
  final String year = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '$year. $month. $day 추가';
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
