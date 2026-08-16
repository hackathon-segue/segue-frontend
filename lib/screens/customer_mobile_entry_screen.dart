import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/app_design_tokens.dart';
import '../widgets/app_state_view.dart';
import '../widgets/mobile_product_visual.dart';
import '../widgets/mobile_screen_scaffold.dart';

enum _MobileScreen { login, home, products, detail, cart, results }

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
      ),
      _MobileScreen.cart => _MobilePlaceholderScreen(
        title: '앱 장바구니 목록',
        tab: CustomerMobileTab.cart,
        icon: Icons.shopping_cart_outlined,
        headline: '담긴 제품이 없습니다',
        onTabSelected: _openTab,
      ),
      _MobileScreen.results => _MobilePlaceholderScreen(
        title: '앱 상담 결과 확인',
        tab: CustomerMobileTab.results,
        icon: Icons.receipt_long_outlined,
        headline: '상담 결과가 없습니다',
        onTabSelected: _openTab,
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
    setState(() {
      _screen = switch (tab) {
        CustomerMobileTab.home => _MobileScreen.home,
        CustomerMobileTab.products => _MobileScreen.products,
        CustomerMobileTab.cart => _MobileScreen.cart,
        CustomerMobileTab.results => _MobileScreen.results,
      };
    });
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
  });

  final MobileProduct product;
  final String? selectedColor;
  final String? selectedSize;
  final MobileSkuOption? selectedSku;
  final VoidCallback onBack;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onSizeSelected;

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
              FilledButton(
                onPressed: selectedSku == null
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('선택한 SKU ${selectedSku!.skuId}'),
                          ),
                        );
                      },
                child: const Text('장바구니 담기'),
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

class _MobilePlaceholderScreen extends StatelessWidget {
  const _MobilePlaceholderScreen({
    required this.title,
    required this.tab,
    required this.icon,
    required this.headline,
    required this.onTabSelected,
  });

  final String title;
  final CustomerMobileTab tab;
  final IconData icon;
  final String headline;
  final ValueChanged<CustomerMobileTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return MobileScreenScaffold(
      title: title,
      currentTab: tab,
      onTabSelected: onTabSelected,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppStateView(icon: icon, title: headline),
        ),
      ),
    );
  }
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
