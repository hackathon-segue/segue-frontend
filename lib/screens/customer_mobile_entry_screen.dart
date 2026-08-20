import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../repositories/repositories.dart';
import '../utils/app_config.dart';
import '../utils/app_design_tokens.dart';
import '../utils/execution_status_display.dart';
import '../utils/product_option_display.dart';
import '../widgets/app_state_view.dart';
import '../widgets/mobile_product_visual.dart';
import '../widgets/mobile_screen_scaffold.dart';
import '../widgets/segue_product_image.dart';

enum _MobileScreen {
  start,
  login,
  signup,
  account,
  profileEdit,
  passwordEdit,
  menu,
  segueIntro,
  products,
  detail,
  cartAdded,
  cart,
  results,
  onlinePurchase,
  storeVisit,
}

abstract final class _McmImageAssets {
  static const String startLxxviLogo = 'assets/icons/start_mcm_lxxvi_logo.png';
  static const String startProfileIcon = 'assets/icons/start_profile_icon.png';
  static const String menuMcmLogo = 'assets/icons/menu_mcm_logo.png';
  static const String menuFooterShoppingBagIcon =
      'assets/icons/menu_footer_shopping_bag_icon.png';
  static const String menuFooterSegueHistoryIcon =
      'assets/icons/menu_footer_segue_history_icon.png';
  static const String menuTileArrowIcon =
      'assets/icons/menu_tile_arrow_icon.png';
  static const String productCategorySelectedArrowIcon =
      'assets/icons/product_category_selected_arrow_icon.png';
  static const String productTileBagIcon =
      'assets/icons/product_tile_bag_icon.png';
  static const String productTileBagAddedIcon =
      'assets/icons/product_tile_bag_added_icon.png';
  static const String startHero = 'assets/images/mcm/start_hero.png';
  static const String menuNewCollection =
      'assets/images/mcm/menu_new_collection.png';
  static const String menuBestSeller = 'assets/images/mcm/menu_best_seller.png';
  static const String menuOuterCollection =
      'assets/images/mcm/menu_outer_collection.png';
  static const String menuOuterCollab =
      'assets/images/mcm/menu_outer_collab.png';
  static const String menuPina = 'assets/images/mcm/menu_pina.png';
  static const String menuArenEastWest =
      'assets/images/mcm/menu_aren_east_west.png';
  static const String categoryNewBags =
      'assets/images/mcm/category_new_bags.png';
  static const String categoryNewProducts =
      'assets/images/mcm/category_new_products.png';
  static const String categoryWomenNewProducts =
      'assets/images/mcm/category_women_new_products.png';
  static const String categoryMenNewProducts =
      'assets/images/mcm/category_men_new_products.png';
  static const String categoryAutumnWinter2026 =
      'assets/images/mcm/category_autumn_winter_2026.png';
  static const String categoryTote = 'assets/images/mcm/category_tote.png';
  static const String categoryShoulder =
      'assets/images/mcm/category_shoulder.png';
  static const String categoryBackpack =
      'assets/images/mcm/category_backpack.png';
  static const String categoryTopHandle =
      'assets/images/mcm/category_top_handle.png';
  static const String segueIntroStoreHero =
      'assets/images/mcm/segue_intro_store_hero.png';
  static const String segueIntroAdvisor =
      'assets/images/mcm/segue_intro_advisor.png';
  static const String segueIntroLastIntentCard =
      'assets/images/mcm/segue_intro_last_intent_card.png';
  static const String segueIntroCompletion =
      'assets/images/mcm/segue_intro_completion.png';
  static const String wordmarkBlack =
      'assets/images/mcm/mcm_wordmark_black.png';

  static String categoryHeroFor(String? category) {
    return switch (category ?? '가방') {
      _ProductCategory.bagNewProducts => categoryNewBags,
      _ProductCategory.newProducts => categoryNewProducts,
      _ProductCategory.womenNewProducts => categoryWomenNewProducts,
      _ProductCategory.menNewProducts => categoryMenNewProducts,
      _ProductCategory.autumnWinter2026 => categoryAutumnWinter2026,
      '토트백 & 쇼퍼백' => categoryTote,
      '숄더백 & 크로스백' => categoryShoulder,
      '백팩' => categoryBackpack,
      '탑 핸들백' => categoryTopHandle,
      _ => categoryNewBags,
    };
  }
}

abstract final class _ProductCategory {
  static const String bagNewProducts = '가방 신상품';
  static const String newProducts = '신상품 제품';
  static const String womenNewProducts = '여성 신상품';
  static const String menNewProducts = '남성 신상품';
  static const String autumnWinter2026 = 'Autumn Winter 2026';
}

bool _isNewProductCategory(String? category) {
  return category == _ProductCategory.newProducts ||
      category == _ProductCategory.womenNewProducts ||
      category == _ProductCategory.menNewProducts ||
      category == _ProductCategory.autumnWinter2026;
}

bool _isNewProductSubcategory(String category) {
  return category == _ProductCategory.womenNewProducts ||
      category == _ProductCategory.menNewProducts ||
      category == _ProductCategory.autumnWinter2026;
}

typedef _CustomerLoginCallback =
    Future<void> Function({required String email, required String password});

class CustomerMobileEntryScreen extends StatefulWidget {
  const CustomerMobileEntryScreen({super.key});

  @override
  State<CustomerMobileEntryScreen> createState() =>
      _CustomerMobileEntryScreenState();
}

