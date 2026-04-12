/// 应用级全局常量（与主题无关的通用配置）。
abstract final class AppConstants {
  AppConstants._();

  /// 对外展示的产品名称
  static const String appName = 'AI衣橱助手';

  /// MaterialApp.title 等简短标题
  static const String appTitleShort = '衣橱';

  /// 列表等默认一页条数（可按接口再调整）
  static const int defaultPageSize = 20;

  /// 网络请求默认超时
  static const Duration networkTimeout = Duration(seconds: 30);

  /// 短动画时长（按钮、开关反馈等）
  static const Duration animationShort = Duration(milliseconds: 200);

  /// 标准动画时长（页面过渡等）
  static const Duration animationMedium = Duration(milliseconds: 300);

  /// 可点击区域最小尺寸（Material 建议）
  static const double minTouchTarget = 48;

  /// 宽屏布局：窗口宽度 ≥ 此值时使用左侧导航 Rail（与衣橱四列对齐）
  static const double layoutDesktopMinWidth = 900;

  /// 中等宽度：衣橱网格 ≥ 此值且 < [layoutDesktopMinWidth] 时为 3 列
  static const double layoutTabletMinWidth = 600;
}
