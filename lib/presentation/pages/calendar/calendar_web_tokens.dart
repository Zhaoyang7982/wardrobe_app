import 'package:flutter/material.dart';

/// PC Web 日历页（≥1280）视觉规范，与全局主题隔离。
abstract final class CalendarWebTokens {
  CalendarWebTokens._();

  static const double minWidth = 1280;

  static const Color purple = Color(0xFF7B61FF);
  static const Color purpleDark = Color(0xFF6A4DE2);
  static const Color bgTint = Color(0xFFF5F2FF);

  static const Color title = Color(0xFF333333);
  static const Color body = Color(0xFF666666);
  static const Color muted = Color(0xFF999999);
  static const Color border = Color(0xFFE5E5E5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outsideDay = Color(0xFFCCCCCC);

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

  static TextStyle text(double size, FontWeight w, Color c) => TextStyle(
        fontSize: size,
        fontWeight: w,
        color: c,
        height: 1.25,
        fontFamilyFallback: fontFamilyFallback,
      );
}
