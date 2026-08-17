import 'package:flutter_test/flutter_test.dart';

import 'package:loto_inteligente/main.dart';

void main() {
  testWidgets(
    'Loto Inteligente abre corretamente',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const LotoInteligenteApp(),
      );

      expect(
        find.text('Olá! 👋'),
        findsOneWidget,
      );

      expect(
        find.text('Bem-vindo ao Loto Inteligente.'),
        findsOneWidget,
      );
    },
  );
}
