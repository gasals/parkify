import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Mobile test harness renders', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.shrink(),
    ));

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
