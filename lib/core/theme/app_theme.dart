import 'package:flutter/material.dart';

/// 应用主题：Material 3，浅色底与表面轻微混入种子色（马卡龙感），深色为暖调底 + 种子微染。
abstract final class AppTheme {
  AppTheme._();

  // --- 字体尺寸（逻辑像素，用于 TextStyle.fontSize）---

  static const double fontSizeDisplay = 36;
  static const double fontSizeHeadline = 28;
  static const double fontSizeTitleLarge = 22;
  static const double fontSizeTitle = 18;
  static const double fontSizeBodyLarge = 16;
  static const double fontSizeBody = 14;
  static const double fontSizeLabel = 12;
  static const double fontSizeLabelSmall = 11;

  /// 横向筛选 Chip（搭配页场合/季节、衣橱页类别等）统一标签：字号与行高一致，单字与双字视觉对齐。
  static const StrutStyle filterChipStrutStyle = StrutStyle(
    fontSize: fontSizeLabel,
    height: 1.25,
    leadingDistribution: TextLeadingDistribution.even,
    forceStrutHeight: true,
  );

  /// 不指定 [TextStyle.color]，便于选中态由 Chip 继承主题强调色。
  static const TextStyle filterChipLabelTextStyle = TextStyle(
    fontSize: fontSizeLabel,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  static Widget filterChipLabel(String text) => Text(
        text,
        strutStyle: filterChipStrutStyle,
        style: filterChipLabelTextStyle,
      );

  // --- 间距 ---

  static const double spaceXxs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // --- 圆角 ---

  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  /// 默认浅色种子（马卡龙薄荷，与 [kDefaultAccentArgb] 一致）
  static const Color _seedLight = Color(0xFF8FE5D0);
  static const Color _seedDark = Color(0xFFB8F0E0);

  /// 浅色中性底（未混色前）
  static const Color _canvasLight = Color(0xFFFFFCFA);
  static const Color _containerLowLight = Color(0xFFF8F4F2);
  static const Color _containerLight = Color(0xFFF2EDE9);
  static const Color _containerHighLight = Color(0xFFEAE4DF);
  static const Color _containerHighestLight = Color(0xFFE0D9D3);

  /// 深色中性底
  static const Color _surfaceDark = Color(0xFF1A1814);
  static const Color _containerLowestDark = Color(0xFF141210);
  static const Color _containerLowDark = Color(0xFF1E1C18);
  static const Color _containerDark = Color(0xFF26231E);
  static const Color _containerHighDark = Color(0xFF322E28);
  static const Color _containerHighestDark = Color(0xFF3D3832);

  /// 在浅色底上叠一层很淡的 [flavor]，让背景随主题色轻微偏色
  static Color _washLight(Color canvas, Color flavor, double alpha) {
    return Color.alphaBlend(flavor.withValues(alpha: alpha.clamp(0, 1)), canvas);
  }

  /// 深色表面微染种子色
  static Color _washDark(Color surface, Color flavor, double alpha) {
    return Color.alphaBlend(flavor.withValues(alpha: alpha.clamp(0, 1)), surface);
  }

  static ThemeData get light => lightWithSeed(_seedLight);

  static ThemeData get dark => darkWithSeed(_seedDark);

  /// 浅色：primary 等由 [seed] 生成，表面层在米白底上轻混种子色
  static ThemeData lightWithSeed(Color seed) {
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      surface: _washLight(_canvasLight, seed, 0.10),
      surfaceContainerLowest: _washLight(_canvasLight, seed, 0.08),
      surfaceContainerLow: _washLight(_containerLowLight, seed, 0.11),
      surfaceContainer: _washLight(_containerLight, seed, 0.12),
      surfaceContainerHigh: _washLight(_containerHighLight, seed, 0.13),
      surfaceContainerHighest: _washLight(_containerHighestLight, seed, 0.14),
    );
    return _buildTheme(scheme, Brightness.light);
  }

  /// 深色：略提亮种子后生成色阶，表面层轻混种子色相
  static ThemeData darkWithSeed(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    final darkSeed = hsl
        .withLightness((hsl.lightness + 0.18).clamp(0.45, 0.82))
        .withSaturation((hsl.saturation * 0.95).clamp(0.2, 1.0))
        .toColor();
    final base = ColorScheme.fromSeed(
      seedColor: darkSeed,
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      surface: _washDark(_surfaceDark, darkSeed, 0.10),
      surfaceContainerLowest: _washDark(_containerLowestDark, darkSeed, 0.09),
      surfaceContainerLow: _washDark(_containerLowDark, darkSeed, 0.10),
      surfaceContainer: _washDark(_containerDark, darkSeed, 0.11),
      surfaceContainerHigh: _washDark(_containerHighDark, darkSeed, 0.12),
      surfaceContainerHighest: _washDark(_containerHighestDark, darkSeed, 0.13),
    );
    return _buildTheme(scheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceXs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: fontSizeLabelSmall,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        showCheckmark: true,
        selectedColor: scheme.surfaceContainerHighest,
        checkmarkColor: scheme.primary,
        labelStyle: filterChipLabelTextStyle.copyWith(color: scheme.onSurface),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;

    TextStyle baseStyle(double size, FontWeight weight) => TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: onSurface,
          height: 1.35,
        );

    return TextTheme(
      displayLarge: baseStyle(fontSizeDisplay, FontWeight.w400),
      displayMedium: baseStyle(32, FontWeight.w400),
      displaySmall: baseStyle(28, FontWeight.w500),
      headlineLarge: baseStyle(fontSizeHeadline, FontWeight.w500),
      headlineMedium: baseStyle(24, FontWeight.w500),
      headlineSmall: baseStyle(fontSizeTitleLarge, FontWeight.w600),
      titleLarge: baseStyle(fontSizeTitleLarge, FontWeight.w600),
      titleMedium: baseStyle(fontSizeTitle, FontWeight.w600),
      titleSmall: baseStyle(fontSizeBodyLarge, FontWeight.w600),
      bodyLarge: baseStyle(fontSizeBodyLarge, FontWeight.w400),
      bodyMedium: baseStyle(fontSizeBody, FontWeight.w400),
      bodySmall: baseStyle(fontSizeLabel, FontWeight.w400),
      labelLarge: baseStyle(fontSizeBodyLarge, FontWeight.w600),
      labelMedium: baseStyle(fontSizeLabel, FontWeight.w500),
      labelSmall: baseStyle(fontSizeLabelSmall, FontWeight.w500),
    );
  }
}