class _CustomerMobileEntryScreenState extends State<CustomerMobileEntryScreen> {
  _MobileScreen _screen = _MobileScreen.start;
  _MobileScreen _menuReturnScreen = _MobileScreen.start;
  _MobileScreen _accountReturnScreen = _MobileScreen.start;
  MobileProduct _selectedProduct = MobileProductCatalog.products[2];
  final List<MobileProduct> _mobileProducts = List<MobileProduct>.of(
    AppConfig.useMockData ? MobileProductCatalog.products : <MobileProduct>[],
  );
  String? _selectedCategory;
  String? _expandedMenuSection;
  String? _selectedColor;
  String? _selectedSize;
  CartItem? _lastSavedCartItem;
  final List<CartItem> _cartItems = <CartItem>[];
  bool _isSavingCart = false;
  bool _isLoadingProducts = false;
  bool _hasLoadedProducts = false;
  bool _hasQueuedInitialProductLoad = false;
  bool _isLoadingCart = false;
  String? _cartSaveError;
  String? _productsError;
  String? _cartError;
  bool _isLoggedIn = false;
  int _customerId = AppConfig.defaultCustomerId;
  String _accountName = '아무개';
  String _accountEmail = '1234@1234.com';
  String _accountPhone = '010-1234-1234';
  final List<ConsultationResult> _consultationResults = <ConsultationResult>[];
  ConsultationResult? _selectedConsultationResult;
  bool _isLoadingResults = false;
  String? _resultsError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasQueuedInitialProductLoad) {
      return;
    }
    _hasQueuedInitialProductLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadMobileProducts());
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      _MobileScreen.start => _StartScreen(
        onOpenMenu: _openMenu,
        onOpenResults: _openAccount,
      ),
      _MobileScreen.login => _LoginScreen(
        onClose: _openStart,
        onLogin: _loginCustomer,
        onSignup: _openSignup,
      ),
      _MobileScreen.signup => _SignupScreen(
        onClose: _openStart,
        onSignup: _completeLogin,
        onLogin: _openLogin,
      ),
      _MobileScreen.account => _AccountScreen(
        isLoggedIn: _isLoggedIn,
        name: _accountName,
        email: _accountEmail,
        phone: _accountPhone,
        onClose: _closeAccount,
        onOpenLogin: _openLogin,
        onEditProfile: _openProfileEdit,
        onOpenCart: _openCart,
        onOpenResults: () {
          _openResults();
        },
      ),
      _MobileScreen.profileEdit => _ProfileEditScreen(
        name: _accountName,
        email: _accountEmail,
        phone: _accountPhone,
        onBack: _openAccount,
        onSave: _saveProfile,
        onPasswordChange: _openPasswordEdit,
        onLogin: _openLogin,
      ),
      _MobileScreen.passwordEdit => _PasswordEditScreen(
        name: _accountName,
        email: _accountEmail,
        phone: _accountPhone,
        onBack: _openProfileEdit,
        onSave: _openAccount,
        onLogin: _openLogin,
      ),
      _MobileScreen.menu => _MenuScreen(
        isLoggedIn: _isLoggedIn,
        expandedSection: _expandedMenuSection,
        onClose: _closeMenu,
        onToggleSection: _toggleMenuSection,
        onOpenSegueIntro: _openSegueIntro,
        onOpenProducts: _openProductCategory,
        onOpenAllProducts: _openAllProducts,
        onOpenLogin: _openLogin,
        onOpenAccount: _openAccount,
        onOpenCart: _openCart,
        onOpenResults: () {
          _openResults();
        },
      ),
      _MobileScreen.segueIntro => _SegueIntroScreen(
        onOpenMenu: _openMenu,
        onOpenAccount: _openAccount,
        onOpenResults: () {
          _openResults();
        },
      ),
      _MobileScreen.products => _ProductListScreen(
        products: _filteredProducts,
        selectedCategory: _selectedCategory,
        cartItems: _cartItems,
        cartSkuIds: _cartItems.map((CartItem item) => item.skuId).toSet(),
        isSavingCart: _isSavingCart,
        isLoading: _isLoadingProducts,
        errorMessage: _productsError,
        onRetry: () => _loadMobileProducts(force: true),
        onCategorySelected: (String? category) {
          if (category == null) {
            _openAllProducts();
            return;
          }
          _openProductCategory(category);
        },
        onProductSelected: _openDetail,
        onQuickAddToCart: _saveProductCartItem,
        onOpenMenu: _openMenu,
        onOpenResults: _openAccount,
      ),
      _MobileScreen.detail => Builder(
        builder: (BuildContext context) {
          final MobileSkuOption? selectedSku = _selectedProduct.skuFor(
            color: _selectedColor,
            size: _selectedSize,
          );
          final bool selectedSkuInCart =
              selectedSku != null &&
              _cartItems.any((CartItem item) => item.skuId == selectedSku.skuId);

          return _ProductDetailScreen(
            product: _selectedProduct,
            selectedColor: _selectedColor,
            selectedSize: _selectedSize,
            selectedSku: selectedSku,
            selectedSkuInCart: selectedSkuInCart,
            onBack: _returnToProducts,
            onColorSelected: (String color) {
              setState(() {
                final MobileSkuOption? firstOption = _selectedProduct
                    .firstOptionForColor(color);
                _selectedColor = color;
                _selectedSize = firstOption?.size;
              });
            },
            onSizeSelected: (String size) {
              if (_selectedProduct.skuFor(color: _selectedColor, size: size) ==
                  null) {
                return;
              }
              setState(() => _selectedSize = size);
            },
            onAddToCart: _saveSelectedCartItem,
            isSavingCart: _isSavingCart,
            cartSaveError: _cartSaveError,
            onOpenAccount: _openAccount,
            onOpenSegueIntro: _openSegueIntro,
          );
        },
      ),
      _MobileScreen.cartAdded => _CartAddedSlideIn(
        child: _CartAddedScreen(
          cartItem: _lastSavedCartItem,
          cartItems: _cartItems,
          onBack: _openDetailFromCartAdded,
          onOpenCart: _openCart,
          onContinueShopping: _returnToProducts,
          onOpenAccount: _openAccount,
          onOpenSegueIntro: _openSegueIntro,
        ),
      ),
      _MobileScreen.cart => _CartListScreen(
        cartItems: _cartItems,
        isLoading: _isLoadingCart,
        errorMessage: _cartError,
        isLoggedIn: _isLoggedIn,
        onRetry: () => _loadCartItems(force: true),
        onBackToProducts: _returnToProducts,
        onOpenMenu: _openMenu,
        onOpenAccount: _openAccount,
        onOpenLogin: _openLogin,
      ),
      _MobileScreen.results => _ConsultationResultsScreen(
        results: _consultationResults,
        isLoading: _isLoadingResults,
        errorMessage: _resultsError,
        onRetry: () => _loadConsultationResults(force: true),
        onOnlinePurchase: _openOnlinePurchase,
        onStoreVisit: _openStoreVisit,
        onBackToHome: _openStart,
        onOpenMenu: _openMenu,
        onOpenAccount: _openAccount,
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
    final List<MobileProduct> products = _mobileProducts.where((
      MobileProduct product,
    ) {
      return _matchesProductCategory(product, category);
    }).toList();
    if (products.isEmpty && _isNewProductSubcategory(category)) {
      products.addAll(
        _mobileProducts.where(
          (MobileProduct product) =>
              _matchesProductCategory(product, _ProductCategory.bagNewProducts),
        ),
      );
    }
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
    final bool hasNewCollectionMetadata = _isNewProduct(product);
    final bool lacksNewCollectionMetadata = _lacksNewProductMetadata(product);

    return switch (category) {
      _ProductCategory.bagNewProducts =>
        hasNewCollectionMetadata ||
            (lacksNewCollectionMetadata && product.category != '지갑'),
      _ProductCategory.newProducts =>
        hasNewCollectionMetadata ||
            (lacksNewCollectionMetadata && product.category != '지갑'),
      _ProductCategory.womenNewProducts =>
        (hasNewCollectionMetadata && _looksLikeWomenNewProduct(product)) ||
            (lacksNewCollectionMetadata && product.category != '지갑'),
      _ProductCategory.menNewProducts =>
        (hasNewCollectionMetadata && _looksLikeMenNewProduct(product)) ||
            (lacksNewCollectionMetadata && product.category != '지갑'),
      _ProductCategory.autumnWinter2026 =>
        hasNewCollectionMetadata ||
            (lacksNewCollectionMetadata && product.category != '지갑'),
      '가방' => product.category != '지갑',
      '토트백 & 쇼퍼백' => product.name.contains('토트') || product.name.contains('쇼퍼'),
      '숄더백 & 크로스백' =>
        product.name.contains('숄더') ||
            product.name.contains('크로스') ||
            product.name.contains('Patricia'),
      '백팩' => product.category == '백팩',
      '탑 핸들백' =>
        product.category == '핸드백' ||
            product.category == '탑 핸들백' ||
            product.name.contains('탑 핸들') ||
            product.name.contains('Klara'),
      _ => product.category == category,
    };
  }

  bool _isNewProduct(MobileProduct product) {
    return product.season.contains('2026') ||
        product.collection.contains('신') ||
        product.category.contains('신상품');
  }

  bool _lacksNewProductMetadata(MobileProduct product) {
    return product.season.trim().isEmpty && product.collection.trim().isEmpty;
  }

  bool _looksLikeWomenNewProduct(MobileProduct product) {
    final String name = product.name.toLowerCase();
    return product.id.isEven ||
        name.contains('liz') ||
        name.contains('diamond') ||
        name.contains('mode') ||
        name.contains('stark') ||
        name.contains('쇼퍼') ||
        name.contains('숄더') ||
        name.contains('토트') ||
        name.contains('드로우스트링') ||
        name.contains('크로스');
  }

  bool _looksLikeMenNewProduct(MobileProduct product) {
    final String name = product.name.toLowerCase();
    return product.id.isOdd ||
        name.contains('aren') ||
        name.contains('ottomar') ||
        name.contains('fursten') ||
        name.contains('tracy') ||
        name.contains('백팩') ||
        name.contains('벨트') ||
        name.contains('위켄더') ||
        name.contains('호보');
  }

  bool _isAccountFlowScreen(_MobileScreen screen) {
    return screen == _MobileScreen.account ||
        screen == _MobileScreen.profileEdit ||
        screen == _MobileScreen.passwordEdit;
  }

  void _openStart() {
    setState(() => _screen = _MobileScreen.start);
  }

  void _openMenu() {
    setState(() {
      if (_screen != _MobileScreen.menu) {
        _menuReturnScreen = _screen;
      }
      _expandedMenuSection = null;
      _screen = _MobileScreen.menu;
    });
  }

  void _closeMenu() {
    setState(() => _screen = _menuReturnScreen);
  }

  void _openLogin() {
    setState(() => _screen = _MobileScreen.login);
  }

  void _openSignup() {
    setState(() => _screen = _MobileScreen.signup);
  }

  void _openAccount() {
    setState(() {
      if (!_isAccountFlowScreen(_screen)) {
        _accountReturnScreen = _screen == _MobileScreen.menu
            ? _menuReturnScreen
            : _screen;
      }
      _screen = _MobileScreen.account;
    });
  }

  void _closeAccount() {
    setState(() {
      _screen = _accountReturnScreen == _MobileScreen.menu
          ? _menuReturnScreen
          : _accountReturnScreen;
    });
  }

  void _openProfileEdit() {
    setState(() => _screen = _MobileScreen.profileEdit);
  }

  void _openPasswordEdit() {
    setState(() => _screen = _MobileScreen.passwordEdit);
  }

  void _saveProfile() {
    setState(() {
      _isLoggedIn = true;
      _screen = _MobileScreen.account;
    });
  }

  Future<void> _loginCustomer({
    required String email,
    required String password,
  }) async {
    final Customer customer = await RepositoryScope.of(
      context,
    ).loginCustomer(email: email, password: password);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoggedIn = true;
      _customerId = customer.id == 0
          ? AppConfig.defaultCustomerId
          : customer.id;
      _accountName = customer.name.trim().isEmpty
          ? _accountName
          : customer.name;
      _accountEmail = customer.email.trim().isEmpty
          ? email.trim()
          : customer.email;
      _accountPhone = customer.phoneNumber.trim().isEmpty
          ? _accountPhone
          : customer.phoneNumber;
      _cartItems.clear();
      _consultationResults.clear();
      _selectedConsultationResult = null;
      _cartError = null;
      _resultsError = null;
      _screen = _MobileScreen.start;
    });
  }

  void _completeLogin() {
    setState(() {
      _isLoggedIn = true;
      _customerId = AppConfig.defaultCustomerId;
      _screen = _MobileScreen.start;
    });
  }

  void _toggleMenuSection(String section) {
    setState(() {
      _expandedMenuSection = _expandedMenuSection == section ? null : section;
    });
  }

  void _openSegueIntro() {
    setState(() => _screen = _MobileScreen.segueIntro);
  }

  void _openAllProducts() {
    setState(() {
      _selectedCategory = null;
      _screen = _MobileScreen.products;
    });
    _loadMobileProducts();
  }

  void _openProductCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _screen = _MobileScreen.products;
    });
    _loadMobileProducts();
  }

  void _returnToProducts() {
    setState(() => _screen = _MobileScreen.products);
  }

  void _openDetail(MobileProduct product) {
    final MobileSkuOption? initialSku = product.firstAvailableOption;
    setState(() {
      _selectedProduct = product;
      _selectedColor = initialSku?.color;
      _selectedSize = initialSku?.size;
      _screen = _MobileScreen.detail;
    });
  }

  void _openCart() {
    if (!_isLoggedIn) {
      setState(() {
        _cartItems.clear();
        _cartError = null;
        _isLoadingCart = false;
        _screen = _MobileScreen.cart;
      });
      return;
    }

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
    if (!_isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() => _screen = _MobileScreen.results);
    if (_consultationResults.isEmpty && !_isLoadingResults) {
      await _loadConsultationResults();
    }
  }

  Future<void> _showLoginRequiredDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (BuildContext dialogContext) {
        return _LoginRequiredDialog(
          onSignup: () {
            Navigator.of(dialogContext).pop();
            _openLogin();
          },
          onLogin: () {
            Navigator.of(dialogContext).pop();
            _openLogin();
          },
        );
      },
    );
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

  Future<void> _loadMobileProducts({bool force = false}) async {
    if (_isLoadingProducts || (_hasLoadedProducts && !force)) {
      return;
    }

    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final List<MobileProduct> products = await RepositoryScope.of(
        context,
      ).fetchMobileProducts();
      if (!mounted) {
        return;
      }
      final List<MobileProduct> nextProducts =
          products.isEmpty && AppConfig.useMockData
          ? MobileProductCatalog.products
          : products;
      setState(() {
        _mobileProducts
          ..clear()
          ..addAll(nextProducts);
        _hasLoadedProducts = true;
        _isLoadingProducts = false;
      });
      _precacheProductImages(nextProducts);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (!AppConfig.useMockData) {
          _mobileProducts.clear();
        }
        _isLoadingProducts = false;
        _productsError = _errorMessage(
          error,
          fallback: '상품 정보를 불러오지 못했습니다. 다시 시도해 주세요.',
        );
      });
    }
  }

  void _precacheProductImages(List<MobileProduct> products) {
    final Set<String> resolvedUrls = <String>{};
    for (final MobileProduct product in products) {
      final String? resolvedUrl = SegueProductImage.resolveImageUrl(
        product.imageUrl,
      );
      if (resolvedUrl == null || !resolvedUrls.add(resolvedUrl)) {
        continue;
      }
      final ImageProvider<Object>? imageProvider =
          SegueProductImage.imageProviderFor(product.imageUrl);
      if (imageProvider == null) {
        continue;
      }
      unawaited(
        precacheImage(imageProvider, context).catchError((Object _) {}),
      );
      if (resolvedUrls.length >= 48) {
        return;
      }
    }
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
      ).fetchConsultationResults(_customerId);
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
      // 고객 본인의 쇼핑백이므로 동의 게이트가 없는 경로를 쓴다. CA 태블릿용
      // fetchCart 를 쓰면 동의 전 고객과 신규 가입 고객이 여기서 403 을 받는다.
      final List<CartItem> items = await RepositoryScope.of(
        context,
      ).fetchOwnCart(customerId: _customerId, storeId: AppConfig.defaultStoreId);
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
    if (selectedSku == null) {
      return;
    }
    await _saveProductCartItem(_selectedProduct, option: selectedSku);
  }

  Future<void> _saveProductCartItem(
    MobileProduct product, {
    MobileSkuOption? option,
  }) async {
    if (!_isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    final MobileSkuOption? selectedSku = option ?? product.firstAvailableOption;
    if (selectedSku == null || _isSavingCart) {
      return;
    }

    setState(() {
      _selectedProduct = product;
      _selectedColor = selectedSku.color;
      _selectedSize = selectedSku.size;
      _isSavingCart = true;
      _cartSaveError = null;
    });

    try {
      final CartItem cartItem = await RepositoryScope.of(context).saveCartItem(
        CartSaveRequest(
          customerId: _customerId,
          productId: product.id,
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
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _StartTransparentTopBar(
                    onOpenMenu: onOpenMenu,
                    onOpenAccount: onOpenResults,
                  ),
                ),
                const Positioned(
                  top: 115,
                  left: 0,
                  right: 0,
                  child: Center(child: _StartScreenLogo()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartTransparentTopBar extends StatelessWidget {
  const _StartTransparentTopBar({
    required this.onOpenMenu,
    required this.onOpenAccount,
  });

  final VoidCallback onOpenMenu;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: '메뉴 열기',
              onPressed: onOpenMenu,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 58.56,
                height: 48,
              ),
              icon: const _StartMenuIcon(),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: '내 계정',
              onPressed: onOpenAccount,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 58.56,
                height: 48,
              ),
              icon: const _StartProfileIcon(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({
    required this.onClose,
    required this.onLogin,
    required this.onSignup,
  });

  final VoidCallback onClose;
  final _CustomerLoginCallback onLogin;
  final VoidCallback onSignup;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginPressed() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showLoginMismatchDialog();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showLoginMismatchDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (BuildContext context) {
        return const _LoginMismatchDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: widget.onClose,
              leadingIcon: Icons.close,
              leadingIconWidget: const _MenuCloseIcon(),
              leadingTooltip: '로그인 닫기',
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(33, 20, 33, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      '로그인',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 13.74,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w700,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '회원으로 가입하시면 빠르고 편리하게 이용하실 수 있습니다.',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 11.908,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w400,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '*표시가 있는 모든 입력 항목은 필수입니다.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 10.076,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _LoginInputField(
                      controller: _emailController,
                      hintText: '이메일 주소*',
                      compactMcmStyle: true,
                    ),
                    const SizedBox(height: 28),
                    _LoginInputField(
                      controller: _passwordController,
                      hintText: '비밀번호*',
                      trailingText: '표시',
                      obscureText: true,
                      compactMcmStyle: true,
                    ),
                    const Spacer(),
                    _LoginPrimaryButton(
                      label: _isSubmitting ? '로그인 중' : '로그인',
                      onPressed: _handleLoginPressed,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: InkWell(
                        onTap: widget.onSignup,
                        child: const _LoginSignupLink('계정이 없으신가요? 회원가입하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequiredDialog extends StatelessWidget {
  const _LoginRequiredDialog({required this.onSignup, required this.onLogin});

  final VoidCallback onSignup;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: SizedBox(
            key: const ValueKey<String>('login-required-dialog-panel'),
            width: 302,
            height: 138,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: Material(
                color: Colors.white,
                shape: const RoundedRectangleBorder(),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: -1.27,
                      right: -4.08,
                      child: IconButton(
                        tooltip: '팝업 닫기',
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        icon: const _LoginRequiredCloseIcon(),
                      ),
                    ),
                    const Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Text(
                        '해당 기능은 로그인 이후에 가능합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w500,
                          height: 0.99925,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 19,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 90,
                            height: 32,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const RoundedRectangleBorder(),
                                textStyle: const TextStyle(
                                  color: Color(0xFF000000),
                                  fontFamily: 'Pretendard',
                                  fontSize: 13,
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.w500,
                                  height: 0.99925,
                                  letterSpacing: 0,
                                ),
                              ),
                              onPressed: onSignup,
                              child: const Text('회원가입'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 90,
                            height: 32,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const RoundedRectangleBorder(),
                                textStyle: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontFamily: 'Pretendard',
                                  fontSize: 13,
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.w500,
                                  height: 0.99925,
                                  letterSpacing: 0,
                                ),
                              ),
                              onPressed: onLogin,
                              child: const Text('로그인'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginRequiredCloseIcon extends StatelessWidget {
  const _LoginRequiredCloseIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10.25,
      height: 9.462,
      child: CustomPaint(painter: _LoginRequiredCloseIconPainter()),
    );
  }
}

class _LoginRequiredCloseIconPainter extends CustomPainter {
  const _LoginRequiredCloseIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt;

    canvas
      ..save()
      ..scale(size.width / 11, size.height / 11)
      ..drawLine(
        const Offset(0.802547, 0.530217),
        const Offset(10.2641, 9.99175),
        paint,
      )
      ..drawLine(
        const Offset(10.5222, 1.06055),
        const Offset(1.06055, 10.5222),
        paint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_LoginRequiredCloseIconPainter oldDelegate) {
    return false;
  }
}

class _AccountScreen extends StatelessWidget {
  const _AccountScreen({
    required this.isLoggedIn,
    required this.name,
    required this.email,
    required this.phone,
    required this.onClose,
    required this.onOpenLogin,
    required this.onEditProfile,
    required this.onOpenCart,
    required this.onOpenResults,
  });

  final bool isLoggedIn;
  final String name;
  final String email;
  final String phone;
  final VoidCallback onClose;
  final VoidCallback onOpenLogin;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onClose,
              leadingIcon: Icons.close,
              leadingIconWidget: const _MenuCloseIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                children: <Widget>[
                  const Text(
                    '내 계정',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Pretendard',
                      fontSize: 13.74,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w700,
                      height: 0.99925,
                      letterSpacing: 0,
                    ),
                  ),
                  if (isLoggedIn) ...<Widget>[
                    const SizedBox(height: 36),
                    const Text(
                      '주문 내역',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 16.489,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w700,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '이 계정에 대한 주문 기록이 없습니다.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 12.824,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 18.321 / 12.824,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 44),
                    const Center(child: _AccountSectionDivider()),
                    const SizedBox(height: 30),
                    const Text(
                      '계정 상세정보',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 16.489,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w700,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AccountInfoBlock(
                      label: '이름/이메일',
                      values: <String>[name, email],
                    ),
                    const SizedBox(height: 24),
                    const _AccountInfoBlock(
                      label: '비밀번호',
                      values: <String>['••••••••'],
                      valueFontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 24),
                    _AccountInfoBlock(label: '전화번호', values: <String>[phone]),
                    const SizedBox(height: 18),
                    _AccountProfileEditButton(
                      label: '프로필 편집',
                      onPressed: onEditProfile,
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: 26),
                    const Text(
                      '로그인을 먼저 진행해 주세요.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 12.824,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 18.321 / 12.824,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19.2, 0, 19.2, 22),
              child: Column(
                children: <Widget>[
                  if (!isLoggedIn)
                    _MenuFooterAccountRow(label: '로그인', onTap: onOpenLogin),
                  _MenuFooterRow(
                    label: '쇼핑백',
                    icon: Icons.shopping_bag_outlined,
                    textStyle: _MenuFooterRow.compactTextStyle,
                    trailingIcon: const _MenuFooterShoppingBagIcon(),
                    onTap: onOpenCart,
                  ),
                  _MenuFooterRow(
                    label: 'SEGUE 내역 확인',
                    icon: Icons.receipt_long_outlined,
                    labelWidget: const _SegueHistoryFooterLabel(),
                    trailingIcon: const _MenuFooterSegueHistoryIcon(),
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

class _SignupScreen extends StatelessWidget {
  const _SignupScreen({
    required this.onClose,
    required this.onSignup,
    required this.onLogin,
  });

  final VoidCallback onClose;
  final VoidCallback onSignup;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onClose,
              leadingIcon: Icons.close,
              leadingIconWidget: const _MenuCloseIcon(),
              leadingTooltip: '회원가입 닫기',
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(33, 20, 33, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      '회원가입',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 13.74,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w700,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '회원으로 가입하시면 빠르고 편리하게 이용하실 수 있습니다.',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 11.908,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w400,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '*표시가 있는 모든 입력 항목은 필수입니다.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 10.076,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const _LoginInputField(
                      hintText: '성명*',
                      compactMcmStyle: true,
                    ),
                    const SizedBox(height: 28),
                    const _LoginInputField(
                      hintText: '이메일 주소*',
                      compactMcmStyle: true,
                    ),
                    const SizedBox(height: 28),
                    const _LoginInputField(
                      hintText: '전화번호*',
                      compactMcmStyle: true,
                    ),
                    const SizedBox(height: 28),
                    const _LoginInputField(
                      hintText: '비밀번호*',
                      trailingText: '표시',
                      obscureText: true,
                      compactMcmStyle: true,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      '비밀번호는 8자 이상이어야 합니다.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 10.076,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    _LoginPrimaryButton(label: '회원가입', onPressed: onSignup),
                    const SizedBox(height: 18),
                    Center(
                      child: InkWell(
                        onTap: onLogin,
                        child: const _LoginSignupLink('이미 계정이 있으신가요? 로그인하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditScreen extends StatelessWidget {
  const _ProfileEditScreen({
    required this.name,
    required this.email,
    required this.phone,
    required this.onBack,
    required this.onSave,
    required this.onPasswordChange,
    required this.onLogin,
  });

  final String name;
  final String email;
  final String phone;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onPasswordChange;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onBack,
              leadingIcon: Icons.chevron_left,
              leadingIconWidget: const _McmBackIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(33, 20, 33, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      '내 프로필 편집',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 13.74,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w700,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '*표시가 있는 모든 입력 항목은 필수입니다.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 10.076,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _AccountFormField(label: '성명*', value: name),
                    const SizedBox(height: 24),
                    _AccountFormField(label: '이메일 주소*', value: email),
                    const SizedBox(height: 24),
                    _AccountFormField(label: '전화번호*', value: phone),
                    const SizedBox(height: 24),
                    const _AccountFormField(
                      label: '비밀번호*',
                      value: '12345678',
                      trailingText: '표시',
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    _AccountPasswordChangeLink(onTap: onPasswordChange),
                    const Spacer(),
                    _LoginPrimaryButton(label: '저장', onPressed: onSave),
                    const SizedBox(height: 18),
                    Center(
                      child: InkWell(
                        onTap: onLogin,
                        child: const _LoginSignupLink('이미 계정이 있으신가요? 로그인하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordEditScreen extends StatelessWidget {
  const _PasswordEditScreen({
    required this.name,
    required this.email,
    required this.phone,
    required this.onBack,
    required this.onSave,
    required this.onLogin,
  });

  final String name;
  final String email;
  final String phone;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onBack,
              leadingIcon: Icons.chevron_left,
              leadingIconWidget: const _McmBackIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(33, 20, 33, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      '내 프로필 편집',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 13.74,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w700,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '*표시가 있는 모든 입력 항목은 필수입니다.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 10.076,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _AccountFormField(label: '성명*', value: name),
                    const SizedBox(height: 24),
                    _AccountFormField(label: '이메일 주소*', value: email),
                    const SizedBox(height: 24),
                    _AccountFormField(label: '전화번호*', value: phone),
                    const SizedBox(height: 24),
                    const _AccountFormField(
                      label: '현재 비밀번호 입력*',
                      value: '12345678',
                      trailingText: '표시',
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    _AccountPasswordChangeLink(onTap: onBack),
                    const SizedBox(height: 24),
                    const _AccountFormField(
                      label: '변경할 비밀번호*',
                      value: '',
                      trailingText: '표시',
                      obscureText: true,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      '비밀번호는 8자 이상이어야 합니다.',
                      style: TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 10.076,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    _LoginPrimaryButton(label: '회원가입', onPressed: onSave),
                    const SizedBox(height: 18),
                    Center(
                      child: InkWell(
                        onTap: onLogin,
                        child: const _LoginSignupLink('이미 계정이 있으신가요? 로그인하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountFormField extends StatefulWidget {
  const _AccountFormField({
    required this.label,
    required this.value,
    this.trailingText,
    this.obscureText = false,
  });

  final String label;
  final String value;
  final String? trailingText;
  final bool obscureText;

  @override
  State<_AccountFormField> createState() => _AccountFormFieldState();
}

class _AccountFormFieldState extends State<_AccountFormField> {
  late bool _obscured = widget.obscureText;

  void _toggleObscured() {
    if (!widget.obscureText) {
      return;
    }
    setState(() => _obscured = !_obscured);
  }

  String get _displayValue {
    if (!widget.obscureText || !_obscured || widget.value.isEmpty) {
      return widget.value;
    }
    return List<String>.filled(widget.value.length, '•').join();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 324.275,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 0.916),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Color(0xFF6E707C),
                          fontFamily: 'Pretendard',
                          fontSize: 10.076,
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w500,
                          height: 0.99925,
                          letterSpacing: 0,
                        ),
                      ),
                      if (_displayValue.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          _displayValue,
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'Pretendard',
                            fontSize: 12.824,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            height: 0.99925,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailingText != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.obscureText ? _toggleObscured : null,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Transform.translate(
                        offset: const Offset(0, -3),
                        child: Text(
                          widget.trailingText!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF6E707C),
                            fontFamily: 'Pretendard',
                            fontSize: 10.076,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            height: 0.99925,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF6E707C),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountPasswordChangeLink extends StatelessWidget {
  const _AccountPasswordChangeLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 324.275,
        child: InkWell(
          onTap: onTap,
          child: const Text(
            '비밀번호 변경',
            style: TextStyle(
              color: Color(0xFF6E707C),
              fontFamily: 'Pretendard',
              fontSize: 10.076,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              height: 0.99925,
              letterSpacing: 0,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF6E707C),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountInfoBlock extends StatelessWidget {
  const _AccountInfoBlock({
    required this.label,
    required this.values,
    this.valueFontWeight = FontWeight.w500,
  });

  final String label;
  final List<String> values;
  final FontWeight valueFontWeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF000000),
            fontFamily: 'Pretendard',
            fontSize: 12.824,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w700,
            height: 18.321 / 12.824,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        for (final String value in values)
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF6E707C),
              fontFamily: 'Pretendard',
              fontSize: 12.824,
              fontStyle: FontStyle.normal,
              fontWeight: valueFontWeight,
              height: 18.321 / 12.824,
              letterSpacing: 0,
            ),
          ),
      ],
    );
  }
}

class _AccountSectionDivider extends StatelessWidget {
  const _AccountSectionDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 324.275,
      height: 0.916,
      child: ColoredBox(color: Color(0xFFEDEDED)),
    );
  }
}

class _AccountProfileEditButton extends StatelessWidget {
  const _AccountProfileEditButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 324.275,
        height: 40.305,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF222222),
            side: const BorderSide(color: Color(0xFF222222), width: 0.916),
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const RoundedRectangleBorder(),
            textStyle: const TextStyle(
              color: Color(0xFF222222),
              fontFamily: 'Pretendard',
              fontSize: 11.908,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w600,
              height: 0.99925,
              letterSpacing: 0,
            ),
          ),
          onPressed: onPressed,
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _LoginInputField extends StatefulWidget {
  const _LoginInputField({
    required this.hintText,
    this.controller,
    this.trailingText,
    this.obscureText = false,
    this.compactMcmStyle = false,
  });

  final String hintText;
  final TextEditingController? controller;
  final String? trailingText;
  final bool obscureText;
  final bool compactMcmStyle;

  @override
  State<_LoginInputField> createState() => _LoginInputFieldState();
}

class _LoginInputFieldState extends State<_LoginInputField> {
  late bool _obscured = widget.obscureText;

  void _toggleObscured() {
    if (!widget.obscureText) {
      return;
    }
    setState(() => _obscured = !_obscured);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle floatingLabelStyle = widget.compactMcmStyle
        ? const TextStyle(
            color: Color(0xFF6E707C),
            fontFamily: 'Pretendard',
            fontSize: 10.076,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w500,
            height: 0.99925,
            letterSpacing: 0,
          )
        : const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          );
    final TextStyle inputTextStyle = widget.compactMcmStyle
        ? const TextStyle(
            color: Color(0xFF000000),
            fontFamily: 'Pretendard',
            fontSize: 12.824,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w500,
            height: 0.99925,
            letterSpacing: 0,
          )
        : const TextStyle(fontSize: 13, height: 1.2);
    final TextStyle trailingStyle = widget.compactMcmStyle
        ? const TextStyle(
            color: Color(0xFF6E707C),
            fontFamily: 'Pretendard',
            fontSize: 9.16,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w500,
            height: 0.99925,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF6E707C),
          )
        : const TextStyle(
            color: Color(0xFF696969),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
    final BorderSide inputBorderSide = BorderSide(
      color: Colors.black,
      width: widget.compactMcmStyle ? 0.916 : 1,
    );

    final Widget field = SizedBox(
      width: widget.compactMcmStyle ? 324.275 : double.infinity,
      height: widget.compactMcmStyle ? 45 : 35,
      child: Stack(
        children: <Widget>[
          TextField(
            controller: widget.controller,
            obscureText: _obscured,
            cursorColor: Colors.black,
            style: inputTextStyle,
            decoration: InputDecoration(
              labelText: widget.hintText,
              labelStyle: floatingLabelStyle,
              floatingLabelStyle: floatingLabelStyle,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              isDense: true,
              contentPadding: EdgeInsets.only(
                right: widget.trailingText == null ? 0 : 44,
                bottom: 9,
              ),
              enabledBorder: UnderlineInputBorder(borderSide: inputBorderSide),
              focusedBorder: UnderlineInputBorder(borderSide: inputBorderSide),
            ),
          ),
          if (widget.trailingText != null)
            Positioned(
              right: 0,
              bottom: widget.compactMcmStyle ? 14 : 10,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.obscureText ? _toggleObscured : null,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    widget.trailingText!,
                    textAlign: TextAlign.right,
                    style: trailingStyle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return widget.compactMcmStyle ? Center(child: field) : field;
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  const _LoginPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 324.275,
        height: 40.305,
        child: Material(
          color: const Color(0xFF222222),
          shape: const RoundedRectangleBorder(),
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontFamily: 'Pretendard',
                  fontSize: 11.908,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w600,
                  height: 0.99925,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginSignupLink extends StatelessWidget {
  const _LoginSignupLink(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF000000),
        fontFamily: 'Pretendard',
        fontSize: 11.908,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w400,
        height: 0.99925,
        letterSpacing: 0,
        decoration: TextDecoration.underline,
        decorationColor: Color(0xFF000000),
      ),
    );
  }
}

class _StartScreenLogo extends StatelessWidget {
  const _StartScreenLogo();

  static const double _figmaWidth = 272.79;
  static const double _figmaHeight = 69.62;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MCM LXXVI 1976',
      image: true,
      child: SizedBox(
        key: const ValueKey<String>('customer-mobile-start-logo'),
        width: _figmaWidth,
        height: _figmaHeight,
        child: Opacity(
          opacity: 0.82,
          child: Image.asset(
            _McmImageAssets.startLxxviLogo,
            width: _figmaWidth,
            height: _figmaHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _StartMenuIcon extends StatelessWidget {
  const _StartMenuIcon();

  static const double width = 20.153;
  static const double height = 14.656;
  static const double strokeWidth = 1.83206;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _StartMenuIconPainter()),
    );
  }
}

class _StartMenuIconPainter extends CustomPainter {
  const _StartMenuIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = _StartMenuIcon.strokeWidth
      ..strokeCap = StrokeCap.butt;

    final double top = _StartMenuIcon.strokeWidth / 2;
    final double bottom = size.height - top;

    canvas.drawLine(Offset(0, top), Offset(size.width, top), paint);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), paint);
  }

  @override
  bool shouldRepaint(_StartMenuIconPainter oldDelegate) {
    return false;
  }
}

class _StartProfileIcon extends StatelessWidget {
  const _StartProfileIcon();

  static const double width = 21.985;
  static const double height = 22.535;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        _McmImageAssets.startProfileIcon,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _MenuScreen extends StatelessWidget {
  const _MenuScreen({
    required this.isLoggedIn,
    required this.expandedSection,
    required this.onClose,
    required this.onToggleSection,
    required this.onOpenSegueIntro,
    required this.onOpenProducts,
    required this.onOpenAllProducts,
    required this.onOpenLogin,
    required this.onOpenAccount,
    required this.onOpenCart,
    required this.onOpenResults,
  });

  final bool isLoggedIn;
  final String? expandedSection;
  final VoidCallback onClose;
  final ValueChanged<String> onToggleSection;
  final VoidCallback onOpenSegueIntro;
  final ValueChanged<String> onOpenProducts;
  final VoidCallback onOpenAllProducts;
  final VoidCallback onOpenLogin;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onClose,
              leadingIcon: Icons.close,
              leadingIconWidget: const _MenuCloseIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(19.2, 20, 19.2, 20),
                children: <Widget>[
                  _MenuPrimaryRow(
                    label: '신상품',
                    expanded: expandedSection == '신상품',
                    onTap: () => onToggleSection('신상품'),
                  ),
                  if (expandedSection == '신상품') ...<Widget>[
                    _MenuSubItem(
                      label: '여성 신상품',
                      onTap: () =>
                          onOpenProducts(_ProductCategory.womenNewProducts),
                    ),
                    _MenuSubItem(
                      label: '남성 신상품',
                      onTap: () =>
                          onOpenProducts(_ProductCategory.menNewProducts),
                    ),
                    _MenuSubItem(
                      label: 'AUTUMN WINTER 2026',
                      onTap: () =>
                          onOpenProducts(_ProductCategory.autumnWinter2026),
                    ),
                    const SizedBox(height: 14),
                    _EditorialTilePair(
                      leadingAssetPath: _McmImageAssets.menuNewCollection,
                      leadingLabel: '여성 신상품 둘러보기',
                      onLeadingTap: () =>
                          onOpenProducts(_ProductCategory.womenNewProducts),
                      trailingAssetPath: _McmImageAssets.menuBestSeller,
                      trailingLabel: '남성 신상품 둘러보기',
                      onTrailingTap: () =>
                          onOpenProducts(_ProductCategory.menNewProducts),
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
                      onTap: () =>
                          onOpenProducts(_ProductCategory.bagNewProducts),
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
                    const SizedBox(height: 14),
                    _EditorialTilePair(
                      leadingAssetPath: _McmImageAssets.menuPina,
                      leadingLabel: 'PINA 둘러보기',
                      onLeadingTap: () => onOpenProducts('숄더백 & 크로스백'),
                      trailingAssetPath: _McmImageAssets.menuArenEastWest,
                      trailingLabel: 'AREN EAST WEST 둘러보기',
                      onTrailingTap: () => onOpenProducts('탑 핸들백'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuPrimaryRow(
                    label: 'SEGUE 소개',
                    expanded: expandedSection == 'SEGUE 소개',
                    onTap: () => onToggleSection('SEGUE 소개'),
                  ),
                  if (expandedSection == 'SEGUE 소개') ...<Widget>[
                    _MenuSubItem(
                      label: 'SEGUE와 함께 이어나가는 여정',
                      onTap: onOpenSegueIntro,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (expandedSection == null) ...<Widget>[
                    const SizedBox(height: 34),
                    _EditorialTilePair(
                      leadingAssetPath: _McmImageAssets.menuOuterCollection,
                      leadingLabel: '2026 가을-겨울 컬렉션 둘러보기',
                      onLeadingTap: () =>
                          onOpenProducts(_ProductCategory.autumnWinter2026),
                      trailingAssetPath: _McmImageAssets.menuOuterCollab,
                      trailingLabel: 'MCM X DJ KHALED X WE THE BEST 둘러보기',
                      onTrailingTap: () =>
                          onOpenProducts(_ProductCategory.menNewProducts),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19.2, 0, 19.2, 22),
              child: Column(
                children: <Widget>[
                  _MenuFooterAccountRow(
                    label: isLoggedIn ? '내 계정' : '로그인',
                    onTap: isLoggedIn ? onOpenAccount : onOpenLogin,
                  ),
                  _MenuFooterRow(
                    label: '쇼핑백',
                    icon: Icons.shopping_bag_outlined,
                    textStyle: _MenuFooterRow.compactTextStyle,
                    trailingIcon: const _MenuFooterShoppingBagIcon(),
                    onTap: onOpenCart,
                  ),
                  _MenuFooterRow(
                    label: 'SEGUE 내역 확인',
                    icon: Icons.receipt_long_outlined,
                    labelWidget: const _SegueHistoryFooterLabel(),
                    trailingIcon: const _MenuFooterSegueHistoryIcon(),
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

class _SegueIntroScreen extends StatelessWidget {
  const _SegueIntroScreen({
    required this.onOpenMenu,
    required this.onOpenAccount,
    required this.onOpenResults,
  });

  final VoidCallback onOpenMenu;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenResults;

  @override
  Widget build(BuildContext context) {
    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onOpenMenu,
              leadingIconWidget: const _McmTopBarMenuIcon(),
              onProfilePressed: onOpenAccount,
              profileIconWidget: const _McmTopBarProfileIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
              edgeIconButtonWidth: 58.56,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const SizedBox(height: 28),
                  const Center(
                    child: _SegueIntroTitleText(
                      'SEGUE, 온라인에서 시작된 선택을 매장에서 이어갑니다.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SegueIntroImage(
                    assetPath: _McmImageAssets.segueIntroStoreHero,
                    width: 361.335,
                    height: 203.359,
                    alignment: Alignment.center,
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: _SegueIntroParagraphText(
                      '온라인에서 선택한 제품이 방문한 매장에 없더라도, 고객이 그 제품을 원한 이유까지 사라지는 것은 아닙니다. SEGUE는 고객의 구매 의도를 이해하고, 지금 가능한 가장 적합한 다음 경험으로 연결합니다.',
                    ),
                  ),
                  const SizedBox(height: 58),
                  const Center(
                    child: _SegueIntroTitleText(
                      '단순히 가장 비슷한 제품이 아닌 가장 적합한 다음 경험',
                    ),
                  ),
                  const SizedBox(height: 21),
                  const Center(
                    child: _SegueIntroParagraphText(
                      'SEGUE는 고객의 쇼핑백 내역과 매장 상담을 연결하고, Client Advisor와 함께 고객이 절대 놓치고 싶지 않은 조건을 이해합니다. 고객의 답변을 바탕으로 필수 조건과 구매 상황을 정리한 뒤, 검증된 제품·매장 정보를 비교해 지금 가장 적합한 다음 행동 하나를 제안합니다.',
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SegueIntroImage(
                    assetPath: _McmImageAssets.segueIntroAdvisor,
                    width: 362.962,
                    height: 204.275,
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: _SegueIntroParagraphText(
                      'SEGUE는 여러 유사 제품을 먼저 보여 주지 않습니다. 고객이 그 제품에서 끝까지 지키고 싶은 조건을 이해하는 것에서 시작합니다.\n\n정확한 제품 확인부터 비교 체험, 오늘 구매 가능한 제품, 추가 상담까지. 상담 결과는 Last Intent Card로 제공되며 고객용 앱에 저장되어, 온라인에서 시작된 선택이 매장과 상담 이후까지 자연스럽게 이어집니다.',
                      height: 144,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _SegueIntroImage(
                    assetPath: _McmImageAssets.segueIntroLastIntentCard,
                    width: 325.574,
                    height: 206.107,
                  ),
                  const SizedBox(height: 8),
                  const _SegueIntroCaption('제공되는 Last Intent Card 예시'),
                  const SizedBox(height: 88),
                  const Center(
                    child: _SegueIntroTitleText('선택이 이어질 때, 경험이 완성됩니다.'),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: _SegueIntroParagraphText(
                      '온라인의 선택에서 매장의 상담으로,\n그리고 다시 고객의 앱으로.',
                      height: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SegueIntroImage(
                    assetPath: _McmImageAssets.segueIntroCompletion,
                    width: 362.875,
                    height: 204.226,
                  ),
                  const SizedBox(height: 84),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17.4, 0, 16.5, 38),
                    child: _SegueIntroHistoryLink(onTap: onOpenResults),
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

class _SegueIntroTitleText extends StatelessWidget {
  const _SegueIntroTitleText(this.text);

  final String text;

  static const TextStyle _latinStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Montserrat',
    fontSize: 18.321,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    fontVariations: <FontVariation>[FontVariation('wght', 450)],
    height: 1.21809,
    letterSpacing: 0,
  );

  static const TextStyle _koreanStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 18.321,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 0.99925,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 43.053),
      child: SizedBox(
        width: 321.527,
        child: _McmMixedFontText(
          text,
          koreanStyle: _koreanStyle,
          latinStyle: _latinStyle,
        ),
      ),
    );
  }
}

class _SegueIntroParagraphText extends StatelessWidget {
  const _SegueIntroParagraphText(this.text, {this.height = 77.863});

  final String text;
  final double height;

  static const double _lineHeight = 18.321 / 12.824;

  static const TextStyle _latinStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Montserrat',
    fontSize: 12.824,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    fontVariations: <FontVariation>[FontVariation('wght', 450)],
    height: _lineHeight,
    letterSpacing: 0,
  );

  static const TextStyle _koreanStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 12.824,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: _lineHeight,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: SizedBox(
        width: 321.527,
        child: _McmMixedFontText(
          text,
          koreanStyle: _koreanStyle,
          latinStyle: _latinStyle,
        ),
      ),
    );
  }
}

class _SegueIntroCaption extends StatelessWidget {
  const _SegueIntroCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174.962,
      height: 14.656,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF6E707C),
          fontFamily: 'Pretendard',
          fontSize: 10.076,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
          height: 18.321 / 10.076,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SegueIntroImage extends StatelessWidget {
  const _SegueIntroImage({
    required this.assetPath,
    required this.width,
    required this.height,
    this.alignment = Alignment.center,
  });

  final String assetPath;
  final double width;
  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: height,
          maxHeight: height,
          child: ColoredBox(
            color: const Color(0xFFD3D3D3),
            child: SizedBox(
              width: width,
              height: height,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: alignment,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegueIntroHistoryLink extends StatelessWidget {
  const _SegueIntroHistoryLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
        ),
        child: const Row(
          children: <Widget>[
            Expanded(child: _SegueHistoryFooterLabel()),
            _MenuFooterSegueHistoryIcon(),
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

  static const double _mobileTextScale = 1.08;

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
          child: ColoredBox(
            color: backgroundColor,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(_mobileTextScale)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _McmTopBar extends StatelessWidget {
  const _McmTopBar({
    required this.onLeadingPressed,
    this.leadingIcon = Icons.menu,
    this.leadingIconWidget,
    this.leadingTooltip,
    this.onProfilePressed,
    this.profileIconWidget,
    this.logoAssetPath = _McmImageAssets.wordmarkBlack,
    this.logoWidth = 76,
    this.logoHeight = 22,
    this.logoFit = BoxFit.contain,
    this.edgeIconButtonWidth = 48,
  });

  final VoidCallback onLeadingPressed;
  final IconData leadingIcon;
  final Widget? leadingIconWidget;
  final String? leadingTooltip;
  final VoidCallback? onProfilePressed;
  final Widget? profileIconWidget;
  final String logoAssetPath;
  final double logoWidth;
  final double logoHeight;
  final BoxFit logoFit;
  final double edgeIconButtonWidth;

  @override
  Widget build(BuildContext context) {
    final bool isCloseButton = leadingIcon == Icons.close;
    final VoidCallback? effectiveLogoPressed = context
        .findAncestorStateOfType<_CustomerMobileEntryScreenState>()
        ?._openStart;
    final Widget logo = Image.asset(
      logoAssetPath,
      width: logoWidth,
      height: logoHeight,
      fit: logoFit,
      filterQuality: FilterQuality.medium,
    );

    return SizedBox(
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: leadingTooltip ?? (isCloseButton ? '메뉴 닫기' : '메뉴 열기'),
              onPressed: onLeadingPressed,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: edgeIconButtonWidth,
                height: 48,
              ),
              icon: leadingIconWidget ?? Icon(leadingIcon, size: 30),
            ),
          ),
          Semantics(
            label: 'MCM',
            image: true,
            button: effectiveLogoPressed != null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: effectiveLogoPressed,
              child: SizedBox(
                width: 96,
                height: 48,
                child: Center(child: logo),
              ),
            ),
          ),
          if (onProfilePressed != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: '내 계정',
                onPressed: onProfilePressed,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: edgeIconButtonWidth,
                  height: 48,
                ),
                icon:
                    profileIconWidget ??
                    const Icon(Icons.person_outline, size: 30),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegueResultTopBar extends StatelessWidget {
  const _SegueResultTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.mobileContentMaxWidth,
      height: 91.603,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[Color(0xFFF6F6F6), Color(0xFFF3F8F0)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 66,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: '상담 결과 닫기',
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 58.56,
                        height: 48,
                      ),
                      icon: const _MenuCloseIcon(),
                    ),
                  ),
                  const _SegueResultTopBarTitle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegueResultTopBarTitle extends StatelessWidget {
  const _SegueResultTopBarTitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'SEGUE',
            style: TextStyle(
              color: Color(0xFF000000),
              fontFamily: 'Montserrat',
              fontSize: 13.74,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w700,
              height: 16.737 / 13.74,
              letterSpacing: 0,
            ),
          ),
          TextSpan(
            text: ' 결과',
            style: TextStyle(
              color: Color(0xFF000000),
              fontFamily: 'Pretendard',
              fontSize: 13.74,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w700,
              height: 0.99925,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _McmTopBarMenuIcon extends StatelessWidget {
  const _McmTopBarMenuIcon();

  static const double width = 20.153;
  static const double height = 14.656;
  static const double strokeWidth = 1.83206;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _McmTopBarMenuIconPainter()),
    );
  }
}

class _McmTopBarMenuIconPainter extends CustomPainter {
  const _McmTopBarMenuIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = _McmTopBarMenuIcon.strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      const Offset(0, _McmTopBarMenuIcon.strokeWidth / 2),
      Offset(size.width, _McmTopBarMenuIcon.strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height - _McmTopBarMenuIcon.strokeWidth / 2),
      Offset(size.width, size.height - _McmTopBarMenuIcon.strokeWidth / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_McmTopBarMenuIconPainter oldDelegate) {
    return false;
  }
}

class _McmTopBarProfileIcon extends StatelessWidget {
  const _McmTopBarProfileIcon();

  static const double width = 21.985;
  static const double height = 22.535;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _McmTopBarProfileIconPainter()),
    );
  }
}

class _McmTopBarProfileIconPainter extends CustomPainter {
  const _McmTopBarProfileIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path outerHead = Path()
      ..moveTo(10.0152, 0.0407543)
      ..cubicTo(12.7218, -0.31024, 15.1978, 1.64451, 15.5579, 4.41711)
      ..cubicTo(15.9181, 7.18971, 14.0273, 9.74038, 11.3249, 10.1275)
      ..cubicTo(8.5971, 10.5184, 6.08104, 8.55838, 5.71738, 5.75998)
      ..cubicTo(5.35372, 2.96166, 7.28244, 0.395, 10.0152, 0.0407543)
      ..close();
    final Path innerHead = Path()
      ..moveTo(10.17, 2.22146)
      ..cubicTo(11.7163, 1.95625, 13.179, 3.02784, 13.4359, 4.61361)
      ..cubicTo(13.6922, 6.19938, 12.6444, 7.69748, 11.0974, 7.95785)
      ..cubicTo(9.55313, 8.21767, 8.09584, 7.14662, 7.83957, 5.56423)
      ..cubicTo(7.58397, 3.98189, 8.62643, 2.48609, 10.17, 2.22146)
      ..close();
    final Path body = Path()
      ..moveTo(10.2775, 10.9455)
      ..cubicTo(14.1153, 10.5766, 17.9762, 12.7164, 20.0901, 16.0631)
      ..cubicTo(21.4382, 18.1969, 21.8007, 20.0231, 21.9847, 22.5304)
      ..lineTo(19.9503, 22.5354)
      ..cubicTo(19.9664, 18.0098, 16.9534, 14.1286, 12.8142, 13.2281)
      ..cubicTo(12.4377, 13.1462, 12.0738, 13.0831, 11.6937, 13.0267)
      ..cubicTo(11.5603, 13.017, 11.4261, 13.0111, 11.2919, 13.0091)
      ..cubicTo(6.13553, 12.9121, 2.09726, 17.0845, 2.01225, 22.529)
      ..lineTo(0, 22.534)
      ..cubicTo(0.351042, 16.2246, 4.191, 11.4546, 10.2775, 10.9455)
      ..close();

    canvas.save();
    canvas.scale(size.width / 21.9847, size.height / 22.5354);
    final Paint blackPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    final Paint whitePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerHead, blackPaint);
    canvas.drawPath(innerHead, whitePaint);
    canvas.drawPath(body, blackPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_McmTopBarProfileIconPainter oldDelegate) {
    return false;
  }
}

class _LoginMismatchDialog extends StatelessWidget {
  const _LoginMismatchDialog();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.white,
          shape: const RoundedRectangleBorder(),
          child: SizedBox(
            key: const ValueKey<String>('login-mismatch-dialog-panel'),
            width: 302,
            height: 84,
            child: Stack(
              children: <Widget>[
                const Positioned.fill(
                  child: Center(
                    child: Text(
                      '이메일 또는 비밀번호가 일치하지 않습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 1,
                  right: 1,
                  child: IconButton(
                    tooltip: '로그인 오류 닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const SizedBox(
                      width: 10.25,
                      height: 9.462,
                      child: _LoginRequiredCloseIcon(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCloseIcon extends StatelessWidget {
  const _MenuCloseIcon();

  static const double width = 14.885;
  static const double height = 13.74;
  static const double strokeWidth = 1.83206;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _MenuCloseIconPainter()),
    );
  }
}

class _MenuCloseIconPainter extends CustomPainter {
  const _MenuCloseIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = _MenuCloseIcon.strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_MenuCloseIconPainter oldDelegate) {
    return false;
  }
}

class _McmBackIcon extends StatelessWidget {
  const _McmBackIcon();

  static const double width = 9.16;
  static const double height = 15.962;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _McmBackIconPainter()),
    );
  }
}

class _McmBackIconPainter extends CustomPainter {
  const _McmBackIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(9.16031, 14.6579)
      ..lineTo(7.79793, 15.9624)
      ..lineTo(0.377446, 8.85257)
      ..cubicTo(0.257831, 8.73865, 0.162904, 8.60317, 0.0981264, 8.45395)
      ..cubicTo(0.033349, 8.30472, 0, 8.14469, 0, 7.98307)
      ..cubicTo(0, 7.82144, 0.033349, 7.66141, 0.0981263, 7.51219)
      ..cubicTo(0.162904, 7.36296, 0.257831, 7.22749, 0.377446, 7.11356)
      ..lineTo(7.79793, 0)
      ..lineTo(9.15902, 1.30456)
      ..lineTo(2.19437, 7.98122)
      ..lineTo(9.16031, 14.6579)
      ..close();

    canvas
      ..save()
      ..scale(size.width / 9.16031, size.height / 15.9624)
      ..drawPath(path, Paint()..color = const Color(0xFF000000))
      ..restore();
  }

  @override
  bool shouldRepaint(_McmBackIconPainter oldDelegate) {
    return false;
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
  const _CampaignMiniature({required this.assetPath, this.large = false});

  final String assetPath;
  final bool large;

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
        child: SizedBox(
          height: 13.74,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _MenuPrimaryLabel(label),
                ),
              ),
              _MenuArrowIcon(expanded: expanded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuPrimaryLabel extends StatelessWidget {
  const _MenuPrimaryLabel(this.label);

  static const TextStyle _koreanStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 13.74,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 0.99925,
  );

  static const TextStyle _segueStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Montserrat',
    fontSize: 13.74,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 1.21809,
  );

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label == 'SEGUE 소개') {
      return const Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(text: 'SEGUE', style: _segueStyle),
            TextSpan(text: ' 소개', style: _koreanStyle),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      label,
      style: _koreanStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MenuArrowIcon extends StatelessWidget {
  const _MenuArrowIcon({this.expanded = false});

  static const double width = 6.412;
  static const double height = 11.268;
  static const double hitSize = _MenuCloseIcon.height;
  static const double strokeWidth = 0.229008;

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget icon = Align(
      alignment: Alignment.centerRight,
      child: Transform.rotate(
        angle: expanded ? math.pi / 2 : 0,
        child: const SizedBox(
          width: _MenuArrowIcon.width,
          height: _MenuArrowIcon.height,
          child: CustomPaint(painter: _MenuArrowIconPainter()),
        ),
      ),
    );

    return SizedBox(width: hitSize, height: hitSize, child: icon);
  }
}

class _MenuArrowIconPainter extends CustomPainter {
  const _MenuArrowIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(1.20361, 11.668)
      ..lineTo(0.250488, 10.7471)
      ..lineTo(0.165527, 10.665)
      ..lineTo(0.250488, 10.583)
      ..lineTo(5.04248, 5.95312)
      ..lineTo(0.249512, 1.32129)
      ..lineTo(0.164551, 1.23926)
      ..lineTo(0.249512, 1.15723)
      ..lineTo(1.20361, 0.236328)
      ..lineTo(1.28271, 0.15918)
      ..lineTo(1.36279, 0.236328)
      ..lineTo(6.55713, 5.25488)
      ..cubicTo(6.65155, 5.34566, 6.72644, 5.45388, 6.77783, 5.57324)
      ..cubicTo(6.8293, 5.6928, 6.85596, 5.82143, 6.85596, 5.95117)
      ..cubicTo(6.85591, 6.08073, 6.8292, 6.20872, 6.77783, 6.32812)
      ..cubicTo(6.72637, 6.44766, 6.65173, 6.5566, 6.55713, 6.64746)
      ..lineTo(1.36279, 11.668)
      ..lineTo(1.28271, 11.7451)
      ..lineTo(1.20361, 11.668)
      ..close();
    final Rect bounds = path.getBounds();
    final double scaleX = size.width / bounds.width;
    final double scaleY = size.height / bounds.height;
    final double averageScale = (scaleX + scaleY) / 2;

    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.translate(-bounds.left, -bounds.top);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _MenuArrowIcon.strokeWidth / averageScale,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MenuArrowIconPainter oldDelegate) {
    return false;
  }
}

class _MenuSubItem extends StatelessWidget {
  const _MenuSubItem({required this.label, required this.onTap});

  static const TextStyle _koreanStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 13.74,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 0.99925,
  );

  static const TextStyle _latinStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Montserrat',
    fontSize: 13.74,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 1.21809,
  );

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 0, 8),
        child: _McmMixedFontText(
          label,
          koreanStyle: _koreanStyle,
          latinStyle: _latinStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _EditorialTilePair extends StatelessWidget {
  const _EditorialTilePair({
    required this.leadingAssetPath,
    required this.leadingLabel,
    required this.onLeadingTap,
    required this.trailingAssetPath,
    required this.trailingLabel,
    required this.onTrailingTap,
  });

  static const double gap = 2.207;

  final String leadingAssetPath;
  final String leadingLabel;
  final VoidCallback onLeadingTap;
  final String trailingAssetPath;
  final String trailingLabel;
  final VoidCallback onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tileWidth = math.max(0, (constraints.maxWidth - gap) / 2);

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _EditorialTile(
              assetPath: leadingAssetPath,
              label: leadingLabel,
              onTap: onLeadingTap,
              width: tileWidth,
            ),
            const SizedBox(width: gap),
            _EditorialTile(
              assetPath: trailingAssetPath,
              label: trailingLabel,
              onTap: onTrailingTap,
              width: tileWidth,
            ),
          ],
        );
      },
    );
  }
}

class _EditorialTile extends StatelessWidget {
  const _EditorialTile({
    required this.assetPath,
    required this.label,
    required this.onTap,
    required this.width,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final double imageHeight = width * 9 / 16;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ColoredBox(
              color: const Color(0xFFD3D3D3),
              child: SizedBox(
                width: width,
                height: imageHeight,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            const SizedBox(height: 7),
            _EditorialTileCaption(label, width: width),
          ],
        ),
      ),
    );
  }
}

class _EditorialTileCaption extends StatelessWidget {
  const _EditorialTileCaption(this.label, {required this.width});

  static const double _arrowSize = 16;
  static const double _gap = 5;

  static const TextStyle _latinStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Montserrat',
    fontSize: 10.992,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 1.21809,
  );

  static const TextStyle _koreanStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 10.992,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 0.99925,
  );

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: ClipRect(
        child: SizedBox(
          width: width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                _McmImageAssets.menuTileArrowIcon,
                width: _arrowSize,
                height: _arrowSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: _McmMixedFontText(
                  label,
                  koreanStyle: _koreanStyle,
                  latinStyle: _latinStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuFooterRow extends StatelessWidget {
  const _MenuFooterRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.labelWidget,
    this.textStyle,
    this.trailingIcon,
  });

  static const TextStyle compactTextStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 11.908,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 0.99925,
  );
  static const double _trailingSlotWidth = 22;

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? labelWidget;
  final TextStyle? textStyle;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 43,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF000000), width: 0.916),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child:
                  labelWidget ??
                  Text(
                    label,
                    style:
                        textStyle ??
                        const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
            ),
            SizedBox(
              width: _trailingSlotWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    trailingIcon ?? Icon(icon, color: Colors.black, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuFooterAccountRow extends StatelessWidget {
  const _MenuFooterAccountRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MenuFooterRow(
      label: label,
      icon: Icons.person_outline,
      textStyle: _MenuFooterRow.compactTextStyle,
      trailingIcon: const _MenuFooterAccountIcon(),
      onTap: onTap,
    );
  }
}

class _SegueHistoryFooterLabel extends StatelessWidget {
  const _SegueHistoryFooterLabel();

  static const TextStyle _segueStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Montserrat',
    fontSize: 11.908,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 1.21809,
  );

  static const TextStyle _koreanStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 11.908,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 0.99925,
  );

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: 'SEGUE', style: _segueStyle),
          TextSpan(text: ' 내역 확인', style: _koreanStyle),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MenuFooterAccountIcon extends StatelessWidget {
  const _MenuFooterAccountIcon();

  static const double width = 14.75;
  static const double height = 15.12;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _MenuFooterAccountIconPainter()),
    );
  }
}

class _MenuFooterAccountIconPainter extends CustomPainter {
  const _MenuFooterAccountIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path outerHead = Path()
      ..moveTo(5.84205, 0.0237734)
      ..cubicTo(7.42095, -0.180973, 8.86526, 0.959299, 9.07535, 2.57665)
      ..cubicTo(9.28543, 4.194, 8.18249, 5.68189, 6.60606, 5.90774)
      ..cubicTo(5.01485, 6.13573, 3.54715, 4.99239, 3.33502, 3.35999)
      ..cubicTo(3.12288, 1.72764, 4.24797, 0.230417, 5.84205, 0.0237734)
      ..close();
    final Path innerHead = Path()
      ..moveTo(5.93247, 1.29597)
      ..cubicTo(6.83447, 1.14127, 7.68769, 1.76636, 7.83757, 2.6914)
      ..cubicTo(7.98706, 3.61643, 7.37583, 4.49032, 6.47343, 4.6422)
      ..cubicTo(5.5726, 4.79376, 4.72251, 4.16899, 4.57302, 3.24592)
      ..cubicTo(4.42392, 2.32289, 5.03202, 1.45034, 5.93247, 1.29597)
      ..close();
    final Path body = Path()
      ..moveTo(5.99521, 6.3844)
      ..cubicTo(8.23392, 6.16919, 10.4861, 7.4174, 11.7192, 9.36965)
      ..cubicTo(12.5056, 10.6143, 12.7171, 11.6796, 12.8244, 13.1422)
      ..lineTo(11.6377, 13.1451)
      ..cubicTo(11.6471, 10.5052, 9.88948, 8.24119, 7.47498, 7.71591)
      ..cubicTo(7.25533, 7.66816, 7.04305, 7.63131, 6.82135, 7.59842)
      ..cubicTo(6.74349, 7.59277, 6.66522, 7.58934, 6.58695, 7.58816)
      ..cubicTo(3.57906, 7.53159, 1.2234, 9.96549, 1.17381, 13.1415)
      ..lineTo(0, 13.1443)
      ..cubicTo(0.204774, 9.46385, 2.44475, 6.68139, 5.99521, 6.3844)
      ..close();

    final Paint blackPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    final Paint cutoutPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.scale(size.width / 12.8244, size.height / 13.1451);
    canvas.drawPath(outerHead, blackPaint);
    canvas.drawPath(body, blackPaint);
    canvas.drawPath(innerHead, cutoutPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MenuFooterAccountIconPainter oldDelegate) {
    return false;
  }
}

class _MenuFooterSegueHistoryIcon extends StatelessWidget {
  const _MenuFooterSegueHistoryIcon();

  static const double width = 15.8;
  static const double height = 15.12;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _McmImageAssets.menuFooterSegueHistoryIcon,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _MenuFooterShoppingBagIcon extends StatelessWidget {
  const _MenuFooterShoppingBagIcon();

  static const double width = 13.7;
  static const double height = 11.88;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _McmImageAssets.menuFooterShoppingBagIcon,
      width: width,
      height: height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
    );
  }
}

class _ProductListScreen extends StatefulWidget {
  const _ProductListScreen({
    required this.products,
    required this.selectedCategory,
    required this.cartItems,
    required this.cartSkuIds,
    required this.isSavingCart,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onCategorySelected,
    required this.onProductSelected,
    required this.onQuickAddToCart,
    required this.onOpenMenu,
    required this.onOpenResults,
  });

  final List<MobileProduct> products;
  final String? selectedCategory;
  final List<CartItem> cartItems;
  final Set<int> cartSkuIds;
  final bool isSavingCart;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<MobileProduct> onProductSelected;
  final ValueChanged<MobileProduct> onQuickAddToCart;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenResults;

  @override
  State<_ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<_ProductListScreen> {
  bool _cartOrderFirst = false;

  void _selectSortOrder(String sortLabel) {
    setState(() => _cartOrderFirst = sortLabel == '장바구니 담은 순');
  }

  List<MobileProduct> _sortedProducts() {
    final List<MobileProduct> sortedProducts = List<MobileProduct>.of(
      widget.products,
    );
    if (!_cartOrderFirst) {
      return sortedProducts;
    }

    final Map<int, int> cartOrderByProductId = <int, int>{};
    for (int index = 0; index < widget.cartItems.length; index += 1) {
      cartOrderByProductId.putIfAbsent(
        widget.cartItems[index].productId,
        () => index,
      );
    }
    final Map<int, int> originalOrderByProductId = <int, int>{
      for (int index = 0; index < widget.products.length; index += 1)
        widget.products[index].id: index,
    };

    sortedProducts.sort((MobileProduct a, MobileProduct b) {
      final int? aCartOrder = cartOrderByProductId[a.id];
      final int? bCartOrder = cartOrderByProductId[b.id];
      if (aCartOrder != null && bCartOrder != null) {
        return aCartOrder.compareTo(bCartOrder);
      }
      if (aCartOrder != null) {
        return -1;
      }
      if (bCartOrder != null) {
        return 1;
      }
      return (originalOrderByProductId[a.id] ?? 0).compareTo(
        originalOrderByProductId[b.id] ?? 0,
      );
    });
    return sortedProducts;
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.selectedCategory ?? '가방';
    final String heroAssetPath = _McmImageAssets.categoryHeroFor(
      widget.selectedCategory,
    );
    final List<String?> categories =
        _isNewProductCategory(widget.selectedCategory)
        ? const <String?>[
            _ProductCategory.womenNewProducts,
            _ProductCategory.menNewProducts,
            _ProductCategory.autumnWinter2026,
          ]
        : const <String?>[
            _ProductCategory.bagNewProducts,
            null,
            '토트백 & 쇼퍼백',
            '숄더백 & 크로스백',
            '백팩',
            '탑 핸들백',
          ];
    final List<MobileProduct> sortedProducts = _sortedProducts();

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: widget.onOpenMenu,
              leadingIconWidget: const _McmTopBarMenuIcon(),
              onProfilePressed: widget.onOpenResults,
              profileIconWidget: const _McmTopBarProfileIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
              edgeIconButtonWidth: 58.56,
            ),
            _CategoryTrail(
              key: const ValueKey<String>('mobile-product-category-trail'),
              selectedCategory: widget.selectedCategory,
              categories: categories,
              onCategorySelected: widget.onCategorySelected,
            ),
            if (widget.isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Colors.black,
                backgroundColor: Color(0xFFEDEDED),
              ),
            if (widget.errorMessage != null)
              _ProductLoadErrorBanner(
                message: widget.errorMessage!,
                onRetry: widget.onRetry,
              ),
            Expanded(
              child: ListView(
                key: const ValueKey<String>('mobile-product-scroll-body'),
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _ProductCampaignHero(
                    assetPath: heroAssetPath,
                    title: title,
                    sortLabel: _cartOrderFirst ? '장바구니 담은 순' : '기본순',
                    onSortSelected: _selectSortOrder,
                  ),
                  const _ProductSortRow(),
                  if (sortedProducts.isEmpty)
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
                        childAspectRatio: 0.76,
                        children: <Widget>[
                          for (final MobileProduct product in sortedProducts)
                            _ProductGridTile(
                              product: product,
                              inCart:
                                  product.firstAvailableOption != null &&
                                  widget.cartSkuIds.contains(
                                    product.firstAvailableOption!.skuId,
                                  ),
                              isSavingCart: widget.isSavingCart,
                              onTap: () => widget.onProductSelected(product),
                              onBagPressed: () =>
                                  widget.onQuickAddToCart(product),
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

class _ProductLoadErrorBanner extends StatelessWidget {
  const _ProductLoadErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F4),
        border: Border.all(color: const Color(0xFFE7B8AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 10,
                height: 1.35,
                color: Color(0xFF6F2A1D),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            onPressed: onRetry,
            child: const Text('재시도'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTrail extends StatelessWidget {
  const _CategoryTrail({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  final String? selectedCategory;
  final List<String?> categories;
  final ValueChanged<String?> onCategorySelected;

  static const TextStyle _selectedStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 12.824,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 0.99925,
  );

  static const TextStyle _unselectedStyle = TextStyle(
    color: Color(0xFF7A7A7A),
    fontFamily: 'Pretendard',
    fontSize: 12.824,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 0.99925,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (BuildContext context, int index) {
          final String? category = categories[index];
          final bool selected = selectedCategory == category;
          final String label = switch (category) {
            null => '모두보기',
            _ProductCategory.bagNewProducts => '신상품',
            _ProductCategory.newProducts => '신상품',
            _ => category,
          };
          return Center(
            child: InkWell(
              onTap: () => onCategorySelected(category),
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == categories.length - 1 ? 0 : 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (selected) ...<Widget>[
                      Image.asset(
                        _McmImageAssets.productCategorySelectedArrowIcon,
                        width: 14,
                        height: 14,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: selected ? _selectedStyle : _unselectedStyle,
                    ),
                  ],
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
  const _ProductCampaignHero({
    required this.assetPath,
    required this.title,
    required this.sortLabel,
    required this.onSortSelected,
  });

  final String assetPath;
  final String title;
  final String sortLabel;
  final ValueChanged<String> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: '$title 상품 목록 캠페인',
          child: SizedBox(
            height: 228,
            child: OverflowBox(
              minWidth: 396,
              maxWidth: 396,
              minHeight: 228,
              maxHeight: 228,
              child: SizedBox(
                width: 396,
                height: 228,
                child: _CampaignMiniature(assetPath: assetPath, large: true),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Expanded(
                child: Text(
                  '정렬 기준 / 필터',
                  style: TextStyle(
                    color: Color(0xFF000000),
                    fontFamily: 'Pretendard',
                    fontSize: 10.076,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w500,
                    height: 0.99925,
                  ),
                ),
              ),
              _SortMenuButton(
                selectedLabel: sortLabel,
                options: const <String>['기본순', '장바구니 담은 순'],
                onSelected: onSortSelected,
                menuWidth: 116,
                textStyle: const TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: 'Pretendard',
                  fontSize: 10.076,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w500,
                  height: 0.99925,
                ),
                arrow: const _ProductSortArrowIcon(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductSortArrowIcon extends StatelessWidget {
  const _ProductSortArrowIcon();

  static const double width = 9;
  static const double height = 5;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _ProductSortArrowIconPainter()),
    );
  }
}

class _ProductSortArrowIconPainter extends CustomPainter {
  const _ProductSortArrowIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(8.26446, 0)
      ..lineTo(9, 0.743627)
      ..lineTo(4.99129, 4.79398)
      ..cubicTo(4.92705, 4.85927, 4.85067, 4.91108, 4.76653, 4.94644)
      ..cubicTo(4.6824, 4.9818, 4.59217, 5, 4.50104, 5)
      ..cubicTo(4.40991, 5, 4.31968, 4.9818, 4.23555, 4.94644)
      ..cubicTo(4.15141, 4.91108, 4.07503, 4.85927, 4.01079, 4.79398)
      ..lineTo(0, 0.743628)
      ..lineTo(0.735543, 0.000700918)
      ..lineTo(4.5, 3.80224)
      ..lineTo(8.26446, 0)
      ..close();

    canvas.save();
    canvas.scale(size.width / 9, size.height / 5);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProductSortArrowIconPainter oldDelegate) {
    return false;
  }
}

class _ConsultationSortArrowIcon extends StatelessWidget {
  const _ConsultationSortArrowIcon();

  static const double width = 8.244;
  static const double height = 4.58;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _ConsultationSortArrowIconPainter()),
    );
  }
}

class _ConsultationSortArrowIconPainter extends CustomPainter {
  const _ConsultationSortArrowIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(0, 0.920914)
      ..lineTo(0.67378, 0.000568)
      ..lineTo(4.12214, 3.48289)
      ..lineTo(7.57049, -0.000074)
      ..lineTo(8.24427, 0.681111)
      ..lineTo(4.57217, 4.39136)
      ..cubicTo(4.51333, 4.45116, 4.44336, 4.49863, 4.36629, 4.53102)
      ..cubicTo(4.28922, 4.5634, 4.20657, 4.58008, 4.12309, 4.58008)
      ..cubicTo(4.03961, 4.58008, 3.95696, 4.5634, 3.87989, 4.53102)
      ..cubicTo(3.80282, 4.49863, 3.73285, 4.45116, 3.67401, 4.39136)
      ..lineTo(0, 0.681111)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF3D3D3D));
  }

  @override
  bool shouldRepaint(_ConsultationSortArrowIconPainter oldDelegate) {
    return false;
  }
}

class _SortMenuButton extends StatefulWidget {
  const _SortMenuButton({
    required this.selectedLabel,
    required this.options,
    required this.onSelected,
    required this.menuWidth,
    required this.textStyle,
    required this.arrow,
  });

  final String selectedLabel;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final double menuWidth;
  final TextStyle textStyle;
  final Widget arrow;

  @override
  State<_SortMenuButton> createState() => _SortMenuButtonState();
}

class _SortMenuButtonState extends State<_SortMenuButton> {
  bool _isOpen = false;

  void _setOpen(bool value) {
    if (!mounted || _isOpen == value) {
      return;
    }
    setState(() => _isOpen = value);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: '',
      color: Colors.white,
      elevation: 2,
      offset: const Offset(0, 20),
      constraints: BoxConstraints.tightFor(width: widget.menuWidth),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFFDBDCE0), width: 0.6),
      ),
      onOpened: () => _setOpen(true),
      onCanceled: () => _setOpen(false),
      onSelected: (String value) {
        _setOpen(false);
        widget.onSelected(value);
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          for (final String option in widget.options)
            PopupMenuItem<String>(
              value: option,
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                option,
                style: widget.textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ];
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            widget.selectedLabel,
            textAlign: TextAlign.right,
            style: widget.textStyle,
          ),
          const SizedBox(width: 5),
          AnimatedRotation(
            turns: _isOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 120),
            child: widget.arrow,
          ),
        ],
      ),
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
  const _ProductGridTile({
    required this.product,
    required this.inCart,
    required this.isSavingCart,
    required this.onTap,
    required this.onBagPressed,
  });

  final MobileProduct product;
  final bool inCart;
  final bool isSavingCart;
  final VoidCallback onTap;
  final VoidCallback onBagPressed;

  @override
  Widget build(BuildContext context) {
    final MobileSkuOption? representativeOption = product.firstAvailableOption;
    final Color? representativeColor = representativeOption == null
        ? null
        : _productTileSwatchColor(
            representativeOption.color,
            representativeOption.swatchValue,
          );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 9.16, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.08,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  MobileProductVisual(
                    product: product,
                    compact: true,
                    imageFit: BoxFit.cover,
                    showFrame: false,
                  ),
                  Positioned(
                    left: 5,
                    top: 5,
                    right: 27,
                    child: Text(
                      product.collection,
                      style: const TextStyle(
                        color: Color(0xFF6E707C),
                        fontFamily: 'Pretendard',
                        fontSize: 8.244,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w400,
                        height: 0.99925,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _ProductTileBagButton(
                      selected: inCart,
                      enabled: !isSavingCart,
                      onPressed: onBagPressed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontFamily: 'Pretendard',
                fontSize: 10.076,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w500,
                height: 0.99925,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatWon(product.price),
              style: const TextStyle(
                color: Color(0xFF000000),
                fontFamily: 'Pretendard',
                fontSize: 10.076,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w500,
                height: 0.99925,
              ),
            ),
            const SizedBox(height: 5.5),
            if (representativeColor != null)
              _ProductTileColorChip(color: representativeColor),
          ],
        ),
      ),
    );
  }
}

Color _productTileSwatchColor(String colorName, int fallbackValue) {
  final String normalized = colorName.trim().toLowerCase().replaceAll(' ', '');
  return Color(switch (normalized) {
    'black' || '블랙' => 0xFF111111,
    'navy' || '네이비' => 0xFF1E3A5F,
    'beige' || '베이지' => 0xFFE8D9C5,
    'orange' || '오렌지' => 0xFFE85F35,
    'khaki' || '카키' || 'green' || '그린' => 0xFF66735F,
    'cognac' ||
    '꼬냑' ||
    '코냑' ||
    'camel' ||
    '카멜' ||
    'brown' ||
    '브라운' => 0xFFB87945,
    'darkbrown' || '다크브라운' => 0xFF5B3A24,
    'pink' || '핑크' => 0xFFE9B5C4,
    'white' || '화이트' => 0xFFF7F7F7,
    'gray' || 'grey' || '그레이' => 0xFF9CA3AF,
    _ => fallbackValue,
  });
}

class _ProductTileBagButton extends StatelessWidget {
  const _ProductTileBagButton({
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onPressed : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          selected
              ? _McmImageAssets.productTileBagAddedIcon
              : _McmImageAssets.productTileBagIcon,
          width: 13.74,
          height: 11.908,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _ProductTileColorChip extends StatelessWidget {
  const _ProductTileColorChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 11.8,
      height: 11.8,
      child: Center(
        child: Transform.rotate(
          angle: math.pi / 4,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF222222)),
            child: Padding(
              padding: const EdgeInsets.all(0.95),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
                child: Padding(
                  padding: const EdgeInsets.all(1.05),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color),
                    child: const SizedBox(width: 6.2, height: 6.2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _McmMixedFontText extends StatelessWidget {
  const _McmMixedFontText(
    this.text, {
    required this.koreanStyle,
    required this.latinStyle,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle koreanStyle;
  final TextStyle latinStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  static final RegExp _latinRun = RegExp(r'[A-Za-z0-9][A-Za-z0-9/&+\-. ]*');

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _spans()),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<InlineSpan> _spans() {
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    for (final RegExpMatch match in _latinRun.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: koreanStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: latinStyle,
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: koreanStyle));
    }
    return spans;
  }
}

class _ProductDetailScreen extends StatelessWidget {
  const _ProductDetailScreen({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    required this.selectedSku,
    required this.selectedSkuInCart,
    required this.onBack,
    required this.onColorSelected,
    required this.onSizeSelected,
    required this.onAddToCart,
    required this.isSavingCart,
    required this.cartSaveError,
    required this.onOpenAccount,
    required this.onOpenSegueIntro,
  });

  final MobileProduct product;
  final String? selectedColor;
  final String? selectedSize;
  final MobileSkuOption? selectedSku;
  final bool selectedSkuInCart;
  final VoidCallback onBack;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onAddToCart;
  final bool isSavingCart;
  final String? cartSaveError;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSegueIntro;

  @override
  Widget build(BuildContext context) {
    final Color selectedVisualColor = selectedColor == null
        ? Color(product.visualValue)
        : Color(product.optionForColor(selectedColor!).swatchValue);
    final List<String> availableColors = product.colors;
    final List<String> availableSizes = product.sizesForColor(selectedColor);
    final String colorLabel = selectedColor == null && availableColors.isEmpty
        ? '정보 없음'
        : displayProductColor(selectedColor ?? availableColors.first);
    final String sizeLabel = selectedSize == null && availableSizes.isEmpty
        ? '정보 없음'
        : displayProductSize(selectedSize ?? availableSizes.first);
    final List<(String, String)> skuDetailRows = <(String, String)>[
      if ((selectedSku?.material ?? product.material).trim().isNotEmpty)
        ('소재', selectedSku?.material ?? product.material),
      if ((selectedSku?.storageStructure ?? '').trim().isNotEmpty)
        ('수납', selectedSku!.storageStructure!),
      if ((selectedSku?.wearStyle ?? '').trim().isNotEmpty)
        ('착용', selectedSku!.wearStyle!),
      if (selectedSku?.weightGrams != null)
        ('무게', '${selectedSku!.weightGrams}g'),
      if (selectedSku?.laptopCompatible != null)
        ('노트북', selectedSku!.laptopCompatible! ? '수납 가능' : '수납 불가'),
      if ((selectedSku?.sizeGrade ?? '').trim().isNotEmpty)
        ('크기', selectedSku!.sizeGrade!),
    ];

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: onBack,
              leadingIconWidget: const _MenuCloseIcon(),
              onProfilePressed: onOpenAccount,
              profileIconWidget: const _McmTopBarProfileIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
              edgeIconButtonWidth: 58.56,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ColoredBox(
                    color: const Color(0xFFF7F7F7),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.5, 12, 16.5, 0),
                          child: Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  '신규 컬렉션',
                                  style: TextStyle(
                                    color: Color(0xFF6E707C),
                                    fontFamily: 'Pretendard',
                                    fontSize: 8.244,
                                    fontStyle: FontStyle.normal,
                                    fontWeight: FontWeight.w400,
                                    height: 0.99925,
                                  ),
                                ),
                              ),
                              _ProductDetailBagButton(
                                selected: selectedSkuInCart,
                                enabled: selectedSku != null && !isSavingCart,
                                onPressed: onAddToCart,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 34, 40, 24),
                          child: AspectRatio(
                            aspectRatio: 1.12,
                            child: MobileProductVisual(
                              product: product,
                              colorOverride: selectedVisualColor,
                              imageFit: BoxFit.cover,
                              showFrame: false,
                              backgroundColor: const Color(0xFFF7F7F7),
                            ),
                          ),
                        ),
                      ],
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
                            color: Color(0xFF000000),
                            fontFamily: 'Pretendard',
                            fontSize: 13.74,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            height: 0.99925,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _formatWon(product.price),
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'Pretendard',
                            fontSize: 13.74,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            height: 0.99925,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          '색상: $colorLabel',
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'Pretendard',
                            fontSize: 12.824,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 0.99925,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '사이즈: $sizeLabel',
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'Pretendard',
                            fontSize: 12.824,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 0.99925,
                          ),
                        ),
                        if (skuDetailRows.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 18),
                          _McmSkuDetailSection(rows: skuDetailRows),
                        ],
                        const SizedBox(height: 22),
                        if (availableColors.length > 1)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String color in availableColors)
                                _McmOptionChip(
                                  label: displayProductColor(color),
                                  selected: selectedColor == color,
                                  onTap: () => onColorSelected(color),
                                ),
                            ],
                          ),
                        if (availableSizes.length > 1) ...<Widget>[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String size in availableSizes)
                                _McmOptionChip(
                                  label: displayProductSize(size),
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
                        Center(
                          child: _ProductDetailAddToCartButton(
                            label: isSavingCart ? '저장 중' : '쇼핑백에 추가',
                            onPressed: selectedSku == null || isSavingCart
                                ? null
                                : onAddToCart,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(child: _ProductDetailAddToCartDivider()),
                        const SizedBox(height: 12),
                        const _McmFinePrint(
                          '이 제품으로 SEGUE 상담을 받고 싶으신가요? 쇼핑백에 추가해 보세요.',
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontFamily: 'Pretendard',
                            fontSize: 10.992,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 20.153 / 10.992,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _McmUnderlinedText(
                          'SEGUE 상담이 무엇인가요?',
                          onTap: onOpenSegueIntro,
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontFamily: 'Pretendard',
                            fontSize: 10.992,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 20.153 / 10.992,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF555555),
                          ),
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

class _ProductDetailBagButton extends StatelessWidget {
  const _ProductDetailBagButton({
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onPressed : null,
      child: SizedBox(
        width: 26,
        height: 26,
        child: Align(
          alignment: Alignment.centerRight,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Image.asset(
              selected
                  ? _McmImageAssets.productTileBagAddedIcon
                  : _McmImageAssets.productTileBagIcon,
              width: 13.74,
              height: 12.207,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _McmSkuDetailSection extends StatefulWidget {
  const _McmSkuDetailSection({required this.rows});

  final List<(String, String)> rows;

  @override
  State<_McmSkuDetailSection> createState() => _McmSkuDetailSectionState();
}

class _McmSkuDetailSectionState extends State<_McmSkuDetailSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: _McmSkuDetailHeader(expanded: _expanded),
        ),
        if (_expanded) ...<Widget>[
          const SizedBox(height: 12),
          _McmSkuDetailPanel(rows: widget.rows),
        ],
      ],
    );
  }
}

class _ProductDetailAddToCartButton extends StatelessWidget {
  const _ProductDetailAddToCartButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320.611,
      height: 44,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: onPressed,
        child: Center(
          child: Container(
            width: 320.611,
            height: 36.641,
            alignment: Alignment.center,
            color: onPressed == null ? const Color(0xFF8A8A8A) : Colors.black,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontSize: 11.908,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
                height: 0.99925,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductDetailAddToCartDivider extends StatelessWidget {
  const _ProductDetailAddToCartDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 320.611,
      height: 0.916,
      child: ColoredBox(color: Colors.black),
    );
  }
}

class _McmSkuDetailPanel extends StatelessWidget {
  const _McmSkuDetailPanel({required this.rows});

  final List<(String, String)> rows;

  static const double _detailLineHeight = 18.321 / 11.908;

  static const TextStyle _labelStyle = TextStyle(
    color: Color(0xFF515151),
    fontFamily: 'Pretendard',
    fontSize: 11.908,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: _detailLineHeight,
  );

  static const TextStyle _valueStyle = TextStyle(
    color: Color(0xFF515151),
    fontFamily: 'Pretendard',
    fontSize: 11.908,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: _detailLineHeight,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final (String label, String value) in rows)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 54, child: Text(label, style: _labelStyle)),
              Expanded(child: Text(value, style: _valueStyle)),
            ],
          ),
      ],
    );
  }
}

class _McmSkuDetailHeader extends StatelessWidget {
  const _McmSkuDetailHeader({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget arrow = const SizedBox(
      width: 6.412,
      height: 11.268,
      child: CustomPaint(painter: _McmSkuDetailArrowPainter()),
    );

    return SizedBox(
      height: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Expanded(
            child: Text(
              '소재 및 상세 정보',
              style: TextStyle(
                color: Color(0xFF000000),
                fontFamily: 'Pretendard',
                fontSize: 12.824,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w500,
                height: 0.99925,
              ),
            ),
          ),
          expanded ? RotatedBox(quarterTurns: 1, child: arrow) : arrow,
        ],
      ),
    );
  }
}

class _McmSkuDetailArrowPainter extends CustomPainter {
  const _McmSkuDetailArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(-0.000105499, 0.92084)
      ..lineTo(0.953554, -0.0000283537)
      ..lineTo(6.1479, 5.0187)
      ..cubicTo(6.23163, 5.09912, 6.29808, 5.19475, 6.34342, 5.30008)
      ..cubicTo(6.38877, 5.40542, 6.41211, 5.51838, 6.41211, 5.63247)
      ..cubicTo(6.41211, 5.74656, 6.38877, 5.85952, 6.34342, 5.96486)
      ..cubicTo(6.29808, 6.07019, 6.23163, 6.16582, 6.1479, 6.24624)
      ..lineTo(0.953555, 11.2676)
      ..lineTo(0.00079407, 10.3467)
      ..lineTo(4.87605, 5.63377)
      ..lineTo(-0.000105499, 0.92084)
      ..close();

    canvas
      ..save()
      ..scale(size.width / 6.41211, size.height / 11.2676)
      ..drawPath(
        path,
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.fill,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_McmSkuDetailArrowPainter oldDelegate) {
    return false;
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

class _McmFinePrint extends StatelessWidget {
  const _McmFinePrint(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          style ??
          const TextStyle(color: Color(0xFF777777), fontSize: 9, height: 1.45),
    );
  }
}

class _McmUnderlinedText extends StatelessWidget {
  const _McmUnderlinedText(this.text, {this.style, this.onTap, this.maxLines});

  final String text;
  final TextStyle? style;
  final VoidCallback? onTap;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final Widget child = Text(
      text,
      maxLines: maxLines,
      style:
          style ??
          const TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 9,
            decoration: TextDecoration.underline,
          ),
    );
    if (onTap == null) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
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

class _CartListLineItem extends StatelessWidget {
  const _CartListLineItem({required this.item});

  final CartItem item;

  static const TextStyle _itemTextStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 12.824,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 0.99925,
  );

  @override
  Widget build(BuildContext context) {
    final MobileProduct product = MobileProductCatalog.productById(
      item.productId,
    ).copyWith(imageUrl: item.imageUrl);
    final String colorLabel = _formatResultProductColor(item.color);
    final String sizeLabel = displayProductSize(item.size);

    return SizedBox(
      height: 155,
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19.2, 11.9, 16, 15.6),
          child: SizedBox(
            height: 127.328,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 116.336,
                  height: 127.328,
                  child: ColoredBox(
                    color: const Color(0xFFD9D9D9),
                    child: MobileProductVisual(
                      product: product,
                      compact: true,
                      imageFit: BoxFit.contain,
                      showFrame: false,
                      backgroundColor: const Color(0xFFD9D9D9),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _itemTextStyle,
                      ),
                      const SizedBox(height: 18),
                      Text(_formatWon(product.price), style: _itemTextStyle),
                      const SizedBox(height: 34),
                      Text(colorLabel, style: _itemTextStyle),
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Text(sizeLabel, style: _itemTextStyle),
                          ),
                          const Text(
                            '수량 1',
                            textAlign: TextAlign.right,
                            style: _itemTextStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartEmptyScreen extends StatelessWidget {
  const _CartEmptyScreen({required this.isLoggedIn, required this.onLogin});

  final bool isLoggedIn;
  final VoidCallback onLogin;

  static const TextStyle _emptyTextStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 12.824,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 0.99925,
  );

  static const TextStyle _loginTextStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 12.824,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 0.99925,
    decoration: TextDecoration.underline,
    decorationColor: Color(0xFF000000),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '나의 쇼핑백(0개 품목)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: 'Pretendard',
                  fontSize: 13.74,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w700,
                  height: 0.99925,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  '쇼핑백이 비어 있습니다.',
                  textAlign: TextAlign.center,
                  style: _emptyTextStyle,
                ),
                const SizedBox(height: 4),
                if (isLoggedIn)
                  const Text(
                    '마음에 드는 상품을 쇼핑백에 담아보세요.',
                    textAlign: TextAlign.center,
                    style: _emptyTextStyle,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onLogin,
                        child: const Text('로그인', style: _loginTextStyle),
                      ),
                      const Text(' 후 쇼핑백 확인하러 가기', style: _emptyTextStyle),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartCheckoutPanel extends StatelessWidget {
  const _CartCheckoutPanel({
    required this.itemCount,
    required this.totalPrice,
    required this.onCheckout,
  });

  final int itemCount;
  final int totalPrice;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 360,
        height: 175.878,
        child: ColoredBox(
          color: const Color(0xFFF6F6F6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _CartCheckoutSummary(
                  itemCount: itemCount,
                  totalPrice: totalPrice,
                ),
                _CartCheckoutButton(label: '결제하기', onPressed: onCheckout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartCheckoutSummary extends StatelessWidget {
  const _CartCheckoutSummary({
    required this.itemCount,
    required this.totalPrice,
  });

  final int itemCount;
  final int totalPrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _CartCheckoutAmountRow(
          label: '소계 ($itemCount개 품목)',
          value: _formatWon(totalPrice),
        ),
        const SizedBox(height: 13),
        const _CartCheckoutAmountRow(label: '배송비', value: '무료'),
        const SizedBox(height: 13),
        _CartCheckoutAmountRow(
          label: '예상 합계',
          value: _formatWon(totalPrice),
          total: true,
        ),
      ],
    );
  }
}

class _CartCheckoutAmountRow extends StatelessWidget {
  const _CartCheckoutAmountRow({
    required this.label,
    required this.value,
    this.total = false,
  });

  final String label;
  final String value;
  final bool total;

  static const TextStyle _labelStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 13.74,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    height: 0.99925,
  );

  static const TextStyle _valueStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 13.74,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w500,
    height: 0.99925,
  );

  static const TextStyle _totalValueStyle = TextStyle(
    color: Color(0xFF000000),
    fontFamily: 'Pretendard',
    fontSize: 13.74,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w600,
    height: 0.99925,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: Text(label, style: _labelStyle)),
        Text(
          value,
          textAlign: TextAlign.right,
          style: total ? _totalValueStyle : _valueStyle,
        ),
      ],
    );
  }
}

class _CartCheckoutButton extends StatelessWidget {
  const _CartCheckoutButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320.611,
      height: 36.641,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF222222),
          foregroundColor: const Color(0xFFFFFFFF),
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontFamily: 'Pretendard',
            fontSize: 11.908,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w600,
            height: 0.99925,
            letterSpacing: 0,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontFamily: 'Pretendard',
            fontSize: 11.908,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w600,
            height: 0.99925,
            letterSpacing: 0,
          ),
        ),
      ),
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
    this.onOpenSegueIntro,
  });

  final String totalLabel;
  final int totalPrice;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onOpenSegueIntro;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 360,
        height: 226.26,
        child: ColoredBox(
          color: const Color(0xFFF6F6F6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.2, 20, 19.2, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ShoppingBagActionTotalRow(
                  label: totalLabel,
                  value: _formatWon(totalPrice),
                ),
                const SizedBox(height: 22),
                _ShoppingBagActionButton(
                  label: primaryLabel,
                  onPressed: onPrimary,
                  primary: true,
                ),
                if (secondaryLabel != null && onSecondary != null) ...<Widget>[
                  const SizedBox(height: 4.6),
                  _ShoppingBagActionButton(
                    label: secondaryLabel!,
                    onPressed: onSecondary!,
                    primary: false,
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  '쇼핑백에 상품을 추가하면 SEGUE 상담을 손쉽게 받을 수 있어요.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontFamily: 'Pretendard',
                    fontSize: 10.992,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    height: 20.153 / 10.992,
                  ),
                ),
                const SizedBox(height: 2),
                _McmUnderlinedText(
                  'SEGUE 상담이 무엇인가요?',
                  onTap: onOpenSegueIntro,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontFamily: 'Pretendard',
                    fontSize: 10.992,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w500,
                    height: 20.153 / 10.992,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShoppingBagActionTotalRow extends StatelessWidget {
  const _ShoppingBagActionTotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontFamily: 'Pretendard',
              fontSize: 14.656,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              height: 0.99925,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFF000000),
            fontFamily: 'Pretendard',
            fontSize: 14.656,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w500,
            height: 0.99925,
          ),
        ),
      ],
    );
  }
}

class _ShoppingBagActionButton extends StatelessWidget {
  const _ShoppingBagActionButton({
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = primary
        ? const Color(0xFF222222)
        : const Color(0xFFFFFFFF);
    final Color textColor = primary
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF222222);

    return SizedBox(
      width: 320.611,
      height: 36.641,
      child: OverflowBox(
        minHeight: 44,
        maxHeight: 44,
        alignment: Alignment.center,
        child: SizedBox(
          width: 320.611,
          height: 44,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: textColor,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const RoundedRectangleBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11.908,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w600,
                height: 0.99925,
                letterSpacing: 0,
              ),
            ),
            onPressed: onPressed,
            child: SizedBox(
              width: 320.611,
              height: 36.641,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: primary
                      ? null
                      : Border.all(
                          color: const Color(0xFF222222),
                          width: 0.916,
                        ),
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'Pretendard',
                      fontSize: 11.908,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w600,
                      height: 0.99925,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
    ).copyWith(imageUrl: result.imageUrl);
    final MobileSkuOption? sku = MobileProductCatalog.skuById(result.skuId);
    final String colorLabel = _formatResultProductColor(sku?.color ?? 'Black');
    final String sizeLabel = displayProductSize(sku?.size ?? 'M');
    final String priceLabel = _formatWon(product.price).replaceFirst('₩ ', '₩');

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE7E7E7), width: 0.641),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19.2, 10.1, 19.2, 10.1),
          child: SizedBox(
            height: 127.328,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 116.336,
                  height: 127.328,
                  child: MobileProductVisual(
                    product: product,
                    colorOverride: sku == null ? null : Color(sku.swatchValue),
                    compact: true,
                    imageFit: BoxFit.cover,
                    showFrame: false,
                    backgroundColor: const Color(0xFFD9D9D9),
                  ),
                ),
                const SizedBox(width: 12.824),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 40.305,
                            height: 14.656,
                            color: const Color(0xFF7A7A7A),
                            alignment: Alignment.center,
                            child: const Text(
                              '상담 제품',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontFamily: 'Pretendard',
                                fontSize: 8.244,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF000000),
                              fontFamily: 'Pretendard',
                              fontSize: 12.824,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w600,
                              height: 0.99925,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            priceLabel,
                            style: const TextStyle(
                              color: Color(0xFF000000),
                              fontFamily: 'Pretendard',
                              fontSize: 12.824,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w400,
                              height: 0.99925,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            colorLabel,
                            style: const TextStyle(
                              color: Color(0xFF000000),
                              fontFamily: 'Pretendard',
                              fontSize: 12.824,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w400,
                              height: 0.99925,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sizeLabel,
                            style: const TextStyle(
                              color: Color(0xFF000000),
                              fontFamily: 'Pretendard',
                              fontSize: 12.824,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w400,
                              height: 0.99925,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 80.611,
                          height: 12.824,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatCompactDateTime(result.consultedAt),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontFamily: 'Pretendard',
                                fontSize: 10.076,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w400,
                                height: 1,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            style: const TextStyle(
              color: Color(0xFF000000),
              fontFamily: 'Pretendard',
              fontSize: 12.824,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w600,
              height: 0.99925,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontFamily: 'Pretendard',
              fontSize: 10.992,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500,
              height: 10.984 / 10.992,
              letterSpacing: 0,
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
    required this.cartItems,
    required this.onBack,
    required this.onOpenCart,
    required this.onContinueShopping,
    required this.onOpenAccount,
    required this.onOpenSegueIntro,
  });

  final CartItem? cartItem;
  final List<CartItem> cartItems;
  final VoidCallback onBack;
  final VoidCallback onOpenCart;
  final VoidCallback onContinueShopping;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSegueIntro;

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
              leadingIconWidget: const _MenuCloseIcon(),
              onProfilePressed: onOpenAccount,
              profileIconWidget: const _McmTopBarProfileIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
              edgeIconButtonWidth: 58.56,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      '새로운 상품이 추가되었습니다!',
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontFamily: 'Pretendard',
                        fontSize: 12.824,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w500,
                        height: 0.99925,
                      ),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        const TextSpan(text: '('),
                        TextSpan(
                          text: '$itemCount',
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'Pretendard',
                            fontSize: 12.824,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            height: 0.99925,
                          ),
                        ),
                        const TextSpan(text: '개 품목)'),
                      ],
                    ),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Pretendard',
                      fontSize: 12.824,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w400,
                      height: 0.99925,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: displayItems.isEmpty
                  ? const Center(child: _McmEmptyState(message: '저장된 항목이 없습니다'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
                      itemCount: displayItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Center(
                          child: SizedBox(
                            width: 360,
                            child: _CartListLineItem(item: displayItems[index]),
                          ),
                        );
                      },
                    ),
            ),
            _ShoppingBagActionPanel(
              totalLabel: '합계:',
              totalPrice: totalPrice,
              primaryLabel: '쇼핑백 확인하기',
              onPrimary: onOpenCart,
              secondaryLabel: '계속 쇼핑하기',
              onSecondary: onContinueShopping,
              onOpenSegueIntro: onOpenSegueIntro,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartAddedSlideIn extends StatefulWidget {
  const _CartAddedSlideIn({required this.child});

  final Widget child;

  @override
  State<_CartAddedSlideIn> createState() => _CartAddedSlideInState();
}

class _CartAddedSlideInState extends State<_CartAddedSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _CartListScreen extends StatelessWidget {
  const _CartListScreen({
    required this.cartItems,
    required this.isLoading,
    required this.errorMessage,
    required this.isLoggedIn,
    required this.onRetry,
    required this.onBackToProducts,
    required this.onOpenMenu,
    required this.onOpenAccount,
    required this.onOpenLogin,
  });

  final List<CartItem> cartItems;
  final bool isLoading;
  final String? errorMessage;
  final bool isLoggedIn;
  final VoidCallback onRetry;
  final VoidCallback onBackToProducts;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenLogin;

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
              onLeadingPressed: onOpenMenu,
              leadingIconWidget: const _McmTopBarMenuIcon(),
              onProfilePressed: onOpenAccount,
              profileIconWidget: const _McmTopBarProfileIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
              edgeIconButtonWidth: 58.56,
            ),
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
                    return _CartEmptyScreen(
                      isLoggedIn: isLoggedIn,
                      onLogin: onOpenLogin,
                    );
                  }

                  return Column(
                    children: <Widget>[
                      SizedBox(
                        height: 44,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '나의 쇼핑백(${cartItems.length}개 품목)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF000000),
                                fontFamily: 'Pretendard',
                                fontSize: 13.74,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w700,
                                height: 0.99925,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 14),
                          itemCount: cartItems.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Center(
                              child: SizedBox(
                                width: 360,
                                child: _CartListLineItem(
                                  item: cartItems[index],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _CartCheckoutPanel(
                        itemCount: cartItems.length,
                        totalPrice: totalPrice,
                        onCheckout: () {},
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

class _ConsultationResultsScreen extends StatefulWidget {
  const _ConsultationResultsScreen({
    required this.results,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOnlinePurchase,
    required this.onStoreVisit,
    required this.onBackToHome,
    required this.onOpenMenu,
    required this.onOpenAccount,
  });

  final List<ConsultationResult> results;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<ConsultationResult> onOnlinePurchase;
  final ValueChanged<ConsultationResult> onStoreVisit;
  final VoidCallback onBackToHome;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenAccount;

  @override
  State<_ConsultationResultsScreen> createState() =>
      _ConsultationResultsScreenState();
}

class _ConsultationResultsScreenState
    extends State<_ConsultationResultsScreen> {
  bool _newestFirst = true;

  void _selectSortOrder(String sortLabel) {
    setState(() => _newestFirst = sortLabel == '최근 상담순');
  }

  @override
  Widget build(BuildContext context) {
    final List<ConsultationResult> sortedResults =
        List<ConsultationResult>.of(widget.results)
          ..sort((ConsultationResult a, ConsultationResult b) {
            final int comparison = a.consultedAt.compareTo(b.consultedAt);
            return _newestFirst ? -comparison : comparison;
          });

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _McmTopBar(
              onLeadingPressed: widget.onOpenMenu,
              leadingIconWidget: const _McmTopBarMenuIcon(),
              onProfilePressed: widget.onOpenAccount,
              profileIconWidget: const _McmTopBarProfileIcon(),
              logoAssetPath: _McmImageAssets.menuMcmLogo,
              logoWidth: 54.046,
              logoHeight: 17.542,
              logoFit: BoxFit.fill,
              edgeIconButtonWidth: 58.56,
            ),
            const SizedBox(height: 12),
            const Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: 'SEGUE',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Montserrat',
                      fontSize: 13.74,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w700,
                      height: 16.737 / 13.74,
                    ),
                  ),
                  TextSpan(
                    text: ' 내역',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Pretendard',
                      fontSize: 13.74,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w700,
                      height: 0.99925,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  if (widget.isLoading) {
                    return const Center(
                      child: AppStateView.loading(title: '상담 결과를 불러오는 중입니다'),
                    );
                  }

                  if (widget.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: AppStateView.error(
                          message: widget.errorMessage,
                          onAction: widget.onRetry,
                        ),
                      ),
                    );
                  }

                  if (sortedResults.isEmpty) {
                    return const Center(
                      child: _McmEmptyState(message: '상담 결과가 없습니다'),
                    );
                  }

                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '총 ${sortedResults.length}건의 상담 기록',
                              style: const TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontFamily: 'Pretendard',
                                fontSize: 10.992,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            const Spacer(),
                            _SortMenuButton(
                              selectedLabel: _newestFirst
                                  ? '최근 상담순'
                                  : '오래된 상담순',
                              options: const <String>['최근 상담순', '오래된 상담순'],
                              onSelected: _selectSortOrder,
                              menuWidth: 102,
                              textStyle: const TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontFamily: 'Pretendard',
                                fontSize: 10.076,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                                height: 0.99925,
                                letterSpacing: 0,
                              ),
                              arrow: const _ConsultationSortArrowIcon(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: sortedResults.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ConsultationResult result =
                                sortedResults[index];
                            return _SegueHistoryRow(
                              result: result,
                              onTap: () => widget.onOnlinePurchase(result),
                            );
                          },
                        ),
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
    final ProductSkuSummary? recommendedProduct =
        currentResult.recommendedProduct;

    return _McmPhoneShell(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _SegueResultTopBar(onClose: onBack),
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
                  if (recommendedProduct != null) ...<Widget>[
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
                            productSummary: recommendedProduct,
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            '상담 완료',
                            style: TextStyle(
                              color: Color(0xFF000000),
                              fontFamily: 'Pretendard',
                              fontSize: 12.824,
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w700,
                              height: 0.99925,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: 314.198,
                            child: Text(
                              '추천 제품은 Client Advisor와 함께 매장에서 확인했습니다. 또한 해당 매장에서 바로 구매가 진행되었습니다.',
                              style: TextStyle(
                                color: Color(0xFF222222),
                                fontFamily: 'Pretendard',
                                fontSize: 10.992,
                                fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w500,
                                height: 14.656 / 10.992,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    this.productSummary,
  });

  final ConsultationResult result;
  final bool showBadge;
  final bool recommended;
  final ProductSkuSummary? productSummary;

  @override
  Widget build(BuildContext context) {
    final ProductSkuSummary? summary = productSummary;
    final int skuId = summary?.skuId ?? result.skuId;
    final String productName = summary?.productName ?? result.productName;
    final String imageUrl =
        summary != null && summary.imageUrl.trim().isNotEmpty
        ? summary.imageUrl
        : result.imageUrl;
    final MobileProduct product = MobileProductCatalog.productBySkuId(
      skuId,
    ).copyWith(name: productName, imageUrl: imageUrl);
    final MobileSkuOption? sku = MobileProductCatalog.skuById(skuId);
    final String color = _formatResultProductColor(
      summary?.color ?? sku?.color ?? 'Black',
    );
    final String size = displayProductSize(summary?.size ?? sku?.size ?? 'M');
    final String priceLabel = _formatWon(product.price).replaceFirst('₩ ', '₩');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 116.336,
          height: 127.328,
          child: MobileProductVisual(
            product: product,
            colorOverride: sku == null ? null : Color(sku.swatchValue),
            compact: true,
            imageFit: BoxFit.cover,
            showFrame: false,
            backgroundColor: const Color(0xFFD9D9D9),
          ),
        ),
        const SizedBox(width: 12.824),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showBadge) ...<Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 40.305,
                    height: 14.656,
                    color: recommended
                        ? const Color(0xFF222222)
                        : const Color(0xFF7A7A7A),
                    alignment: Alignment.center,
                    child: Text(
                      recommended ? '추천 제품' : '상담 제품',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontFamily: 'Pretendard',
                        fontSize: 8.244,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                const Text(
                  '상담 제품',
                  style: TextStyle(
                    color: Color(0xFF000000),
                    fontFamily: 'Pretendard',
                    fontSize: 12.824,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                    height: 0.99925,
                    letterSpacing: 0,
                  ),
                ),
              Text(
                productName,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: 'Pretendard',
                  fontSize: 12.824,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w600,
                  height: 0.99925,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                priceLabel,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: 'Pretendard',
                  fontSize: 12.824,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w400,
                  height: 0.99925,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                color,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: 'Pretendard',
                  fontSize: 12.824,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w400,
                  height: 0.99925,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                size,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: 'Pretendard',
                  fontSize: 12.824,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w400,
                  height: 0.99925,
                  letterSpacing: 0,
                ),
              ),
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

String _formatCompactDateTime(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  final String hour = date.hour.toString().padLeft(2, '0');
  final String minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}.$month.$day $hour:$minute';
}

String _formatResultProductColor(String color) {
  return displayProductColor(color);
}

String _formatWon(int price) {
  if (price <= 0) {
    return '가격 정보 없음';
  }
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
