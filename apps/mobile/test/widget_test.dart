import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_config.dart';
import 'package:mobile/app/stock_ai_app.dart';
import 'package:mobile/design_system/ui_components.dart';
import 'package:mobile/features/alerts/alert_screen.dart';

void main() {
  testWidgets('shows missing Supabase config state', (tester) async {
    await tester.pumpWidget(
      const StockAiApp(
        config: AppConfig(supabaseUrl: '', supabaseAnonKey: ''),
      ),
    );

    expect(find.text('Supabase env belum diisi'), findsOneWidget);
  });

  testWidgets('smart alert form uses safe default scenario', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AlertScreen())),
    );

    expect(find.text('Smart Alert'), findsOneWidget);
    expect(find.text('BBCA'), findsOneWidget);
    expect(find.text('BBCA risk warning watch'), findsOneWidget);
    expect(find.text('risk warning'), findsWidgets);
    expect(find.text('Risk'), findsOneWidget);
    expect(find.text('<'), findsOneWidget);
    expect(find.text('55'), findsOneWidget);
  });

  testWidgets('score pill shows waiting copy for missing data', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ScorePill(label: 'Final', value: null)),
      ),
    );

    expect(find.text('Final Menunggu data'), findsOneWidget);
  });
}
