import 'package:flutter/material.dart';

/// Lurniq visual identity: warm, welcoming, modern. Material 3, original
/// palette — terracotta primary, deep-teal secondary, amber tertiary —
/// on warm paper (light) / warm charcoal (dark) backgrounds.
///
/// v2 design language: the palette is *owned* in both modes via signature
/// gradients (sunrise for day, ember-dusk for night), cards carry soft
/// depth, headers are expressive, and empty states use original vector
/// illustrations (see widgets/illustrations.dart) — never heavy bitmaps.
class AppTheme {
  static const _seed = Color(0xFFE8762D);
  static const primary = Color(0xFFC2571D);
  static const secondary = Color(0xFF0F766E);
  static const tertiary = Color(0xFFB45309);

  /// Signature gradient: sunrise (day) / ember dusk (night). Used for
  /// hero headers, primary CTAs accents, and brand moments.
  static LinearGradient heroGradient(Brightness brightness) =>
      brightness == Brightness.light
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8762D), Color(0xFFF5B04C)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0925C), Color(0xFF7C2D12)],
            );

  /// Soft wash behind section headers and empty states.
  static LinearGradient washGradient(Brightness brightness) =>
      brightness == Brightness.light
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE8762D).withValues(alpha: 0.14),
                const Color(0xFFE8762D).withValues(alpha: 0.0),
              ],
            )
          : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF0925C).withValues(alpha: 0.16),
                const Color(0xFFF0925C).withValues(alpha: 0.0),
              ],
            );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      tertiary: tertiary,
      surface: const Color(0xFFFFFBF4),
      surfaceContainerLow: const Color(0xFFFFF6EA),
      surfaceContainerHighest: const Color(0xFFF7EDE0),
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFF0925C),
      onPrimary: const Color(0xFF2A1408),
      secondary: const Color(0xFF5EC8BE),
      tertiary: const Color(0xFFF5B04C),
      surface: const Color(0xFF1C1512),
      onSurface: const Color(0xFFFFF3E8),
      onSurfaceVariant: const Color(0xFFE8D5C0),
      surfaceContainerLow: const Color(0xFF241C17),
      surfaceContainerHighest: const Color(0xFF332922),
      outlineVariant: const Color(0xFF5A4636),
    );
    return _base(scheme, dark: true);
  }

  static ThemeData _base(ColorScheme scheme, {bool dark = false}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: dark ? 0 : 2,
        shadowColor: dark
            ? Colors.transparent
            : const Color(0xFF7C2D12).withValues(alpha: 0.10),
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark
                ? scheme.outlineVariant.withValues(alpha: 0.7)
                : scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftFadeTransitionBuilder(),
          TargetPlatform.iOS: _SoftFadeTransitionBuilder(),
        },
      ),
    );
  }
}

/// Subtle shared-element-feel transition: quick fade + gentle scale.
/// Keeps navigation feeling alive without slowing the user down.
class _SoftFadeTransitionBuilder extends PageTransitionsBuilder {
  const _SoftFadeTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final scale = Tween<double>(begin: 0.98, end: 1.0).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}
