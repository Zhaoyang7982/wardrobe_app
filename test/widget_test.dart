import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wardrobe_app/main.dart';

void main() {
  testWidgets('应用显示衣橱标题文案', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WardrobeApp()));

    expect(find.text('衣橱'), findsOneWidget);
  });
}
