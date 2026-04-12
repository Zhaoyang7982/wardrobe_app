import 'package:flutter/material.dart';

/// Web 宽屏日历（≥ [CalendarWebStyle.minWidth]）的用色与字体栈。
///
/// 颜色取自 [ColorScheme]，随应用主题种子色 / 深浅色模式变化；不再写死紫色。
class CalendarWebStyle {
  CalendarWebStyle._({
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.bgTint,
    required this.title,
    required this.body,
    required this.muted,
    required this.border,
    required this.surface,
    required this.outsideDay,
    required this.onPrimary,
  });

  factory CalendarWebStyle.fromTheme(ThemeData theme) {
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final dark = theme.brightness == Brightness.dark;
    final hoverMod = dark ? Colors.white : Colors.black;
    final primaryHover = Color.alphaBlend(hoverMod.withValues(alpha: 0.10), primary);
    final primaryPressed = Color.alphaBlend(hoverMod.withValues(alpha: 0.18), primary);
    final bgTint = Color.alphaBlend(primary.withValues(alpha: 0.09), cs.surface);

    return CalendarWebStyle._(
      primary: primary,
      primaryHover: primaryHover,
      primaryPressed: primaryPressed,
      bgTint: bgTint,
      title: cs.onSurface,
      body: cs.onSurfaceVariant,
      muted: cs.outline,
      border: cs.outlineVariant,
      surface: cs.surface,
      outsideDay: cs.onSurface.withValues(alpha: 0.38),
      onPrimary: cs.onPrimary,
    );
  }

  static const double minWidth = 1280;

  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color bgTint;
  final Color title;
  final Color body;
  final Color muted;
  final Color border;
  final Color surface;
  final Color outsideDay;
  final Color onPrimary;

  /// 与需求文档一致的无衬线栈（Web 优先）
  static const List<String> fontFamilyFallback = [
    'system-ui',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'PingFang SC',
    'Microsoft YaHei',
    'sans-serif',
  ];

  TextStyle text(double size, FontWeight w, Color c) => TextStyle(
        fontSize: size,
        fontWeight: w,
        color: c,
        height: 1.25,
        fontFamilyFallback: fontFamilyFallback,
      );
}
