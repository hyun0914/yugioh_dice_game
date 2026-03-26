import 'package:flutter_test/flutter_test.dart';
import 'package:yugioh_dice_game/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const YugiohDiceApp());
    expect(find.text('DD 시작'), findsOneWidget);
  });
}
