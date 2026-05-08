import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:asistente_dibujo_ia/app.dart';
import 'package:asistente_dibujo_ia/estado_app.dart';

void main() {
  testWidgets('La app arranca correctamente', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => EstadoApp(), child: const App()),
    );
    expect(find.text('Asistente de dibujo IA'), findsOneWidget);
  });
}
