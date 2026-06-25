import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app_config.dart';
import 'package:mobile/app/stock_ai_app.dart';
import 'package:mobile/design_system/ui_components.dart';
import 'package:mobile/core/models/market_data_models.dart';
import 'package:mobile/features/alerts/alert_screen.dart';
import 'package:mobile/features/chart_lab/chart_lab_screen.dart';
import 'package:mobile/features/stock_detail/stock_detail_screen.dart';

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

  test('ui helpers format severity, provider labels, and WIB timestamps', () {
    expect(riskSeverityBand('low'), 'low');
    expect(riskSeverityBand('medium'), 'medium');
    expect(riskSeverityBand('high'), 'high');
    expect(riskSeverityBand('error'), 'high');
    expect(humanizeUiText('Delayed Live Data'), 'Delayed provider-backed data');
    expect(
      formatWibTimestamp('2026-06-25T12:58:00Z'),
      '25 Jun 2026, 19:58 WIB',
    );
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

  test('market context adapter reads delayed live provider-backed state', () {
    final response = MarketContextResponse.fromResult(
      {
        'market_context': {
          'market_code': 'IDX',
          'index_symbol': 'IHSG',
          'market_status': 'Provider-backed watchlist context',
          'index_trend': 'Provider-backed watchlist context',
          'risk_regime': 'Risk-aware delayed context',
          'data_quality': 'delayed',
          'is_stale': false,
          'risk_warning': [
            {
              'level': 'low',
              'message':
                  'Data provider bersifat delayed; gunakan sebagai konteks edukatif watchlist candidate.',
            },
          ],
        },
        'provider': {
          'provider_name': 'mixed_live_providers',
          'provider_status':
              'Provider live aktif dengan kontribusi multi-provider',
          'provider_mode': 'live',
          'data_quality': 'delayed',
        },
        'cache': {
          'allow_stale': true,
          'stale_blocked': false,
          'ttl_seconds': 900,
        },
        'disclaimer': 'Edukasi watchlist context.',
      },
      {
        'data_quality': 'delayed',
        'provider_name': 'mixed_live_providers',
        'provider_status':
            'Provider live aktif dengan kontribusi multi-provider',
        'provider_mode': 'live',
      },
    );

    expect(response.marketContext.isDelayed, isTrue);
    expect(response.marketContext.isLiveBacked, isTrue);
    expect(response.marketContext.isSample, isFalse);
    expect(response.marketContext.isStale, isFalse);
    expect(response.meta.isDelayedLive, isTrue);
    expect(response.provider.providerName, 'mixed_live_providers');
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

  test('OHLCV adapter reads provider-backed chart data', () {
    final response = StockChartDataResponse.fromResult(
      {
        'chart': {
          'symbol_code': 'BBCA',
          'timeframe': '1d',
          'data_quality': 'delayed',
          'bars': [
            {
              'symbol_code': 'BBCA',
              'timeframe': '1d',
              'observed_at': '2026-06-25T12:58:00Z',
              'open': 9000,
              'high': 9300,
              'low': 8900,
              'close': 9200,
              'volume': 1200000,
              'data_quality': 'delayed',
              'provider_name': 'eodhd',
            },
          ],
        },
        'provider': {
          'provider_name': 'eodhd',
          'provider_status': 'Provider-backed delayed OHLCV cache tersedia',
          'data_quality': 'delayed',
        },
        'risk_warning': [
          {'level': 'low', 'message': 'Delayed provider-backed data.'},
        ],
        'disclaimer': 'Chart edukatif.',
      },
      {
        'data_quality': 'delayed',
        'provider_name': 'eodhd',
        'provider_mode': 'live',
      },
    );

    expect(response.symbolCode, 'BBCA');
    expect(response.hasBars, isTrue);
    expect(response.isDelayedProviderBacked, isTrue);
    expect(response.bars.first.close, 9200);
    expect(response.riskWarnings.first.level, 'low');
  });

  testWidgets('chart lab copy reflects provider-backed preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartLabScreen(autoLoad: false))),
    );

    expect(
      find.textContaining('Provider-backed delayed OHLCV data'),
      findsWidgets,
    );
    expect(find.textContaining('OHLCV cache belum tersedia'), findsOneWidget);
  });

  testWidgets('chart lab renders provider-backed OHLCV state', (tester) async {
    final response = StockChartDataResponse.fromResult(
      {
        'chart': {
          'symbol_code': 'BBCA',
          'timeframe': '1d',
          'data_quality': 'delayed',
          'bars': [
            {
              'symbol_code': 'BBCA',
              'timeframe': '1d',
              'observed_at': '2026-06-24T12:00:00Z',
              'open': 9000,
              'high': 9250,
              'low': 8950,
              'close': 9100,
              'volume': 1000000,
              'data_quality': 'delayed',
              'provider_name': 'eodhd',
            },
            {
              'symbol_code': 'BBCA',
              'timeframe': '1d',
              'observed_at': '2026-06-25T12:00:00Z',
              'open': 9100,
              'high': 9400,
              'low': 9050,
              'close': 9350,
              'volume': 1300000,
              'data_quality': 'delayed',
              'provider_name': 'eodhd',
            },
          ],
        },
        'provider': {
          'provider_name': 'eodhd',
          'provider_status': 'Provider-backed delayed OHLCV cache tersedia',
          'data_quality': 'delayed',
        },
        'disclaimer': 'Chart edukatif.',
      },
      {'data_quality': 'delayed', 'provider_name': 'eodhd'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartLabScreen(initialChartData: response, autoLoad: false),
        ),
      ),
    );

    expect(find.text('BBCA OHLCV'), findsOneWidget);
    expect(find.text('2 OHLCV bars'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('9350'), findsOneWidget);
  });

  testWidgets('stock detail copy uses delayed provider context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: StockDetailScreen(
          item: {
            'symbol_code': 'BBRI',
            'symbols': {'company_name': 'Bank Rakyat Indonesia'},
            'latest_score': {
              'overall_score': 72,
              'technical_score': 70,
              'harmony_score': 66,
              'fundamental_score': 74,
              'risk_score': 61,
              'liquidity_score': 80,
              'candidate_label': 'watchlist candidate',
              'rule_version': 'p0_dummy_scoring_v1',
            },
          },
        ),
      ),
    );

    expect(
      find.textContaining(
        'Market data P2 tersedia sebagai provider-backed delayed context.',
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Rule scoring awal menjadi sumber utama'),
      findsWidgets,
    );
  });
}
