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

  test('sync adapter reads live delayed multi-provider diagnostics', () {
    final response = SyncMarketCandidatesResponse.fromResult(
      {
        'sync_run_id': 'run-1',
        'provider': {
          'provider_name': 'alpha_vantage',
          'provider_status':
              'Provider live aktif dengan kontribusi multi-provider',
          'provider_mode': 'live',
        },
        'synced_symbols': [
          {'symbol_code': 'ASII', 'company_name': 'Astra'},
          {'symbol_code': 'BBCA', 'company_name': 'Bank Central Asia'},
        ],
        'synced_count': 5,
        'rows_inserted': 12,
        'live_symbol_count': 5,
        'fallback_symbol_count': 0,
        'live_symbols': ['ASII', 'BBCA', 'BBRI', 'TLKM', 'UNVR'],
        'fallback_symbols': [],
        'data_quality': 'delayed',
        'provider_status':
            'Provider live aktif dengan kontribusi multi-provider',
        'risk_warning': [
          {
            'level': 'low',
            'message':
                'Data provider bersifat delayed; gunakan sebagai konteks edukatif watchlist candidate.',
          },
        ],
      },
      {
        'data_quality': 'delayed',
        'provider_name': 'alpha_vantage',
        'provider_status':
            'Provider live aktif dengan kontribusi multi-provider',
        'provider_mode': 'live',
        'provider_diagnostics': {
          'selected_provider': 'mixed_live_providers',
          'fallback_provider_used': false,
          'provider_failover_reason': 'provider_chain_resolved',
          'secondary_provider_configured': true,
          'secondary_provider_name': 'twelve_data',
          'secondary_provider_host': 'api.twelvedata.com',
          'tertiary_provider_configured': true,
          'tertiary_provider_name': 'eodhd',
          'tertiary_provider_host': 'eodhd.com',
          'tertiary_provider_fallback_reason': 'none',
          'provider_attempts': [
            {
              'provider_name': 'alpha_vantage',
              'provider_role': 'primary',
              'provider_configured': true,
              'provider_status': 'selected',
              'data_quality': 'delayed',
            },
            {
              'provider_name': 'twelve_data',
              'provider_role': 'secondary',
              'provider_configured': true,
              'provider_status': 'selected',
              'data_quality': 'delayed',
            },
            {
              'provider_name': 'eodhd',
              'provider_role': 'tertiary',
              'provider_configured': true,
              'provider_status': 'selected',
              'data_quality': 'delayed',
            },
            {
              'provider_name': 'sample_provider',
              'provider_role': 'sample',
              'provider_configured': true,
              'provider_status': 'skipped',
              'data_quality': 'delayed',
            },
          ],
          'symbol_diagnostics': [
            {
              'requested_symbol': 'BBRI',
              'attempted_provider_symbols': ['BBRI', 'BBRI.JK'],
              'selected_provider_symbol': 'BBRI.JK',
              'fallback_reason': 'none',
            },
          ],
        },
      },
    );

    expect(response.isDelayedLive, isTrue);
    expect(response.isMultiProvider, isTrue);
    expect(response.hasFallbackSymbols, isFalse);
    expect(response.fallbackSymbolCount, 0);
    expect(response.meta.providerDiagnostics?.fallbackProviderUsed, isFalse);
    expect(response.meta.providerDiagnostics?.tertiaryProviderName, 'eodhd');
    expect(
      response.meta.providerDiagnostics?.providerAttempts.map(
        (attempt) => attempt.providerName,
      ),
      ['alpha_vantage', 'twelve_data', 'eodhd', 'sample_provider'],
    );
    expect(
      response
          .meta
          .providerDiagnostics
          ?.symbolDiagnostics
          .first
          .selectedProviderSymbol,
      'BBRI.JK',
    );
  });
}
