import 'package:flutter/material.dart';

import '../utils/app_design_tokens.dart';

enum CustomerMobileTab { home, products, cart, results }

class MobileScreenScaffold extends StatelessWidget {
  const MobileScreenScaffold({
    required this.title,
    required this.body,
    this.showBackButton = false,
    this.onBack,
    this.currentTab,
    this.onTabSelected,
    super.key,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final VoidCallback? onBack;
  final CustomerMobileTab? currentTab;
  final ValueChanged<CustomerMobileTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final Widget content = ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _MobileTopBar(
              title: title,
              showBackButton: showBackButton,
              onBack: onBack,
            ),
            Expanded(child: body),
            if (currentTab != null && onTabSelected != null)
              _MobileBottomNavigation(
                currentTab: currentTab!,
                onTabSelected: onTabSelected!,
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.mobileContentMaxWidth,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.title,
    required this.showBackButton,
    this.onBack,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: AppBorders.subtle),
      ),
      child: SizedBox(
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (showBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: '뒤로',
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.currentTab,
    required this.onTabSelected,
  });

  final CustomerMobileTab currentTab;
  final ValueChanged<CustomerMobileTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(top: AppBorders.subtle)),
      child: NavigationBar(
        height: 64,
        selectedIndex: currentTab.index,
        onDestinationSelected: (int index) {
          onTabSelected(CustomerMobileTab.values[index]);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: '제품',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: '장바구니',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '상담 결과',
          ),
        ],
      ),
    );
  }
}
