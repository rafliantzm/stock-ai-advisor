import '../utils/map_utils.dart';
import 'analysis_models.dart';

class ProviderInfo {
  const ProviderInfo({
    required this.providerName,
    required this.providerStatus,
    this.providerType,
    this.providerMode,
    this.status,
  });

  factory ProviderInfo.fromMap(Map<String, dynamic> map) {
    return ProviderInfo(
      providerName: map['provider_name']?.toString() ?? 'sample_provider',
      providerStatus:
          map['provider_status']?.toString() ??
          map['status']?.toString() ??
          'provider belum aktif',
      providerType: map['provider_type']?.toString(),
      providerMode: map['provider_mode']?.toString(),
      status: map['status']?.toString(),
    );
  }

  final String providerName;
  final String providerStatus;
  final String? providerType;
  final String? providerMode;
  final String? status;
}

class SyncedSymbol {
  const SyncedSymbol({
    required this.symbolCode,
    required this.companyName,
    this.symbolId,
  });

  factory SyncedSymbol.fromMap(Map<String, dynamic> map) {
    return SyncedSymbol(
      symbolId: map['symbol_id']?.toString(),
      symbolCode: map['symbol_code']?.toString() ?? '-',
      companyName: map['company_name']?.toString() ?? 'Company pending',
    );
  }

  final String? symbolId;
  final String symbolCode;
  final String companyName;
}

class MarketContextData {
  const MarketContextData({
    required this.marketCode,
    required this.indexSymbol,
    required this.marketStatus,
    required this.indexTrend,
    required this.riskRegime,
    required this.dataQuality,
    required this.isStale,
    required this.riskWarnings,
    this.indexLast,
    this.indexChange,
    this.indexChangePercent,
    this.lastUpdated,
    this.stalenessWarning,
  });

  factory MarketContextData.fromMap(Map<String, dynamic> map) {
    return MarketContextData(
      marketCode: map['market_code']?.toString() ?? 'IDX',
      indexSymbol: map['index_symbol']?.toString() ?? 'IHSG',
      marketStatus: map['market_status']?.toString() ?? 'provider belum aktif',
      indexTrend: map['index_trend']?.toString() ?? 'needs_more_data',
      riskRegime: map['risk_regime']?.toString() ?? 'needs_more_data',
      indexLast: map['index_last'],
      indexChange: map['index_change'],
      indexChangePercent: map['index_change_percent'],
      lastUpdated: map['last_updated']?.toString(),
      dataQuality: map['data_quality']?.toString() ?? 'sample',
      isStale: map['is_stale'] == true,
      stalenessWarning: map['staleness_warning']?.toString(),
      riskWarnings: (map['risk_warning'] is List)
          ? (map['risk_warning'] as List).map(RiskWarning.fromObject).toList()
          : const [],
    );
  }

  final String marketCode;
  final String indexSymbol;
  final String marketStatus;
  final String indexTrend;
  final String riskRegime;
  final Object? indexLast;
  final Object? indexChange;
  final Object? indexChangePercent;
  final String? lastUpdated;
  final String dataQuality;
  final bool isStale;
  final String? stalenessWarning;
  final List<RiskWarning> riskWarnings;

  bool get isSample => dataQuality == 'sample';
  bool get isDelayed => dataQuality == 'delayed';
  bool get isLiveBacked =>
      dataQuality == 'live' ||
      dataQuality == 'delayed' ||
      dataQuality == 'production';
}

class MarketCacheInfo {
  const MarketCacheInfo({
    required this.allowStale,
    required this.staleBlocked,
    required this.ttlSeconds,
  });

  factory MarketCacheInfo.fromMap(Map<String, dynamic> map) {
    return MarketCacheInfo(
      allowStale: map['allow_stale'] == true,
      staleBlocked: map['stale_blocked'] == true,
      ttlSeconds: _intFromObject(map['ttl_seconds']),
    );
  }

  final bool allowStale;
  final bool staleBlocked;
  final int? ttlSeconds;

