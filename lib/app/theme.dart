import 'package:flutter/material.dart';

/// The single source of colours, type scale and component sizes.
/// Widgets use `Theme.of(context).textTheme.*` (copyWith only for colour or
/// weight); never a hard-coded `fontSize`.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF17537A);
  static const Color secondary = Color(0xFFA4552C);
  static const Color background = Color(0xFFF3F5F7);
  static const Color border = Color(0xFFE2E7EC);
  static const Color textStrong = Color(0xFF14212B);
  static const Color textMuted = Color(0xFF5B6B78); // 5.3:1 on white
  static const Color error = Color(0xFFB42318);

  static const double radius = 12;

  /// Standard button height.
  static const double controlHeight = 44;

  /// Full-width primary action (Login, Save).
  static const double primaryButtonHeight = 48;
  static const double inputHeight = 46;
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  static const double iconSize = 20;
  static const double smallIconSize = 18;

  /// Tamil glyphs have tall ascenders/descenders; this keeps them unclipped.
  static const double lineHeight = 1.35;
  static const List<String> _fontFallback = ['Noto Sans Tamil'];

  /// Upper/lower bounds for the system font-size setting.
  static const double minTextScale = 0.9;
  static const double maxTextScale = 1.15;

  static final BorderRadius _borderRadius = BorderRadius.circular(radius);

  static TextStyle _style(
    TextStyle? base,
    double size,
    FontWeight weight, [
    Color? color,
  ]) => (base ?? const TextStyle()).copyWith(
    fontSize: size,
    fontWeight: weight,
    height: lineHeight,
    letterSpacing: 0,
    fontFamilyFallback: _fontFallback,
    color: color,
  );

  static TextTheme _textTheme(TextTheme t) => t.copyWith(
    // Login brand title only; the one style above 18.
    headlineSmall: _style(t.headlineSmall, 22, FontWeight.w800),
    titleLarge: _style(t.titleLarge, 18, FontWeight.w700),
    titleMedium: _style(t.titleMedium, 16, FontWeight.w600),
    titleSmall: _style(t.titleSmall, 14, FontWeight.w600),
    bodyLarge: _style(t.bodyLarge, 14, FontWeight.w400),
    bodyMedium: _style(t.bodyMedium, 13, FontWeight.w400),
    bodySmall: _style(t.bodySmall, 12, FontWeight.w400, textMuted),
    labelLarge: _style(t.labelLarge, 14, FontWeight.w600),
    labelMedium: _style(t.labelMedium, 12, FontWeight.w600),
    labelSmall: _style(t.labelSmall, 11, FontWeight.w500),
  );

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
    );
    final text = _textTheme(
      ThemeData(useMaterial3: true, colorScheme: colorScheme).textTheme,
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = RoundedRectangleBorder(borderRadius: _borderRadius);
    const buttonSize = Size(64, controlHeight);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: text,
      scaffoldBackgroundColor: background,
      iconTheme: const IconThemeData(size: iconSize),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        toolbarHeight: 56,
        titleTextStyle: text.titleLarge?.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: iconSize),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
          size: iconSize,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? primary : textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : textMuted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: text.labelMedium,
        iconTheme: const IconThemeData(size: smallIconSize),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        constraints: const BoxConstraints(minHeight: inputHeight),
        contentPadding: inputPadding,
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.bodyMedium,
        hintStyle: text.bodyLarge?.copyWith(color: textMuted),
        errorStyle: text.bodySmall?.copyWith(color: colorScheme.error),
        border: border(Colors.grey.shade400),
        enabledBorder: border(Colors.grey.shade400),
        focusedBorder: border(primary, 2),
        errorBorder: border(colorScheme.error),
        focusedErrorBorder: border(colorScheme.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          iconSize: smallIconSize,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          iconSize: smallIconSize,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          iconSize: smallIconSize,
        ),
      ),
    );
  }

  /// Keeps the user's font-size setting within [minTextScale]..[maxTextScale]
  /// so layouts stay intact. Use as `MaterialApp.builder`.
  static Widget clampTextScale(BuildContext context, Widget? child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context)
            .clamp(minScaleFactor: minTextScale, maxScaleFactor: maxTextScale),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
