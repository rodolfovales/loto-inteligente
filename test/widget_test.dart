import 'package:flutter_test/flutter_test.dart';
import 'package:loto_inteligente/main.dart';

void main() {
  testWidgets(
    'Loto Inteligente abre corretamente',
    (tester) async {
      await tester.pumpWidget(
        const LotoInteligenteApp(),
      );

      expect(
        find.byType(LotoInteligenteApp),
        findsOneWidget,
      );

      expect(
        find.text('Olá! 👋'),
        findsOneWidget,
      );
    },
  );
}