  static int? _intFromObject(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class MarketDataMeta {
  const MarketDataMeta({
    required this.dataQuality,
    required this.providerName,
    required this.providerStatus,
    this.providerMode,
    this.ruleVersion,
    this.providerDiagnostics,
  });

  factory MarketDataMeta.fromMap(Map<String, dynamic> map) {
    return MarketDataMeta(
      dataQuality: map['data_quality']?.toString() ?? 'sample',
      providerName: map['provider_name']?.toString() ?? 'sample_provider',
      providerStatus:
          map['provider_status']?.toString() ?? 'provider belum aktif',
      providerMode: map['provider_mode']?.toString(),
      ruleVersion: map['rule_version']?.toString(),
      providerDiagnostics: map['provider_diagnostics'] is Map
          ? ProviderDiagnostics.fromMap(
              asStringMap(map['provider_diagnostics']),
            )
          : null,
    );
  }

  final String dataQuality;
  final String providerName;
  final String providerStatus;
  final String? providerMode;
  final String? ruleVersion;
  final ProviderDiagnostics? providerDiagnostics;

  bool get isDelayedLive => providerMode == 'live' && dataQuality == 'delayed';
  bool get isLiveMode => providerMode == 'live';
  bool get isSample => dataQuality == 'sample';
  bool get isStale => dataQuality == 'stale';
}

class ProviderDiagnostics {
  const ProviderDiagnostics({
    this.selectedProvider,
    required this.fallbackProviderUsed,
    this.providerFailoverReason,
    required this.secondaryProviderConfigured,
    this.secondaryProviderName,
    this.secondaryProviderHost,
    required this.tertiaryProviderConfigured,
    this.tertiaryProviderName,
    this.tertiaryProviderHost,
    this.tertiaryProviderFallbackReason,
    required this.providerAttempts,
    required this.symbolDiagnostics,
  });

  factory ProviderDiagnostics.fromMap(Map<String, dynamic> map) {
    return ProviderDiagnostics(
      selectedProvider: map['selected_provider']?.toString(),
      fallbackProviderUsed: map['fallback_provider_used'] == true,
      providerFailoverReason: map['provider_failover_reason']?.toString(),
      secondaryProviderConfigured: map['secondary_provider_configured'] == true,
      secondaryProviderName: map['secondary_provider_name']?.toString(),
      secondaryProviderHost: map['secondary_provider_host']?.toString(),
      tertiaryProviderConfigured: map['tertiary_provider_configured'] == true,
      tertiaryProviderName: map['tertiary_provider_name']?.toString(),
      tertiaryProviderHost: map['tertiary_provider_host']?.toString(),
      tertiaryProviderFallbackReason: map['tertiary_provider_fallback_reason']
          ?.toString(),
      providerAttempts: asMapList(
        map['provider_attempts'],
      ).map(ProviderAttempt.fromMap).toList(),
      symbolDiagnostics: asMapList(
        map['symbol_diagnostics'],
      ).map(ProviderSymbolDiagnostic.fromMap).toList(),
    );
  }

  final String? selectedProvider;
  final bool fallbackProviderUsed;
  final String? providerFailoverReason;
  final bool secondaryProviderConfigured;
  final String? secondaryProviderName;
  final String? secondaryProviderHost;
  final bool tertiaryProviderConfigured;
  final String? tertiaryProviderName;
  final String? tertiaryProviderHost;
  final String? tertiaryProviderFallbackReason;
  final List<ProviderAttempt> providerAttempts;
  final List<ProviderSymbolDiagnostic> symbolDiagnostics;

  bool get isMultiProvider => selectedProvider == 'mixed_live_providers';
}

class ProviderAttempt {
  const ProviderAttempt({
    required this.providerName,
    required this.providerRole,
    required this.providerConfigured,
    required this.providerStatus,
    required this.dataQuality,
    this.fallbackReason,
  });

  factory ProviderAttempt.fromMap(Map<String, dynamic> map) {
    return ProviderAttempt(
      providerName: map['provider_name']?.toString() ?? '-',
      providerRole: map['provider_role']?.toString() ?? '-',
      providerConfigured: map['provider_configured'] == true,
      providerStatus: map['provider_status']?.toString() ?? '-',
      dataQuality: map['data_quality']?.toString() ?? '-',
      fallbackReason: map['fallback_reason']?.toString(),
    );
  }

  final String providerName;
  final String providerRole;
  final bool providerConfigured;
  final String providerStatus;
  final String dataQuality;
  final String? fallbackReason;
}

class ProviderSymbolDiagnostic {
  const ProviderSymbolDiagnostic({
    required this.requestedSymbol,
    required this.attemptedProviderSymbols,
    this.selectedProviderSymbol,
    this.fallbackReason,
  });

  factory ProviderSymbolDiagnostic.fromMap(Map<String, dynamic> map) {
    final attempted = map['attempted_provider_symbols'];
    return ProviderSymbolDiagnostic(
      requestedSymbol: map['requested_symbol']?.toString() ?? '-',
      attemptedProviderSymbols: attempted is List
          ? attempted.map((item) => item.toString()).toList()
          : const [],
      selectedProviderSymbol: map['selected_provider_symbol']?.toString(),
      fallbackReason: map['fallback_reason']?.toString(),
    );
  }

  final String requestedSymbol;
  final List<String> attemptedProviderSymbols;
  final String? selectedProviderSymbol;
  final String? fallbackReason;
}

class MarketContextResponse {
  const MarketContextResponse({
    required this.marketContext,
    required this.provider,
    required this.cache,
    required this.meta,
    required this.disclaimer,
  });

  factory MarketContextResponse.fromResult(
    Map<String, dynamic> data,
    Map<String, dynamic> meta,
  ) {
    return MarketContextResponse(
      marketContext: MarketContextData.fromMap(
        asStringMap(data['market_context']),
      ),
      provider: ProviderInfo.fromMap(asStringMap(data['provider'])),
      cache: MarketCacheInfo.fromMap(asStringMap(data['cache'])),
      meta: MarketDataMeta.fromMap(meta),
      disclaimer:
          data['disclaimer']?.toString() ??
          'Data market context bersifat edukatif.',
    );
  }

  final MarketContextData marketContext;
  final ProviderInfo provider;
  final MarketCacheInfo cache;
  final MarketDataMeta meta;
  final String disclaimer;
}

class SyncMarketCandidatesResponse {
  const SyncMarketCandidatesResponse({
    required this.syncRunId,
    required this.provider,
    required this.syncedSymbols,
    required this.syncedCount,
    required this.rowsInserted,
    required this.liveSymbolCount,
    required this.fallbackSymbolCount,
    required this.liveSymbols,
    required this.fallbackSymbols,
    required this.dataQuality,
    required this.providerStatus,
    required this.riskWarnings,
    required this.meta,
  });

  factory SyncMarketCandidatesResponse.fromResult(
    Map<String, dynamic> data,
    Map<String, dynamic> meta,
  ) {
    return SyncMarketCandidatesResponse(
      syncRunId: data['sync_run_id']?.toString(),
      provider: ProviderInfo.fromMap(asStringMap(data['provider'])),
      syncedSymbols: asMapList(
        data['synced_symbols'],
      ).map(SyncedSymbol.fromMap).toList(),
      syncedCount: _intFromObject(data['synced_count']) ?? 0,
      rowsInserted: _intFromObject(data['rows_inserted']) ?? 0,
      liveSymbolCount:
          _intFromObject(
            data['live_symbol_count'] ?? meta['live_symbol_count'],
          ) ??
          0,
      fallbackSymbolCount:
          _intFromObject(
            data['fallback_symbol_count'] ?? meta['fallback_symbol_count'],
          ) ??
          0,
      liveSymbols: _stringList(data['live_symbols'] ?? meta['live_symbols']),
      fallbackSymbols: _stringList(
        data['fallback_symbols'] ?? meta['fallback_symbols'],
      ),
      dataQuality: data['data_quality']?.toString() ?? 'sample',
      providerStatus:
          data['provider_status']?.toString() ?? 'provider belum aktif',
      riskWarnings: (data['risk_warning'] is List)
          ? (data['risk_warning'] as List).map(RiskWarning.fromObject).toList()
          : const [],
      meta: MarketDataMeta.fromMap(meta),
    );
  }

  final String? syncRunId;
  final ProviderInfo provider;
  final List<SyncedSymbol> syncedSymbols;
  final int syncedCount;
  final int rowsInserted;
  final int liveSymbolCount;
  final int fallbackSymbolCount;
  final List<String> liveSymbols;
  final List<String> fallbackSymbols;
  final String dataQuality;
  final String providerStatus;
  final List<RiskWarning> riskWarnings;
  final MarketDataMeta meta;

  bool get hasFallbackSymbols =>
      fallbackSymbolCount > 0 || fallbackSymbols.isNotEmpty;

  bool get isDelayedLive =>
      meta.providerMode == 'live' && dataQuality == 'delayed';

  bool get isMultiProvider => meta.providerDiagnostics?.isMultiProvider == true;

  static int? _intFromObject(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}

class OhlcvBar {
  const OhlcvBar({
    required this.symbolCode,
    required this.timeframe,
    required this.observedAt,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.dataQuality,
    required this.providerName,
    this.volume,
  });

  factory OhlcvBar.fromMap(Map<String, dynamic> map) {
    return OhlcvBar(
      symbolCode: map['symbol_code']?.toString() ?? '-',
      timeframe: map['timeframe']?.toString() ?? '1d',
      observedAt: map['observed_at']?.toString() ?? '-',
      open: _numFromObject(map['open'] ?? map['open_price']) ?? 0,
      high: _numFromObject(map['high'] ?? map['high_price']) ?? 0,
      low: _numFromObject(map['low'] ?? map['low_price']) ?? 0,
      close: _numFromObject(map['close'] ?? map['close_price']) ?? 0,
      volume: _numFromObject(map['volume']),
      dataQuality: map['data_quality']?.toString() ?? 'needs_more_data',
      providerName: map['provider_name']?.toString() ?? 'provider_cache',
    );
  }

  final String symbolCode;
  final String timeframe;
  final String observedAt;
  final num open;
  final num high;
  final num low;
  final num close;
  final num? volume;
  final String dataQuality;
  final String providerName;

  bool get isProviderBacked =>
      dataQuality == 'delayed' ||
      dataQuality == 'realtime' ||
      dataQuality == 'live';
}

class ChartIndicatorSnapshot {
  const ChartIndicatorSnapshot({
    this.ema20,
    this.ema50,
    this.rsi14,
    this.trendState,
    this.technicalScore,
    this.ruleVersion,
  });

  factory ChartIndicatorSnapshot.fromMap(Map<String, dynamic> map) {
    return ChartIndicatorSnapshot(
      ema20: _numFromObject(map['ema_20']),
      ema50: _numFromObject(map['ema_50']),
      rsi14: _numFromObject(map['rsi_14']),
      trendState: map['trend_state']?.toString(),
      technicalScore: _numFromObject(map['technical_score']),
      ruleVersion: map['rule_version']?.toString(),
    );
  }

  final num? ema20;
  final num? ema50;
  final num? rsi14;
  final String? trendState;
  final num? technicalScore;
  final String? ruleVersion;

  bool get hasData =>
      ema20 != null ||
      ema50 != null ||
      rsi14 != null ||
      trendState != null ||
      technicalScore != null;
}

class StockChartDataResponse {
  const StockChartDataResponse({
    required this.symbolCode,
    required this.timeframe,
    required this.bars,
    required this.dataQuality,
    required this.providerName,
    required this.providerStatus,
    required this.disclaimer,
    required this.riskWarnings,
    this.indicators,
  });

  factory StockChartDataResponse.fromResult(
    Map<String, dynamic> data,
    Map<String, dynamic> meta,
  ) {
    final chart = asStringMap(data['chart']);
    final provider = asStringMap(data['provider']);
    final bars = asMapList(chart['bars']).map(OhlcvBar.fromMap).toList();
    return StockChartDataResponse(
      symbolCode: chart['symbol_code']?.toString() ?? '-',
      timeframe: chart['timeframe']?.toString() ?? '1d',
      bars: bars,
      dataQuality:
          chart['data_quality']?.toString() ??
          meta['data_quality']?.toString() ??
          'needs_more_data',
      providerName:
          provider['provider_name']?.toString() ??
          meta['provider_name']?.toString() ??
          'provider_cache',
      providerStatus:
          provider['provider_status']?.toString() ??
          meta['provider_status']?.toString() ??
          'OHLCV cache belum tersedia',
      disclaimer:
          data['disclaimer']?.toString() ??
          'Chart data bersifat edukatif untuk watchlist context.',
      riskWarnings: (data['risk_warning'] is List)
          ? (data['risk_warning'] as List).map(RiskWarning.fromObject).toList()
          : const [],
      indicators: data['indicators'] is Map
          ? ChartIndicatorSnapshot.fromMap(asStringMap(data['indicators']))
          : null,
    );
  }

  final String symbolCode;
  final String timeframe;
  final List<OhlcvBar> bars;
  final String dataQuality;
  final String providerName;
  final String providerStatus;
  final String disclaimer;
  final List<RiskWarning> riskWarnings;
  final ChartIndicatorSnapshot? indicators;

  int get barCount => bars.length;
  bool get hasBars => bars.isNotEmpty;
  bool get isDelayedProviderBacked => dataQuality == 'delayed' && hasBars;
}

num? _numFromObject(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}
