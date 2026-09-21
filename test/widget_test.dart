import 'package:flutter_test/flutter_test.dart';

import 'package:ballmatrix/main.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const BallMatrixApp());
    await tester.pumpAndSettle();
    expect(find.text('绿场智算'), findsOneWidget);
  });
}