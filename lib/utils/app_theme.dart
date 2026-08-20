import 'package:flutter/material.dart';

import 'app_design_tokens.dart';

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

abstract final class SegueTheme {
  static const String englishFontFamily = 'Montserrat';
  static const String koreanFontFamily = 'Pretendard';
  static const List<String> _fontFamilyFallback = <String>[koreanFontFamily];

  static ThemeData light() {
    final ThemeData base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
      ),
      fontFamily: englishFontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      splashFactory: InkRipple.splashFactory,
      useMaterial3: true,
    );

    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _NoAnimationPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(base.textTheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.surface,
          // A finite minimum width (not Size.fromHeight's implicit infinite
          // width) so buttons placed in unbounded-width contexts (Align,
          // Wrap, a header row) still lay out; screens that want a
          // full-width button opt in explicitly via SizedBox(width: double.infinity).
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: _fontStyle(const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          side: AppBorders.subtle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: _fontStyle(const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: AppBorders.subtle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: AppBorders.subtle,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: AppBorders.focused,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: AppBorders.danger,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: AppBorders.subtle,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        iconColor: AppColors.ink,
        textColor: AppColors.ink,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: _fontStyle(
          base.textTheme.bodyMedium,
        )?.copyWith(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );
  }

  static TextStyle? _fontStyle(TextStyle? style) {
    final FontWeight requestedWeight = style?.fontWeight ?? FontWeight.w500;
    final double visualWeight = ((((requestedWeight.index + 1) * 100) + 120)
        .clamp(650, 900)
        .toDouble());

    return style?.copyWith(
      fontFamily: englishFontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      fontVariations: <FontVariation>[FontVariation('wght', visualWeight)],
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: _fontStyle(base.headlineMedium)?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: _fontStyle(base.titleLarge)?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleMedium: _fontStyle(base.titleMedium)?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyMedium: _fontStyle(
        base.bodyMedium,
      )?.copyWith(color: AppColors.mutedInk, height: 1.4, letterSpacing: 0),
      bodySmall: _fontStyle(
        base.bodySmall,
      )?.copyWith(color: AppColors.subtleInk, letterSpacing: 0),
      labelLarge: _fontStyle(base.labelLarge)?.copyWith(
        color: AppColors.subtleInk,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}
