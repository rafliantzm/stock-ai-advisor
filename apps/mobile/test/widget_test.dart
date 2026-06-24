import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_config.dart';
import 'package:mobile/app/stock_ai_app.dart';
import 'package:mobile/design_system/ui_components.dart';
import 'package:mobile/core/models/market_data_models.dart';
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

  test('market context adapter reads P2 response contract', () {
    final response = MarketContextResponse.fromResult(
      {
        'market_context': {
          'market_code': 'IDX',
          'index_symbol': 'IHSG',
          'market_status': 'provider belum aktif',
          'index_trend': 'needs_more_data',
          'risk_regime': 'needs_more_data',
          'data_quality': 'sample',
          'is_stale': true,
          'risk_warning': [
            {'level': 'medium', 'message': 'sample data'},
          ],
        },
        'provider': {
          'provider_name': 'sample_provider',
          'provider_status': 'provider belum aktif',
        },
        'cache': {
          'allow_stale': true,
          'stale_blocked': false,
          'ttl_seconds': 900,
        },
        'disclaimer': 'Edukasi.',
      },
      {
        'data_quality': 'sample',
        'provider_name': 'sample_provider',
        'provider_status': 'provider belum aktif',
      },
    );

    expect(response.marketContext.marketCode, 'IDX');
    expect(response.marketContext.isSample, isTrue);
    expect(response.marketContext.isStale, isTrue);
    expect(response.marketContext.riskWarnings.first.level, 'medium');
    expect(response.provider.providerName, 'sample_provider');
    expect(response.cache.ttlSeconds, 900);
  });
}
