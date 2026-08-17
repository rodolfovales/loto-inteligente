import 'package:flutter_test/flutter_test.dart';
import 'package:loto_inteligente/main.dart';

void main() {
  testWidgets(
    'Loto Inteligente inicia corretamente',
    (tester) async {
      await tester.pumpWidget(
        const LotoInteligenteApp(),
      );

      expect(
        find.text('Loto Inteligente'),
        findsOneWidget,
      );
    },
  );
}
