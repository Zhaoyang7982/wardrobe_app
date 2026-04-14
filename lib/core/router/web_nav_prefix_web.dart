import 'dart:html' as html;

/// 与 `index.html` 中 `<base href>` 一致，子路径部署时 GoRouter 须带此前缀才能匹配 `location.pathname`
String get webNavPathPrefix {
  final href = html.document.querySelector('base')?.getAttribute('href');
  if (href == null || href.isEmpty) return '';
  var normalized = href.trim();
  if (normalized == '/' || normalized.isEmpty) return '';
  if (!normalized.startsWith('/')) normalized = '/$normalized';
  if (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  if (normalized == '/') return '';
  return normalized;
}
