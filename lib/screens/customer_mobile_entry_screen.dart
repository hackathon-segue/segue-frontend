import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../repositories/repositories.dart';
import '../utils/app_design_tokens.dart';
import '../utils/execution_status_display.dart';
import '../widgets/app_state_view.dart';
import '../widgets/mobile_product_visual.dart';
import '../widgets/mobile_screen_scaffold.dart';

enum _MobileScreen {
  login,
  home,
  products,
  detail,
  cartAdded,
  cart,
  results,
  onlinePurchase,
  storeVisit,
}

class CustomerMobileEntryScreen extends StatefulWidget {
  const CustomerMobileEntryScreen({super.key});

  @override
  State<CustomerMobileEntryScreen> createState() =>
      _CustomerMobileEntryScreenState();
}

class _CustomerMobileEntryScreenState extends State<CustomerMobileEntryScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  _MobileScreen _screen = _MobileScreen.login;
  MobileProduct _selectedProduct = MobileProductCatalog.products[2];
  String? _selectedCategory;
  String? _selectedColor;
  String? _selectedSize;
  CartItem? _lastSavedCartItem;
  final List<CartItem> _cartItems = <CartItem>[];
  bool _isSavingCart = false;
  String? _cartSaveError;
  final List<ConsultationResult> _consultationResults = <ConsultationResult>[];
  ConsultationResult? _selectedConsultationResult;
  bool _isLoadingResults = false;
  String? _resultsError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      _MobileScreen.login => _LoginScreen(
        emailController: _emailController,
        passwordController: _passwordController,
        onEnter: _openHome,
      ),
      _MobileScreen.home => _HomeScreen(
        onOpenProducts: _openProducts,
        onBackToLogin: () => setState(() => _screen = _MobileScreen.login),
        onTabSelected: _openTab,
      ),
      _MobileScreen.products => _ProductListScreen(
        products: _filteredProducts,
        selectedCategory: _selectedCategory,
        searchController: _searchController,
        onSearchChanged: (_) => setState(() {}),
        onCategorySelected: (String? category) {
          setState(() => _selectedCategory = category);
        },
        onProductSelected: _openDetail,
        onTabSelected: _openTab,
      ),
      _MobileScreen.detail => _ProductDetailScreen(
        product: _selectedProduct,
        selectedColor: _selectedColor,
        selectedSize: _selectedSize,
        selectedSku: _selectedProduct.skuFor(
          color: _selectedColor,
          size: _selectedSize,
        ),
        onBack: _openProducts,
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
        onContinueShopping: _openProducts,
      ),
      _MobileScreen.cart => _CartListScreen(
        cartItems: _cartItems,
        onBackToProducts: _openProducts,
        onTabSelected: _openTab,
      ),
      _MobileScreen.results => _ConsultationResultsScreen(
        results: _consultationResults,
        isLoading: _isLoadingResults,
        errorMessage: _resultsError,
        onRetry: () => _loadConsultationResults(force: true),
        onOnlinePurchase: _openOnlinePurchase,
        onStoreVisit: _openStoreVisit,
        onBackToHome: _openHome,
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
    final String keyword = _searchController.text.trim().toLowerCase();
    return MobileProductCatalog.products.where((MobileProduct product) {
      final bool matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;
      final bool matchesKeyword =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword) ||
          product.collection.toLowerCase().contains(keyword);
      return matchesCategory && matchesKeyword;
    }).toList();
  }

  void _openHome() {
    setState(() => _screen = _MobileScreen.home);
  }

  void _openProducts() {
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

    setState(() {
      _screen = switch (tab) {
        CustomerMobileTab.home => _MobileScreen.home,
        CustomerMobileTab.products => _MobileScreen.products,
        CustomerMobileTab.cart => _MobileScreen.cart,
        CustomerMobileTab.results => _MobileScreen.results,
      };
    });
  }

  void _openCart() {
    setState(() => _screen = _MobileScreen.cart);
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
      ).fetchConsultationResults(1);
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
          customerId: 1,
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

class _LoginScreen extends StatelessWidget {
  const _LoginScreen({
    required this.emailController,
    required this.passwordController,
    required this.onEnter,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return MobileScreenScaffold(
      title: '앱 로그인 화면',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('로그인', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              Text('이메일 주소', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('비밀번호', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: onEnter, child: const Text('로그인')),
              const SizedBox(height: AppSpacing.lg),
              Text('계정이 없으신가요?', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton(
                onPressed: onEnter,
                child: const Text('신규 계정 만들기'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(child: Text('또는', style: theme.textTheme.bodySmall)),
              const SizedBox(height: AppSpacing.sm),
              Align(
                child: OutlinedButton(
                  onPressed: onEnter,
                  child: const Text('앱으로 계속하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.onOpenProducts,
    required this.onBackToLogin,
    required this.onTabSelected,
  });

  final VoidCallback onOpenProducts;
  final VoidCallback onBackToLogin;
  final ValueChanged<CustomerMobileTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MobileProduct heroProduct = MobileProductCatalog.products[2];

    return MobileScreenScaffold(
      title: '앱 홈 화면',
      currentTab: CustomerMobileTab.home,
      onTabSelected: onTabSelected,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.42,
            child: MobileProductVisual(product: heroProduct),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('MCM 월드', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '당신의 스타일을 완성하는 프리미엄 가죽 제품을 만나보세요.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const _HomeFeatureTile(
            icon: Icons.auto_awesome_outlined,
            title: '신상품 컬렉션',
            description: '새롭게 출시된 MCM 제품을 확인하세요.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _HomeFeatureTile(
            icon: Icons.favorite_border,
            title: '베스트셀러',
            description: '가장 많이 찾는 제품을 한눈에 보세요.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _HomeFeatureTile(
            icon: Icons.palette_outlined,
            title: '컬러별 탐색',
            description: '원하는 컬러로 제품을 찾아보세요.',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onOpenProducts,
              child: const Text('제품 전체 보기'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onBackToLogin,
              child: const Text('돌아가기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFeatureTile extends StatelessWidget {
  const _HomeFeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceMuted,
              foregroundColor: AppColors.ink,
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
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
    required this.searchController,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onProductSelected,
    required this.onTabSelected,
  });

  final List<MobileProduct> products;
  final String? selectedCategory;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<MobileProduct> onProductSelected;
  final ValueChanged<CustomerMobileTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const List<String?> categories = <String?>[null, '가방', '지갑', '액세서리'];

    return MobileScreenScaffold(
      title: '제품 목록 화면',
      currentTab: CustomerMobileTab.products,
      onTabSelected: onTabSelected,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Text('제품', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final String? category in categories)
                ChoiceChip(
                  label: Text(category ?? '전체'),
                  selected: selectedCategory == category,
                  onSelected: (_) => onCategorySelected(category),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (products.isEmpty)
            const AppStateView.empty(title: '검색 결과가 없습니다')
          else
            for (final MobileProduct product in products) ...<Widget>[
              _ProductListCard(
                product: product,
                onTap: () => onProductSelected(product),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({required this.product, required this.onTap});

  final MobileProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
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
                    Text(product.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(product.collection, style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatWon(product.price),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
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
    required this.onBackToProducts,
    required this.onTabSelected,
  });

  final List<CartItem> cartItems;
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
          if (cartItems.isEmpty)
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
